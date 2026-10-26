// SPDX-License-Identifier: GPL-3.0-or-later
#include "systeminfo.h"
#include "proc.h"
#include <QCoreApplication>
#include <QDir>
#include <QStandardPaths>
#include <QFile>
#include <QGuiApplication>
#include <QHostInfo>
#include <QRegularExpression>
#include <QScreen>
#include <QStorageInfo>
#include <QSysInfo>
#include <QTextStream>
#include <QThread>
#include <sys/sysinfo.h>

SystemInfo::SystemInfo(QObject *parent) : QObject(parent) { refresh(); }

QVariantMap SystemInfo::readKeyValueFile(const QString &path)
{
    QVariantMap m;
    QFile f(path);
    if (!f.open(QIODevice::ReadOnly | QIODevice::Text)) return m;
    while (!f.atEnd()) {
        const QString line = QString::fromUtf8(f.readLine()).trimmed();
        const int eq = line.indexOf(QLatin1Char('='));
        if (eq <= 0 || line.startsWith(QLatin1Char('#'))) continue;
        QString v = line.mid(eq + 1).trimmed();
        if (v.size() >= 2 && v.startsWith(QLatin1Char('"')) && v.endsWith(QLatin1Char('"'))) v = v.mid(1, v.size() - 2);
        m[line.left(eq)] = v;
    }
    return m;
}

QString SystemInfo::humanSize(qint64 b)
{
    const char *u[] = { "B", "KiB", "MiB", "GiB", "TiB" };
    double v = b; int i = 0;
    while (v >= 1024 && i < 4) { v /= 1024; ++i; }
    return QStringLiteral("%1 %2").arg(QString::number(v, 'f', i >= 2 ? 1 : 0), QLatin1String(u[i]));
}

