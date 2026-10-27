// SPDX-License-Identifier: GPL-3.0-or-later
#include "browserhelper.h"

#include <QCoreApplication>
#include <QDBusConnection>
#include <QDBusMessage>
#include <QDir>
#include <QFileInfo>
#include <QLocale>
#include <QRegularExpression>
#include <QSettings>
#include <QStandardPaths>
#include <QVariantMap>

Q_LOGGING_CATEGORY(lcBrowser, "hagra.browser")

namespace {
struct Engine { const char *id; const char *name; const char *url; };
// 이름은 QML 쪽에서 qsTranslate("BrowserHelper", ...) 로 번역한다 (QT_TRANSLATE_NOOP 로 lupdate 에 등록)
const Engine kEngines[] = {
    { "google",     QT_TRANSLATE_NOOP("BrowserHelper", "구글"),     "https://www.google.com/search?q=%1" },
    { "naver",      QT_TRANSLATE_NOOP("BrowserHelper", "네이버"),   "https://search.naver.com/search.naver?query=%1" },
    { "daum",       QT_TRANSLATE_NOOP("BrowserHelper", "다음"),     "https://search.daum.net/search?q=%1" },
    { "duckduckgo", QT_TRANSLATE_NOOP("BrowserHelper", "덕덕고"),   "https://duckduckgo.com/?q=%1" },
    { "bing",       QT_TRANSLATE_NOOP("BrowserHelper", "빙"),       "https://www.bing.com/search?q=%1" },
};
const char kDefaultEngine[] = "google";

const Engine *findEngine(const QString &id)
{
    for (const Engine &e : kEngines)
        if (id == QLatin1String(e.id)) return &e;
    return nullptr;
}

// 주소로 열어도 되는 스킴. 그 밖의 "단어:" 는 주소가 아니라 검색어로 본다 (예: "localhost:8080" 은 따로 처리).
const QStringList kSchemes = { QStringLiteral("http"), QStringLiteral("https"), QStringLiteral("file"), QStringLiteral("ftp"),
                               QStringLiteral("about"), QStringLiteral("data"), QStringLiteral("view-source"), QStringLiteral("blob"),
                               QStringLiteral("chrome"), QStringLiteral("mailto") };
}

BrowserHelper::BrowserHelper(QObject *parent) : QObject(parent)
{
    load();
}

QString BrowserHelper::configPath()
{
    return QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation) + QStringLiteral("/hagra/browser.conf");
}

QStringList BrowserHelper::defaultShortcuts()
{
    static const char *const titles[][2] = {
        { QT_TRANSLATE_NOOP("BrowserHelper", "네이버"), "https://www.naver.com/" },
        { QT_TRANSLATE_NOOP("BrowserHelper", "다음"), "https://www.daum.net/" },
        { QT_TRANSLATE_NOOP("BrowserHelper", "구글"), "https://www.google.com/" },
        { QT_TRANSLATE_NOOP("BrowserHelper", "유튜브"), "https://www.youtube.com/" },
        { QT_TRANSLATE_NOOP("BrowserHelper", "위키백과"), "https://ko.wikipedia.org/" },
    };
    QStringList out;
    for (const auto &t : titles)
        out << QCoreApplication::translate("BrowserHelper", t[0]) + QLatin1Char('\t') + QLatin1String(t[1]);
    return out;
}

void BrowserHelper::load()
{
    QSettings s(configPath(), QSettings::IniFormat);
    m_search = s.value(QStringLiteral("browser/search"), QLatin1String(kDefaultEngine)).toString();
    if (!findEngine(m_search)) m_search = QLatin1String(kDefaultEngine);
    // 키가 아예 없으면 기본 목록, 사용자가 모두 지웠으면(빈 목록) 그대로 빈 목록
    const QStringList raw = s.contains(QStringLiteral("browser/shortcuts"))
        ? s.value(QStringLiteral("browser/shortcuts")).toStringList() : defaultShortcuts();
    m_shortcuts.clear();
    for (const QString &line : raw) {
        const int tab = line.indexOf(QLatin1Char('\t'));
        const QString url = (tab >= 0 ? line.mid(tab + 1) : line).trimmed();
        if (url.isEmpty()) continue;
        m_shortcuts.append({ tab >= 0 ? line.left(tab).trimmed() : QString(), url });
    }
}

