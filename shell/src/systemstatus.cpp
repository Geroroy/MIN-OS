// SPDX-License-Identifier: GPL-3.0-or-later
#include "systemstatus.h"
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QNetworkInterface>
#include <QProcess>
#include <QRegularExpression>
#include <QStandardPaths>
#include <QTimer>

static QString readFile(const QString &p)
{
    QFile f(p);
    return f.open(QIODevice::ReadOnly) ? QString::fromUtf8(f.readAll()) : QString();
}

SystemStatus::SystemStatus(QObject *parent) : QObject(parent)
{
    m_audioTool = !QStandardPaths::findExecutable(QStringLiteral("wpctl")).isEmpty() ? QStringLiteral("wpctl")
                : !QStandardPaths::findExecutable(QStringLiteral("pactl")).isEmpty() ? QStringLiteral("pactl") : QString();
    m_timer = new QTimer(this);
    m_timer->setInterval(5000);
    connect(m_timer, &QTimer::timeout, this, [this] { ++m_tick; pollNetwork(); pollBattery(); if (m_tick % 2 == 0) pollAudio(); emit changed(); });
    refresh();
    m_timer->start();
}

QString SystemStatus::defaultRouteIface(const QString &text)
{
    for (const QString &line : text.split(QLatin1Char('\n'), Qt::SkipEmptyParts)) {
        const QStringList f = line.simplified().split(QLatin1Char(' '));
        if (f.size() >= 4 && f[1] == QLatin1String("00000000") && (f[3].toInt(nullptr, 16) & 2)) return f[0];
    }
    return {};
}

int SystemStatus::wifiSignalPercent(const QString &text, const QString &iface)
{
    // /proc/net/wireless: "wlan0: 0000   54.  -56.  -256 ..." — 두 번째 열이 링크 품질(0..70)
    for (const QString &line : text.split(QLatin1Char('\n'))) {
        const QString t = line.trimmed();
        if (!t.startsWith(iface + QLatin1Char(':'))) continue;
        const QStringList f = t.mid(iface.size() + 1).simplified().split(QLatin1Char(' '));
        if (f.size() < 2) return -1;
        QString q = f[1]; q.remove(QLatin1Char('.'));
        bool ok = false; const double v = q.toDouble(&ok);
        return ok ? qBound(0, qRound(v / 70.0 * 100), 100) : -1;
    }
    return -1;
}

void SystemStatus::pollNetwork()
{
    m_iface = defaultRouteIface(readFile(QStringLiteral("/proc/net/route")));
    m_online = !m_iface.isEmpty();
    m_address.clear(); m_signal = -1;
    if (!m_online) { m_kind = QStringLiteral("none"); return; }
    m_kind = QFileInfo::exists(QStringLiteral("/sys/class/net/%1/wireless").arg(m_iface)) ? QStringLiteral("wifi") : QStringLiteral("ethernet");
    const QNetworkInterface ni = QNetworkInterface::interfaceFromName(m_iface);
    for (const QNetworkAddressEntry &e : ni.addressEntries())
        if (e.ip().protocol() == QAbstractSocket::IPv4Protocol) { m_address = e.ip().toString(); break; }
    if (m_kind == QLatin1String("wifi")) m_signal = wifiSignalPercent(readFile(QStringLiteral("/proc/net/wireless")), m_iface);
}

void SystemStatus::pollBattery()
{
    QDir d(QStringLiteral("/sys/class/power_supply"));
    m_batteryPresent = false; m_charging = false; m_batteryPercent = -1;
    bool acOnline = false;
    for (const QString &n : d.entryList(QDir::Dirs | QDir::NoDotAndDotDot)) {
        const QString base = d.absoluteFilePath(n);
        const QString type = readFile(base + QStringLiteral("/type")).trimmed();
        if (type == QLatin1String("Battery") && !m_batteryPresent) {
            m_batteryPresent = true;
            m_batteryPercent = readFile(base + QStringLiteral("/capacity")).trimmed().toInt();
            const QString st = readFile(base + QStringLiteral("/status")).trimmed();
            m_charging = st == QLatin1String("Charging") || st == QLatin1String("Full");
        } else if ((type == QLatin1String("Mains") || type == QLatin1String("USB")) && readFile(base + QStringLiteral("/online")).trimmed() == QLatin1String("1")) {
            acOnline = true;
        }
    }
    if (m_batteryPresent && acOnline) m_charging = true;
}

void SystemStatus::pollAudio()
{
    m_audio = false;
    if (m_audioTool.isEmpty()) return;
    QProcess p;
    if (m_audioTool == QLatin1String("wpctl")) p.start(m_audioTool, { QStringLiteral("get-volume"), QStringLiteral("@DEFAULT_AUDIO_SINK@") });
    else p.start(m_audioTool, { QStringLiteral("get-sink-volume"), QStringLiteral("@DEFAULT_SINK@") });
    if (!p.waitForFinished(1500) || p.exitCode() != 0) return;
    const QString out = QString::fromUtf8(p.readAllStandardOutput());
    if (m_audioTool == QLatin1String("wpctl")) {
        static const QRegularExpression re(QStringLiteral("Volume:\\s*([0-9.]+)(\\s*\\[MUTED\\])?"));
        const auto m = re.match(out);
        if (!m.hasMatch()) return;
        m_volume = qRound(m.captured(1).toDouble() * 100); m_muted = !m.captured(2).isEmpty();
    } else {
        static const QRegularExpression pct(QStringLiteral("(\\d+)%"));
        const auto m = pct.match(out);
        if (!m.hasMatch()) return;
        m_volume = m.captured(1).toInt();
        QProcess mu; mu.start(m_audioTool, { QStringLiteral("get-sink-mute"), QStringLiteral("@DEFAULT_SINK@") }); mu.waitForFinished(1500);
        m_muted = QString::fromUtf8(mu.readAllStandardOutput()).contains(QLatin1String("yes"));
    }
    m_audio = true;
}

void SystemStatus::refresh()
{
    pollNetwork(); pollBattery(); pollAudio();
    emit changed();
}

bool SystemStatus::setVolume(int percent)
{
    if (!m_audio) return false;
    percent = qBound(0, percent, 150);
    QProcess p;
    if (m_audioTool == QLatin1String("wpctl")) p.start(m_audioTool, { QStringLiteral("set-volume"), QStringLiteral("-l"), QStringLiteral("1.5"), QStringLiteral("@DEFAULT_AUDIO_SINK@"), QStringLiteral("%1%").arg(percent) });
    else p.start(m_audioTool, { QStringLiteral("set-sink-volume"), QStringLiteral("@DEFAULT_SINK@"), QStringLiteral("%1%").arg(percent) });
    const bool ok = p.waitForFinished(1500) && p.exitCode() == 0;
    pollAudio(); emit changed();
    return ok;
}

bool SystemStatus::setMuted(bool muted)
{
    if (!m_audio) return false;
    QProcess p;
    if (m_audioTool == QLatin1String("wpctl")) p.start(m_audioTool, { QStringLiteral("set-mute"), QStringLiteral("@DEFAULT_AUDIO_SINK@"), muted ? QStringLiteral("1") : QStringLiteral("0") });
    else p.start(m_audioTool, { QStringLiteral("set-sink-mute"), QStringLiteral("@DEFAULT_SINK@"), muted ? QStringLiteral("1") : QStringLiteral("0") });
    const bool ok = p.waitForFinished(1500) && p.exitCode() == 0;
    pollAudio(); emit changed();
    return ok;
}
