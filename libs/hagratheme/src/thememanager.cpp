// 하그라 테마 관리자 구현
// SPDX-License-Identifier: GPL-3.0-or-later
#include "hagratheme/thememanager.h"

#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QFileSystemWatcher>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QLoggingCategory>
#include <QProcess>
#include <QQmlEngine>
#include <QQmlComponent>
#include <QJSValue>
#include <QSettings>
#include <QStandardPaths>
#include <QUrl>
#include <QMetaObject>
#include <QTimer>
#include <QElapsedTimer>

Q_LOGGING_CATEGORY(lcTheme, "minos.theme")

namespace HagraTheme {

static const char *kBuiltinDefault = "hagra-dancheong-light";

ThemeManager::ThemeManager(QObject *parent) : QObject(parent)
{
    rescan();
    loadSettings();
    const QString env = envOverride();
    if (!env.isEmpty()) {
        if (theme(env).valid()) {
            m_currentId = env;
            m_envOverride = true;
            qCInfo(lcTheme) << "theme overridden by HAGRA_THEME:" << env;
        } else {
            qCWarning(lcTheme) << "HAGRA_THEME names an unknown theme:" << env << "— ignored";
        }
    }
    if (!theme(m_currentId).valid()) {
        qCWarning(lcTheme) << "saved theme" << m_currentId << "not available; falling back to" << defaultId();
        m_currentId = defaultId();
    }
    watchSettings();
}

ThemeManager::~ThemeManager() = default;

QString ThemeManager::builtinDefaultId() { return QString::fromLatin1(kBuiltinDefault); }

QString ThemeManager::envOverride() const { return qEnvironmentVariable("HAGRA_THEME").trimmed(); }

QStringList ThemeManager::searchDirs()
{
    QStringList dirs;
    for (const QString &p : qEnvironmentVariable("HAGRA_THEME_PATH").split(QLatin1Char(':'), Qt::SkipEmptyParts))
        dirs << p;
    dirs << QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation) + QStringLiteral("/hagra/themes");
#ifdef MINOS_THEME_INSTALL_DIR
    dirs << QStringLiteral(MINOS_THEME_INSTALL_DIR);
#endif
    for (const QString &d : QStandardPaths::standardLocations(QStandardPaths::GenericDataLocation))
        dirs << d + QStringLiteral("/hagra/themes");
    dirs.removeDuplicates();
    return dirs;
}

QString ThemeManager::configFilePath()
{
    return QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation) + QStringLiteral("/minos/theme.conf");
}

QString ThemeManager::stateDir()
{
    QString base = qEnvironmentVariable("XDG_STATE_HOME");
    if (base.isEmpty())
        base = QDir::homePath() + QStringLiteral("/.local/state");
    return base + QStringLiteral("/minos/theme");
}

ThemeInfo ThemeManager::readPack(const QString &dir)
{
    ThemeInfo t;
    QFile f(dir + QStringLiteral("/theme.json"));
    if (!f.open(QIODevice::ReadOnly))
        return t;
    QJsonParseError err;
    const QJsonDocument doc = QJsonDocument::fromJson(f.readAll(), &err);
    if (err.error != QJsonParseError::NoError || !doc.isObject()) {
        qCWarning(lcTheme) << "invalid theme.json in" << dir << err.errorString();
        return t;
    }
    const QJsonObject o = doc.object();
    auto rel = [&](const QString &key, const QString &fallback) {
        const QString v = o.value(key).toString(fallback);
        return v.isEmpty() ? QString() : QDir(dir).absoluteFilePath(v);
    };
    t.id = o.value(QStringLiteral("id")).toString();
    t.displayName = o.value(QStringLiteral("displayName")).toString(t.id);
    t.description = o.value(QStringLiteral("description")).toString();
    t.dir = dir;
    t.tokensPath = rel(QStringLiteral("tokens"), QStringLiteral("tokens.json"));
    t.assetsDir = rel(QStringLiteral("assets"), QStringLiteral("assets"));
    t.wallpaper = rel(QStringLiteral("wallpaper"), QStringLiteral("wallpaper.png"));
    t.preview = rel(QStringLiteral("preview"), QStringLiteral("preview.png"));
    t.labwcThemerc = rel(QStringLiteral("labwcThemerc"), QStringLiteral("labwc/themerc"));
    t.wallpaperFill = o.value(QStringLiteral("wallpaperFill")).toString(QStringLiteral("#000000"));
    t.isDefault = o.value(QStringLiteral("default")).toBool(false);
    if (t.id.isEmpty() || !QFileInfo::exists(t.tokensPath)) {
        qCWarning(lcTheme) << "theme pack" << dir << "lacks id or tokens.json — skipped";
        return ThemeInfo();
    }
    return t;
}