void BrowserHelper::save() const
{
    QDir().mkpath(QFileInfo(configPath()).absolutePath());
    QSettings s(configPath(), QSettings::IniFormat);
    s.setValue(QStringLiteral("browser/search"), m_search);
    QStringList raw;
    for (const Shortcut &sc : m_shortcuts) raw << sc.title + QLatin1Char('\t') + sc.url;
    s.setValue(QStringLiteral("browser/shortcuts"), raw);
}

QString BrowserHelper::searchUrl(const QString &query) const
{
    const Engine *e = findEngine(m_search);
    if (!e) e = findEngine(QLatin1String(kDefaultEngine));
    return QString::fromLatin1(e->url).arg(QString::fromLatin1(QUrl::toPercentEncoding(query.trimmed())));
}

QString BrowserHelper::fixup(const QString &input) const
{
    const QString s = input.trimmed();
    if (s.isEmpty()) return {};

    // 로컬 파일 경로
    if (s.startsWith(QLatin1Char('/')) || s.startsWith(QStringLiteral("~/"))) {
        const QString path = s.startsWith(QLatin1Char('~')) ? QDir::homePath() + s.mid(1) : s;
        if (QFileInfo::exists(path)) return QUrl::fromLocalFile(QDir::cleanPath(path)).toString();
        return searchUrl(s);
    }

    // 알려진 스킴 (http: 와 https: 는 // 가 있어야 주소로 본다: "http:문서" 같은 검색어 보호)
    static const QRegularExpression schemeRe(QStringLiteral("^([A-Za-z][A-Za-z0-9+.-]*):(.*)$"));
    const auto sm = schemeRe.match(s);
    if (sm.hasMatch() && !s.contains(QRegularExpression(QStringLiteral("\\s")))) {
        const QString scheme = sm.captured(1).toLower();
        if (kSchemes.contains(scheme) && (!(scheme == QLatin1String("http") || scheme == QLatin1String("https")) || sm.captured(2).startsWith(QStringLiteral("//"))))
            return s;
    }
    if (s.contains(QRegularExpression(QStringLiteral("\\s"))))
        return searchUrl(s);

    // 호스트[:포트][/경로] 형태인가
    static const QRegularExpression hostRe(QStringLiteral("^(\\[[0-9A-Fa-f:.]+\\]|[^/?#:]+)(:\\d{1,5})?([/?#].*)?$"));
    const auto hm = hostRe.match(s);
    if (!hm.hasMatch()) return searchUrl(s);
    const QString host = hm.captured(1).toLower();
    static const QRegularExpression ipv4Re(QStringLiteral("^\\d{1,3}(\\.\\d{1,3}){3}$"));
    if (host == QLatin1String("localhost") || host.endsWith(QStringLiteral(".localhost")) || ipv4Re.match(host).hasMatch() || host.startsWith(QLatin1Char('[')))
        return QStringLiteral("http://") + s;
    const QStringList labels = host.split(QLatin1Char('.'));
    if (labels.size() < 2) return searchUrl(s);
    static const QRegularExpression labelRe(QStringLiteral("^[\\w-]+$"), QRegularExpression::UseUnicodePropertiesOption);
    for (const QString &l : labels)
        if (l.isEmpty() || !labelRe.match(l).hasMatch() || l.startsWith(QLatin1Char('-')) || l.endsWith(QLatin1Char('-')))
            return searchUrl(s);
    // 최상위 도메인: 글자 2자 이상 (숫자만이면 "3.14" 같은 검색어), 또는 퓨니코드 xn--
    const QString tld = labels.last();
    static const QRegularExpression tldRe(QStringLiteral("^(\\p{L}{2,}|xn--[a-z0-9-]+)$"), QRegularExpression::UseUnicodePropertiesOption);
    if (!tldRe.match(tld).hasMatch()) return searchUrl(s);
    return QStringLiteral("https://") + s;
}

QString BrowserHelper::displayUrl(const QUrl &url) const
{
    if (url.isEmpty()) return {};
    return url.toDisplayString();
}

QString BrowserHelper::shortName(const QUrl &url) const
{
    QString h = url.host();
    if (h.startsWith(QStringLiteral("www."))) h = h.mid(4);
    if (!h.isEmpty()) return h;
    if (url.isLocalFile()) return QFileInfo(url.toLocalFile()).fileName();
    return url.toDisplayString();
}

void BrowserHelper::setSearchEngine(const QString &id)
{
    if (id == m_search || !findEngine(id)) return;
    m_search = id;
    save();
    emit searchEngineChanged();
}

