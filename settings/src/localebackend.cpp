// SPDX-License-Identifier: GPL-3.0-or-later
#include "localebackend.h"
#include "proc.h"
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QLocale>
#include <QStandardPaths>
#include <QTimeZone>

LocaleBackend::LocaleBackend(QObject *parent) : QObject(parent) { refresh(); }

QString LocaleBackend::configPath()
{
    return QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation) + QStringLiteral("/hagra/locale.conf");
}

QVariantList LocaleBackend::parseLocaleList(const QString &out)
{
    QVariantList l;
    QStringList seen;
    for (QString line : out.split(QLatin1Char('\n'), Qt::SkipEmptyParts)) {
        line = line.trimmed();
        if (line == QLatin1String("C") || line == QLatin1String("POSIX")) continue;
        QString norm = line;
        norm.replace(QLatin1String(".utf8"), QLatin1String(".UTF-8"));
        if (!norm.contains(QLatin1String("UTF-8"))) continue;
        if (seen.contains(norm)) continue;
        seen << norm;
        const QLocale loc(norm.section(QLatin1Char('.'), 0, 0));
        QString name = norm == QLatin1String("C.UTF-8") ? QStringLiteral("기본 (C.UTF-8)") : QLocale::languageToString(loc.language()) + QStringLiteral(" (") + QLocale::territoryToString(loc.territory()) + QLatin1Char(')');
        l << QVariantMap{ { QStringLiteral("code"), norm }, { QStringLiteral("name"), name } };
    }
    std::stable_sort(l.begin(), l.end(), [](const QVariant &a, const QVariant &b) {
        auto rank = [](const QString &c) { return c.startsWith(QLatin1String("ko_")) ? 0 : c.startsWith(QLatin1String("en_")) ? 1 : 2; };
        const QString ca = a.toMap().value(QStringLiteral("code")).toString(), cb = b.toMap().value(QStringLiteral("code")).toString();
        return rank(ca) != rank(cb) ? rank(ca) < rank(cb) : ca < cb;
    });
    return l;
}

void LocaleBackend::refresh()
{
    const ProcResult r = Proc::run(QStringLiteral("locale"), { QStringLiteral("-a") });
    m_locales = parseLocaleList(r.ok() ? r.out : QStringLiteral("C.UTF-8\n"));
    m_savedLang.clear(); m_savedTime.clear();
    QFile f(configPath());
    if (f.open(QIODevice::ReadOnly | QIODevice::Text)) {
        for (const QString &line : QString::fromUtf8(f.readAll()).split(QLatin1Char('\n'))) {
            if (line.startsWith(QLatin1String("LANG="))) m_savedLang = line.mid(5).trimmed();
            if (line.startsWith(QLatin1String("LC_TIME="))) m_savedTime = line.mid(8).trimmed();
        }
    }
    m_tz = QString::fromUtf8(QTimeZone::systemTimeZoneId());
    // 입력기
    QVariantMap ime;
    const bool fcitx = Proc::has(QStringLiteral("fcitx5"));
    ime[QStringLiteral("installed")] = fcitx;
    ime[QStringLiteral("name")] = fcitx ? QStringLiteral("fcitx5") : QString();
    bool hangul = false;
    for (const QString &d : QStandardPaths::standardLocations(QStandardPaths::GenericDataLocation))
        if (QFileInfo::exists(d + QStringLiteral("/fcitx5/addon/hangul.conf"))) hangul = true;
    for (const QString &d : { QStringLiteral("/usr/lib/x86_64-linux-gnu/fcitx5/libhangul.so"), QStringLiteral("/usr/lib/aarch64-linux-gnu/fcitx5/libhangul.so") })
        if (QFileInfo::exists(d)) hangul = true;
    ime[QStringLiteral("hangul")] = hangul;
    bool running = false;
    if (fcitx) { const ProcResult p = Proc::run(QStringLiteral("pgrep"), { QStringLiteral("-x"), QStringLiteral("fcitx5") }, 2000); running = p.ok(); }
    ime[QStringLiteral("running")] = running;
    ime[QStringLiteral("envOk")] = qEnvironmentVariable("QT_IM_MODULE") == QLatin1String("fcitx") || qEnvironmentVariable("XMODIFIERS").contains(QLatin1String("fcitx"));
    m_ime = ime;
    emit refreshed();
}

static void writeConf(const QString &path, const QString &lang, const QString &time)
{
    QDir().mkpath(QFileInfo(path).absolutePath());
    QFile f(path);
    if (!f.open(QIODevice::WriteOnly | QIODevice::Truncate)) return;
    QString s = QStringLiteral("# hagra-settings: 언어·지역 (다음 로그인부터 적용; hagra-session 이 읽는다)\n");
    if (!lang.isEmpty()) s += QStringLiteral("LANG=") + lang + QLatin1Char('\n');
    if (!time.isEmpty()) s += QStringLiteral("LC_TIME=") + time + QLatin1Char('\n');
    f.write(s.toUtf8());
}

void LocaleBackend::setLang(const QString &lang)
{
    writeConf(configPath(), lang, m_savedTime);
    refresh();
}

void LocaleBackend::setTimeFormatLocale(const QString &lc)
{
    writeConf(configPath(), m_savedLang, lc);
    refresh();
}

bool LocaleBackend::startIme()
{
    if (!Proc::has(QStringLiteral("fcitx5"))) return false;
    const bool ok = Proc::detach(QStringLiteral("fcitx5"), { QStringLiteral("-d"), QStringLiteral("--replace") });
    refresh();
    return ok;
}