void ThemeManager::rescan()
{
    QVector<ThemeInfo> found;
    for (const QString &base : searchDirs()) {
        QDir d(base);
        if (!d.exists())
            continue;
        for (const QString &sub : d.entryList(QDir::Dirs | QDir::NoDotAndDotDot, QDir::Name)) {
            ThemeInfo t = readPack(d.absoluteFilePath(sub));
            if (!t.valid())
                continue;
            bool dup = false;
            for (const ThemeInfo &e : found)
                if (e.id == t.id) { dup = true; break; }   // 앞선 검색 경로(사용자) 우선
            if (!dup)
                found.append(t);
        }
    }
    m_themes = found;
    qCDebug(lcTheme) << "themes:" << m_themes.size() << "search dirs:" << searchDirs();
    emit themesChanged();
}

ThemeInfo ThemeManager::theme(const QString &id) const
{
    for (const ThemeInfo &t : m_themes)
        if (t.id == id)
            return t;
    return ThemeInfo();
}

QString ThemeManager::defaultId() const
{
    // 시스템 기본값 파일 > 팩의 default 표시 > 내장 기본
    QSettings sys(QStringLiteral("/etc/minos/theme.conf"), QSettings::IniFormat);
    const QString fromSys = sys.value(QStringLiteral("appearance/theme")).toString();
    if (!fromSys.isEmpty() && theme(fromSys).valid())
        return fromSys;
    for (const ThemeInfo &t : m_themes)
        if (t.isDefault)
            return t.id;
    if (theme(builtinDefaultId()).valid())
        return builtinDefaultId();
    return m_themes.isEmpty() ? builtinDefaultId() : m_themes.first().id;
}

QVariantList ThemeManager::themesForQml() const
{
    QVariantList list;
    for (const ThemeInfo &t : m_themes) {
        QVariantMap m;
        m[QStringLiteral("id")] = t.id;
        m[QStringLiteral("displayName")] = t.displayName;
        m[QStringLiteral("description")] = t.description;
        m[QStringLiteral("preview")] = QFileInfo::exists(t.preview) ? QUrl::fromLocalFile(t.preview).toString() : QString();
        m[QStringLiteral("isDefault")] = t.id == defaultId();
        m[QStringLiteral("current")] = t.id == m_currentId;
        list << m;
    }
    return list;
}

static QVariantMap jsonGroup(const QJsonObject &root, const QString &key)
{
    QVariantMap out;
    const QJsonObject g = root.value(key).toObject();
    for (auto it = g.begin(); it != g.end(); ++it)
        if (!it.key().startsWith(QLatin1Char('_')))
            out[it.key()] = it.value().toVariant();
    return out;
}