QVariantList BrowserHelper::searchEngines() const
{
    QVariantList out;
    for (const Engine &e : kEngines)
        out << QVariantMap{ { QStringLiteral("id"), QLatin1String(e.id) },
                            { QStringLiteral("name"), QCoreApplication::translate("BrowserHelper", e.name) } };
    return out;
}

QVariantList BrowserHelper::shortcuts() const
{
    QVariantList out;
    for (const Shortcut &sc : m_shortcuts)
        out << QVariantMap{ { QStringLiteral("title"), sc.title.isEmpty() ? shortName(QUrl(sc.url)) : sc.title },
                            { QStringLiteral("url"), sc.url } };
    return out;
}

static QString normalized(const QString &url)
{
    QString u = url.trimmed();
    if (u.endsWith(QLatin1Char('/'))) u.chop(1);
    return u;
}

bool BrowserHelper::hasShortcut(const QString &url) const
{
    const QString n = normalized(url);
    if (n.isEmpty()) return false;
    for (const Shortcut &sc : m_shortcuts)
        if (normalized(sc.url) == n) return true;
    return false;
}

void BrowserHelper::addShortcut(const QString &title, const QString &url)
{
    if (url.trimmed().isEmpty() || hasShortcut(url)) return;
    m_shortcuts.append({ title.trimmed(), url.trimmed() });
    save();
    emit shortcutsChanged();
}

void BrowserHelper::removeShortcut(const QString &url)
{
    const QString n = normalized(url);
    const auto before = m_shortcuts.size();
    m_shortcuts.removeIf([&n](const Shortcut &sc) { return normalized(sc.url) == n; });
    if (m_shortcuts.size() == before) return;
    save();
    emit shortcutsChanged();
}

void BrowserHelper::toggleShortcut(const QString &title, const QString &url)
{
    if (hasShortcut(url)) removeShortcut(url); else addShortcut(title, url);
}

QString BrowserHelper::storagePath() const
{
    return QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation) + QStringLiteral("/hagra/browser");
}

QString BrowserHelper::cachePath() const
{
    return QStandardPaths::writableLocation(QStandardPaths::GenericCacheLocation) + QStringLiteral("/hagra/browser");
}

bool BrowserHelper::storageWritable() const
{
    static const bool ok = [this] {
        for (const QString &d : { storagePath(), cachePath() }) {
            if (!QDir().mkpath(d) || !QFileInfo(d).isWritable()) {
                qCWarning(lcBrowser) << "storage not writable:" << d << "— using an in-memory profile (cookies and history are not kept)";
                return false;
            }
        }
        return true;
    }();
    return ok;
}

QString BrowserHelper::downloadDir() const
{
    QString d = QStandardPaths::writableLocation(QStandardPaths::DownloadLocation);
    if (d.isEmpty() || QDir(d) == QDir::home()) d = QDir::homePath() + QStringLiteral("/Downloads");
    return d;
}

QString BrowserHelper::acceptLanguage() const
{
    QStringList langs;
    for (const QString &l : QLocale().uiLanguages()) {
        if (l == QLatin1String("C")) continue;
        QString tag = l;
        tag.replace(QLatin1Char('_'), QLatin1Char('-'));
        if (!langs.contains(tag)) langs << tag;
        const QString base = tag.section(QLatin1Char('-'), 0, 0);
        if (!langs.contains(base)) langs << base;
    }
    for (const QString &fallback : { QStringLiteral("en-US"), QStringLiteral("en") })
        if (!langs.contains(fallback)) langs << fallback;
    QStringList out;
    for (int i = 0; i < langs.size(); ++i)
        out << (i == 0 ? langs[i] : QStringLiteral("%1;q=%2").arg(langs[i]).arg(qMax(0.1, 1.0 - 0.1 * i), 0, 'f', 1));
    return out.join(QLatin1Char(','));
}

bool BrowserHelper::notify(const QString &title, const QString &body) const
{
    QDBusMessage m = QDBusMessage::createMethodCall(QStringLiteral("org.freedesktop.Notifications"), QStringLiteral("/org/freedesktop/Notifications"),
                                                    QStringLiteral("org.freedesktop.Notifications"), QStringLiteral("Notify"));
    m << QCoreApplication::translate("BrowserHelper", "하그라 브라우저") << 0u << QStringLiteral("org.hagra.browser") << title << body
      << QStringList() << QVariantMap() << -1;
    return QDBusConnection::sessionBus().send(m);
}

void BrowserHelper::log(const QString &message) const
{
    qCInfo(lcBrowser).noquote() << message;
}