void SystemInfo::refresh()
{
    QVariantMap m;
    const QVariantMap rel = readKeyValueFile(QStringLiteral("/etc/hagra-release"));
    m[QStringLiteral("hagraName")] = rel.value(QStringLiteral("HAGRA_DISPLAY_NAME"), tr("하그라"));
    m[QStringLiteral("hagraVersion")] = rel.value(QStringLiteral("HAGRA_VERSION"), QStringLiteral(HAGRA_VERSION) + tr(" (개발 호스트)"));
    m[QStringLiteral("hagraBase")] = rel.value(QStringLiteral("HAGRA_BASE"), QString());
    m[QStringLiteral("hagraBuildDate")] = rel.value(QStringLiteral("HAGRA_BUILD_DATE"), QString());
    const QVariantMap os = readKeyValueFile(QStringLiteral("/etc/os-release"));
    m[QStringLiteral("osPretty")] = os.value(QStringLiteral("PRETTY_NAME"), QSysInfo::prettyProductName());
    m[QStringLiteral("kernel")] = QSysInfo::kernelType() + QLatin1Char(' ') + QSysInfo::kernelVersion();
    m[QStringLiteral("arch")] = QSysInfo::currentCpuArchitecture();
    m[QStringLiteral("hostname")] = QHostInfo::localHostName();
    QString user = qEnvironmentVariable("USER", qEnvironmentVariable("LOGNAME"));
    if (user.isEmpty()) user = QDir::home().dirName();
    m[QStringLiteral("user")] = user;
    // CPU
    QString cpu; int cores = 0;
    QFile ci(QStringLiteral("/proc/cpuinfo"));
    if (ci.open(QIODevice::ReadOnly | QIODevice::Text)) {
        while (!ci.atEnd()) {
            const QString l = QString::fromUtf8(ci.readLine());
            if (l.startsWith(QLatin1String("processor"))) ++cores;
            if (cpu.isEmpty() && (l.startsWith(QLatin1String("model name")) || l.startsWith(QLatin1String("Model")) || l.startsWith(QLatin1String("Hardware"))))
                cpu = l.section(QLatin1Char(':'), 1).trimmed();
        }
    }
    m[QStringLiteral("cpu")] = cpu.isEmpty() ? tr("알 수 없음") : cpu;
    m[QStringLiteral("cores")] = cores > 0 ? cores : QThread::idealThreadCount();
    struct sysinfo si{};
    if (sysinfo(&si) == 0) {
        m[QStringLiteral("memTotal")] = humanSize(qint64(si.totalram) * si.mem_unit);
        m[QStringLiteral("memFree")] = humanSize((qint64(si.freeram) + qint64(si.bufferram)) * si.mem_unit);
        m[QStringLiteral("uptimeSec")] = qint64(si.uptime);
    }
    QStorageInfo root(QStringLiteral("/"));
    m[QStringLiteral("diskTotal")] = humanSize(root.bytesTotal());
    m[QStringLiteral("diskFree")] = humanSize(root.bytesAvailable());
    m[QStringLiteral("diskFs")] = QString::fromUtf8(root.fileSystemType());
    m[QStringLiteral("live")] = root.fileSystemType() == "overlay" || QFile::exists(QStringLiteral("/run/live/medium"));
    m[QStringLiteral("qtVersion")] = QString::fromLatin1(qVersion());
    const ProcResult lw = Proc::run(QStringLiteral("labwc"), { QStringLiteral("--version") }, 2000);
    m[QStringLiteral("compositor")] = lw.ok() ? lw.out.trimmed() : tr("labwc (버전 확인 불가)");
    m[QStringLiteral("session")] = qEnvironmentVariable("XDG_SESSION_TYPE", QStringLiteral("?")) + QStringLiteral(" / ") + qEnvironmentVariable("XDG_CURRENT_DESKTOP", QStringLiteral("?"));
    m[QStringLiteral("renderer")] = qEnvironmentVariable("QT_QUICK_BACKEND").isEmpty() ? QStringLiteral("GPU (OpenGL)") : tr("소프트웨어 (") + qEnvironmentVariable("QT_QUICK_BACKEND") + QLatin1Char(')');
    QVariantList screens;
    for (QScreen *s : QGuiApplication::screens())
        screens << QStringLiteral("%1: %2×%3 @ %4x, %5 dpi").arg(s->name()).arg(s->size().width()).arg(s->size().height()).arg(s->devicePixelRatio()).arg(qRound(s->logicalDotsPerInch()));
    m[QStringLiteral("screens")] = screens;
    m_info = m;
    emit refreshed();
}

QString SystemInfo::sessionLogPath() const
{
    QString base = qEnvironmentVariable("XDG_STATE_HOME");
    if (base.isEmpty()) base = QDir::homePath() + QStringLiteral("/.local/state");
    return base + QStringLiteral("/hagra/session.log");
}

QString SystemInfo::shellLogPath() const
{
    return qEnvironmentVariable("XDG_RUNTIME_DIR", QStringLiteral("/tmp")) + QStringLiteral("/hagra-shell.log");
}

QString SystemInfo::readTail(const QString &path, int lines) const
{
    QFile f(path);
    if (!f.open(QIODevice::ReadOnly | QIODevice::Text)) return tr("(파일 없음: %1)").arg(path);
    QStringList all = QString::fromUtf8(f.readAll()).split(QLatin1Char('\n'));
    if (all.size() > lines) all = all.mid(all.size() - lines);
    return all.join(QLatin1Char('\n'));
}

QStringList SystemInfo::cursorThemes() const
{
    QStringList names;
    QStringList dirs = QStandardPaths::standardLocations(QStandardPaths::GenericDataLocation);
    dirs << QDir::homePath() + QStringLiteral("/.icons");
    for (const QString &d : dirs) {
        QDir icons(d + QStringLiteral("/icons"));
        if (d.endsWith(QLatin1String("/.icons"))) icons = QDir(d);
        for (const QString &n : icons.entryList(QDir::Dirs | QDir::NoDotAndDotDot, QDir::Name))
            if (QFileInfo::exists(icons.absoluteFilePath(n) + QStringLiteral("/cursors")) && !names.contains(n) && n != QLatin1String("default"))
                names << n;
    }
    return names;
}