QVariantMap ThemeManager::tokensFor(const ThemeInfo &t) const
{
    QVariantMap out;
    if (!t.valid())
        return out;
    QFile f(t.tokensPath);
    if (!f.open(QIODevice::ReadOnly))
        return out;
    const QJsonObject root = QJsonDocument::fromJson(f.readAll()).object();
    if (root.isEmpty())
        return out;
    out[QStringLiteral("themeId")] = t.id;
    out[QStringLiteral("displayName")] = t.displayName;
    out[QStringLiteral("color")] = jsonGroup(root, QStringLiteral("color"));
    out[QStringLiteral("window")] = jsonGroup(root, QStringLiteral("window"));
    out[QStringLiteral("size")] = jsonGroup(root, QStringLiteral("size"));
    QVariantMap font;
    const QJsonObject fo = root.value(QStringLiteral("font")).toObject();
    font[QStringLiteral("family")] = fo.value(QStringLiteral("family")).toString();
    font[QStringLiteral("familyKo")] = fo.value(QStringLiteral("familyKo")).toString();
    font[QStringLiteral("monoFamily")] = fo.value(QStringLiteral("monoFamily")).toString();
    font[QStringLiteral("size")] = fo.value(QStringLiteral("size")).toInt();
    font[QStringLiteral("sizeSmall")] = fo.value(QStringLiteral("sizeSmall")).toInt();
    font[QStringLiteral("sizeTitle")] = fo.value(QStringLiteral("sizeTitle")).toInt();
    font[QStringLiteral("lineHeight")] = fo.value(QStringLiteral("lineHeight")).toDouble();
    out[QStringLiteral("font")] = font;
    QVariantMap assets;
    QDir ad(t.assetsDir);
    if (ad.exists())
        for (const QString &svg : ad.entryList({ QStringLiteral("*.svg") }, QDir::Files, QDir::Name))
            assets[svg.chopped(4)] = QUrl::fromLocalFile(ad.absoluteFilePath(svg)).toString();
    out[QStringLiteral("assets")] = assets;
    out[QStringLiteral("wallpaper")] = effectiveWallpaper();
    return out;
}

bool ThemeManager::apply(const QString &id, bool persist)
{
    ThemeInfo t = theme(id);
    bool ok = true;
    if (!t.valid()) {
        qCWarning(lcTheme) << "unknown theme" << id << "— reverting to default" << defaultId();
        t = theme(defaultId());
        ok = false;
    }
    if (t.valid() && tokensFor(t).isEmpty()) {
        qCWarning(lcTheme) << "theme" << t.id << "has unreadable tokens — reverting to default";
        t = theme(defaultId());
        ok = false;
    }
    if (!t.valid()) {
        qCWarning(lcTheme) << "no usable theme pack found in" << searchDirs();
        return false;
    }
    if (!QFileInfo::exists(t.wallpaper))
        qCWarning(lcTheme) << "theme" << t.id << "wallpaper missing:" << t.wallpaper << "(default theme wallpaper will be used)";
    m_currentId = t.id;
    m_envOverride = false;
    if (persist)
        saveSettings();
    writeState(t);
    emit changed();
    emit wallpaperChanged();
    if (persist)
        reloadSession();
    return ok;
}

bool ThemeManager::resetToDefault() { return apply(defaultId(), true); }

bool ThemeManager::syncState()
{
    const ThemeInfo t = current();
    return t.valid() && writeState(t);
}

bool ThemeManager::writeState(const ThemeInfo &t)
{
    QDir().mkpath(stateDir());
    auto write = [&](const QString &name, const QByteArray &data) {
        QFile f(stateDir() + QLatin1Char('/') + name);
        if (!f.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
            qCWarning(lcTheme) << "cannot write" << f.fileName();
            return false;
        }
        f.write(data);
        return true;
    };
    bool ok = write(QStringLiteral("current"), t.id.toUtf8() + '\n');
    QFile rc(t.labwcThemerc);
    QByteArray themerc;
    if (rc.open(QIODevice::ReadOnly))
        themerc = rc.readAll();
    else
        qCWarning(lcTheme) << "theme" << t.id << "has no labwc themerc:" << t.labwcThemerc;
    ok = write(QStringLiteral("themerc-override"), themerc) && ok;
    ok = write(QStringLiteral("wallpaper"), effectiveWallpaper().toUtf8() + '\n') && ok;
    ok = write(QStringLiteral("wallpaper-fill"), t.wallpaperFill.toUtf8() + '\n') && ok;
    return ok;
}

