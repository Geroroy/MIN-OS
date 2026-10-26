// SPDX-License-Identifier: GPL-3.0-or-later
#include "networkbackend.h"
#include "proc.h"
#include <QFile>
#include <QNetworkInterface>

NetworkBackend::NetworkBackend(QObject *parent) : QObject(parent) { refresh(); }

QString NetworkBackend::parseDefaultRoute(const QString &text)
{
    for (const QString &line : text.split(QLatin1Char('\n'), Qt::SkipEmptyParts)) {
        const QStringList f = line.simplified().split(QLatin1Char(' '));
        if (f.size() >= 4 && f[1] == QLatin1String("00000000") && (f[3].toInt(nullptr, 16) & 2)) return f[0];
    }
    return {};
}

QVariantList NetworkBackend::parseNmcliWifi(const QString &out)
{
    QVariantList l;
    for (const QString &line : out.split(QLatin1Char('\n'), Qt::SkipEmptyParts)) {
        // nmcli -t 는 ':' 구분, SSID 안의 ':' 는 '\:' 로 이스케이프
        QStringList f; QString cur; bool esc = false;
        for (const QChar c : line) { if (esc) { cur += c; esc = false; } else if (c == QLatin1Char('\\')) esc = true; else if (c == QLatin1Char(':')) { f << cur; cur.clear(); } else cur += c; }
        f << cur;
        if (f.size() < 3 || f[0].isEmpty()) continue;
        l << QVariantMap{ { QStringLiteral("ssid"), f[0] }, { QStringLiteral("signal"), f[1].toInt() }, { QStringLiteral("security"), f[2] },
                          { QStringLiteral("inUse"), f.value(3).trimmed() == QLatin1String("*") } };
    }
    return l;
}

void NetworkBackend::refresh()
{
    m_ifaces.clear();
    QFile route(QStringLiteral("/proc/net/route"));
    m_route = route.open(QIODevice::ReadOnly) ? parseDefaultRoute(QString::fromUtf8(route.readAll())) : QString();
    for (const QNetworkInterface &i : QNetworkInterface::allInterfaces()) {
        if (i.type() == QNetworkInterface::Loopback) continue;
        QStringList addrs;
        for (const QNetworkAddressEntry &e : i.addressEntries())
            if (!e.ip().isLoopback() && !e.ip().isLinkLocal()) addrs << e.ip().toString();
        QString kind;
        switch (i.type()) {
        case QNetworkInterface::Wifi: kind = tr("무선"); break;
        case QNetworkInterface::Ethernet: kind = tr("유선"); break;
        case QNetworkInterface::Virtual: kind = tr("가상"); break;
        default: kind = tr("기타");
        }
        QFile op(QStringLiteral("/sys/class/net/%1/operstate").arg(i.name()));
        const QString state = op.open(QIODevice::ReadOnly) ? QString::fromUtf8(op.readAll()).trimmed() : QString();
        m_ifaces << QVariantMap{ { QStringLiteral("name"), i.name() }, { QStringLiteral("kind"), kind }, { QStringLiteral("up"), bool(i.flags() & QNetworkInterface::IsUp) },
                                 { QStringLiteral("running"), bool(i.flags() & QNetworkInterface::IsRunning) }, { QStringLiteral("state"), state },
                                 { QStringLiteral("addresses"), addrs.join(QStringLiteral(", ")) }, { QStringLiteral("mac"), i.hardwareAddress() },
                                 { QStringLiteral("isDefault"), i.name() == m_route } };
    }
    m_nm = Proc::has(QStringLiteral("nmcli"));
    if (m_nm) {
        const ProcResult r = Proc::run(QStringLiteral("nmcli"), { QStringLiteral("-t"), QStringLiteral("general"), QStringLiteral("status") }, 3000);
        if (!r.ok()) { m_nm = false; m_reason = tr("nmcli 가 NetworkManager 에 연결하지 못했습니다 (서비스 미실행?). ") + r.err.trimmed(); }
        else m_reason.clear();
    } else {
        m_reason = tr("NetworkManager 가 설치되어 있지 않아 Wi-Fi 검색·연결 설정은 제공하지 않습니다. 아래는 커널이 보고하는 인터페이스 상태입니다 (읽기 전용). 설치: network-manager.");
    }
    emit refreshed();
}

void NetworkBackend::scanWifi()
{
    m_wifi.clear();
    if (m_nm) {
        const ProcResult r = Proc::run(QStringLiteral("nmcli"), { QStringLiteral("-t"), QStringLiteral("-f"), QStringLiteral("SSID,SIGNAL,SECURITY,IN-USE"), QStringLiteral("dev"), QStringLiteral("wifi"), QStringLiteral("list"), QStringLiteral("--rescan"), QStringLiteral("yes") }, 15000);
        if (r.ok()) m_wifi = parseNmcliWifi(r.out);
    }
    emit refreshed();
}

QVariantMap NetworkBackend::connectWifi(const QString &ssid, const QString &password)
{
    QVariantMap res{ { QStringLiteral("ok"), false } };
    if (!m_nm) { res[QStringLiteral("message")] = m_reason; return res; }
    QStringList a{ QStringLiteral("dev"), QStringLiteral("wifi"), QStringLiteral("connect"), ssid };
    if (!password.isEmpty()) a << QStringLiteral("password") << password;
    const ProcResult r = Proc::run(QStringLiteral("nmcli"), a, 30000);
    res[QStringLiteral("ok")] = r.ok();
    res[QStringLiteral("message")] = (r.ok() ? r.out : r.err).trimmed();
    refresh();
    return res;
}

QVariantMap NetworkBackend::disconnect(const QString &iface)
{
    QVariantMap res{ { QStringLiteral("ok"), false } };
    if (!m_nm) { res[QStringLiteral("message")] = m_reason; return res; }
    const ProcResult r = Proc::run(QStringLiteral("nmcli"), { QStringLiteral("dev"), QStringLiteral("disconnect"), iface }, 10000);
    res[QStringLiteral("ok")] = r.ok(); res[QStringLiteral("message")] = (r.ok() ? r.out : r.err).trimmed();
    refresh();
    return res;
}