void ThemeManager::saveSettings()
{
    QSettings s(configFilePath(), QSettings::IniFormat);
    s.beginGroup(QStringLiteral("appearance"));
    s.setValue(QStringLiteral("theme"), m_currentId);
    s.setValue(QStringLiteral("useThemeWallpaper"), m_useThemeWallpaper);
    if (m_userWallpaper.isEmpty())
        s.remove(QStringLiteral("wallpaper"));
    else
        s.setValue(QStringLiteral("wallpaper"), m_userWallpaper);
    s.endGroup();
    s.sync();
    watchSettings();   // 파일이 새로 생겼을 수 있다
}

void ThemeManager::loadSettings()
{
    QSettings s(configFilePath(), QSettings::IniFormat);
    s.beginGroup(QStringLiteral("appearance"));
    const QString saved = s.value(QStringLiteral("theme")).toString();
    m_currentId = saved.isEmpty() ? defaultId() : saved;
    m_useThemeWallpaper = s.value(QStringLiteral("useThemeWallpaper"), true).toBool();
    m_userWallpaper = s.value(QStringLiteral("wallpaper")).toString();
    s.endGroup();
}

void ThemeManager::reloadFromSettings()
{
    if (m_envOverride)
        return;
    const QString before = m_currentId;
    const bool wBefore = m_useThemeWallpaper;
    const QString uBefore = m_userWallpaper;
    loadSettings();
    if (!theme(m_currentId).valid())
        m_currentId = defaultId();
    if (m_currentId != before) {
        qCInfo(lcTheme) << "theme changed externally:" << before << "→" << m_currentId;
        emit changed();
    }
    if (m_currentId != before || wBefore != m_useThemeWallpaper || uBefore != m_userWallpaper)
        emit wallpaperChanged();
}

void ThemeManager::watchSettings()
{
    if (!m_watcher) {
        m_watcher = new QFileSystemWatcher(this);
        connect(m_watcher, &QFileSystemWatcher::fileChanged, this, [this] {
            // 편집기·QSettings 는 파일을 교체하므로 잠시 뒤 다시 읽고 감시를 재등록한다
            QTimer::singleShot(100, this, [this] { reloadFromSettings(); watchSettings(); });
        });
        connect(m_watcher, &QFileSystemWatcher::directoryChanged, this, [this] {
            QTimer::singleShot(100, this, [this] { reloadFromSettings(); watchSettings(); });
        });
    }
    const QString file = configFilePath();
    const QString dir = QFileInfo(file).absolutePath();
    QDir().mkpath(dir);   // 설정 파일이 아직 없어도 디렉터리를 감시할 수 있게 만든다 (다른 프로세스가 처음 쓰는 경우)
    if (QFileInfo::exists(file) && !m_watcher->files().contains(file))
        m_watcher->addPath(file);
    if (QFileInfo::exists(dir) && !m_watcher->directories().contains(dir))
        m_watcher->addPath(dir);
}

void ThemeManager::setUseThemeWallpaper(bool v)
{
    if (m_useThemeWallpaper == v)
        return;
    m_useThemeWallpaper = v;
    saveSettings();
    writeState(current());
    emit wallpaperChanged();
    reloadSession();
}

void ThemeManager::setUserWallpaper(const QString &path)
{
    QString p = path.trimmed();
    if (p.startsWith(QLatin1String("file://")))
        p = QUrl(p).toLocalFile();
    if (m_userWallpaper == p)
        return;
    m_userWallpaper = p;
    if (!p.isEmpty())
        m_useThemeWallpaper = false;
    saveSettings();
    writeState(current());
    emit wallpaperChanged();
    reloadSession();
}

QString ThemeManager::effectiveWallpaper() const
{
    if (!m_useThemeWallpaper && !m_userWallpaper.isEmpty() && QFileInfo::exists(m_userWallpaper))
        return m_userWallpaper;
    const ThemeInfo t = current();
    if (QFileInfo::exists(t.wallpaper))
        return t.wallpaper;
    const ThemeInfo d = theme(defaultId());
    if (QFileInfo::exists(d.wallpaper))
        return d.wallpaper;
    return QString();
}

bool ThemeManager::sessionReloadSupported() const
{
    return !qEnvironmentVariableIsEmpty("WAYLAND_DISPLAY") && !QStandardPaths::findExecutable(QStringLiteral("labwc")).isEmpty();
}

void ThemeManager::reloadSession()
{
    if (qEnvironmentVariableIsSet("HAGRA_THEME_NO_SESSION_RELOAD") || qEnvironmentVariableIsEmpty("WAYLAND_DISPLAY"))
        return;
    // labwc: 설정·테마 재읽기 (SIGHUP 과 동일한 지원 절차; themerc-override 는 관리 상태 파일에 다시 썼다)
    if (qEnvironmentVariableIsSet("LABWC_PID") && !QStandardPaths::findExecutable(QStringLiteral("labwc")).isEmpty())
        QProcess::startDetached(QStringLiteral("labwc"), { QStringLiteral("--reconfigure") });
    else
        QProcess::startDetached(QStringLiteral("pkill"), { QStringLiteral("-HUP"), QStringLiteral("-x"), QStringLiteral("labwc") });   // 같은 효과 (labwc 가 SIGHUP 에 재구성)
    // 배경: swaybg 는 재읽기가 없으므로 다시 띄운다 (세션 스크립트와 같은 인자)
    const QString wall = effectiveWallpaper();
    if (!QStandardPaths::findExecutable(QStringLiteral("swaybg")).isEmpty()) {
        QProcess kill;
        kill.start(QStringLiteral("pkill"), { QStringLiteral("-x"), QStringLiteral("swaybg") });
        kill.waitForFinished(2000);
        QStringList args{ QStringLiteral("-m"), QStringLiteral("fill"), QStringLiteral("-c"), current().wallpaperFill };
        if (!wall.isEmpty())
            args << QStringLiteral("-i") << wall;
        QProcess::startDetached(QStringLiteral("swaybg"), args);
    }
    qCInfo(lcTheme) << "session reload requested for theme" << m_currentId << "wallpaper" << wall;
}

void ThemeManager::registerQmlTypes(ThemeManager *mgr)
{
    qmlRegisterSingletonInstance("HagraTheme", 1, 0, "ThemeManager", mgr);
}

bool ThemeManager::bindEngine(QQmlEngine *engine, ThemeManager *mgr)
{
    // MinUI.Theme 은 qmldir 의 composite singleton 이라 qmlTypeId 로 바로 찾을 수 없다.
    // 작은 QML 글루 객체를 엔진 안에서 만들어 Theme.applyTokens() 를 호출한다 (import 경로·캐시를 그대로 사용).
    auto *component = new QQmlComponent(engine, engine);
    component->setData(QByteArrayLiteral("import QtQuick\nimport MinUI 1.0\nQtObject { function apply(t) { Theme.applyTokens(t) } }"),
                       QUrl::fromLocalFile(QStringLiteral("/hagratheme-bind.qml")));   // 알 수 없는 scheme 이면 Loading 에 머문다
    if (component->isLoading()) {   // 모듈을 아직 읽는 중이면 짧게 기다린다 (보통 호스트 QML 이 이미 MinUI 를 import 했으므로 즉시 준비됨)
        QElapsedTimer t; t.start();
        while (component->isLoading() && t.elapsed() < 3000)
            QCoreApplication::processEvents(QEventLoop::AllEvents, 20);
    }
    QObject *glue = component->isReady() ? component->create() : nullptr;
    if (!glue) {
        qCWarning(lcTheme) << "cannot bind MinUI.Theme:" << component->errorString();
        delete component;
        return false;
    }
    glue->setParent(engine);
    auto push = [engine, glue, mgr] {
        QJSValue v = engine->toScriptValue(mgr->tokens());
        QMetaObject::invokeMethod(glue, "apply", Q_ARG(QVariant, v.toVariant()));
        qCDebug(lcTheme) << "applied theme tokens" << mgr->currentId();
    };
    push();
    QObject::connect(mgr, &ThemeManager::changed, glue, push);
    return true;
}

} // namespace HagraTheme
