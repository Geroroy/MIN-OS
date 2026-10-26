// 하그라 테마 관리자 — 테마 팩 레지스트리, 선택 저장/복원, 런타임 적용.
//   테마 팩: <dir>/<id>/theme.json + tokens.json + assets/ + wallpaper.png + preview.png + labwc/themerc
//   검색 경로: $HAGRA_THEME_PATH(:구분) → ~/.local/share/hagra/themes → /usr/share/hagra/themes (MINOS_THEME_INSTALL_DIR)
//   선택 저장: ~/.config/minos/theme.conf [appearance] theme=, wallpaper=, useThemeWallpaper=   (docs/ARCHITECTURE.md §2.6)
//   관리 상태: ~/.local/state/minos/theme/{current, themerc-override, wallpaper}  ← minos-session·autostart 가 읽는다
//   런타임: 변경 시 changed() → 호스트가 MinUI.Theme.applyTokens(tokens()) 호출 (bindEngine). labwc 는 --reconfigure, 배경은 swaybg 재시작.
//   다른 프로세스의 변경은 theme.conf 를 감시해 따라간다.
// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once
#include <QObject>
#include <QString>
#include <QStringList>
#include <QVariantList>
#include <QVariantMap>
#include <QVector>

class QFileSystemWatcher;
class QQmlEngine;

namespace HagraTheme {

struct ThemeInfo {
    QString id;
    QString displayName;
    QString description;
    QString dir;
    QString tokensPath;
    QString assetsDir;
    QString wallpaper;
    QString preview;
    QString labwcThemerc;
    QString wallpaperFill;   // swaybg -c (배경 이미지 바깥 색)
    bool isDefault = false;
    bool valid() const { return !id.isEmpty() && !tokensPath.isEmpty(); }
};

class ThemeManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString currentId READ currentId NOTIFY changed)
    Q_PROPERTY(QString currentName READ currentName NOTIFY changed)
    Q_PROPERTY(QString defaultId READ defaultId NOTIFY themesChanged)
    Q_PROPERTY(QVariantList themes READ themesForQml NOTIFY themesChanged)
    Q_PROPERTY(QVariantMap tokens READ tokens NOTIFY changed)
    Q_PROPERTY(bool useThemeWallpaper READ useThemeWallpaper WRITE setUseThemeWallpaper NOTIFY wallpaperChanged)
    Q_PROPERTY(QString userWallpaper READ userWallpaper WRITE setUserWallpaper NOTIFY wallpaperChanged)
    Q_PROPERTY(QString effectiveWallpaper READ effectiveWallpaper NOTIFY wallpaperChanged)
    Q_PROPERTY(bool sessionReloadSupported READ sessionReloadSupported CONSTANT)
public:
    explicit ThemeManager(QObject *parent = nullptr);
    ~ThemeManager() override;

    static QString builtinDefaultId();           // "hagra-dancheong-light"
    static QStringList searchDirs();
    static QString configFilePath();             // ~/.config/minos/theme.conf
    static QString stateDir();                   // ~/.local/state/minos/theme

    void rescan();
    QVector<ThemeInfo> themes() const { return m_themes; }
    QVariantList themesForQml() const;
    ThemeInfo theme(const QString &id) const;
    ThemeInfo current() const { return theme(m_currentId); }
    QString currentId() const { return m_currentId; }
    QString currentName() const { return current().displayName; }
    QString defaultId() const;

    /// MinUI.Theme.applyTokens() 형식: { themeId, displayName, color:{}, window:{}, size:{}, font:{}, assets:{name:url} }
    QVariantMap tokens() const { return tokensFor(current()); }
    QVariantMap tokensFor(const ThemeInfo &t) const;

    /// 테마 선택. 알 수 없는 ID·토큰 손상이면 기본 테마로 복귀하고 false. persist=false 면 저장하지 않는다(미리보기).
    Q_INVOKABLE bool apply(const QString &id, bool persist = true);
    Q_INVOKABLE bool resetToDefault();
    /// 저장된 선택으로 관리 상태 파일(themerc-override, wallpaper)을 다시 쓴다. 세션 시작 시 호출.
    Q_INVOKABLE bool syncState();
    Q_INVOKABLE void reloadFromSettings();

    bool useThemeWallpaper() const { return m_useThemeWallpaper; }
    void setUseThemeWallpaper(bool v);
    QString userWallpaper() const { return m_userWallpaper; }
    void setUserWallpaper(const QString &path);
    QString effectiveWallpaper() const;
    bool sessionReloadSupported() const;

    /// 실행 중 세션에 반영: labwc --reconfigure, swaybg 재시작. WAYLAND_DISPLAY 가 없으면 아무것도 하지 않는다.
    Q_INVOKABLE void reloadSession();

    /// 호스트 연결: 엔진의 MinUI.Theme 싱글톤에 tokens() 를 적용하고 changed() 마다 다시 적용한다. QML 로드 후 호출.
    static void registerQmlTypes(ThemeManager *mgr);
    static bool bindEngine(QQmlEngine *engine, ThemeManager *mgr);

Q_SIGNALS:
    void changed();
    void themesChanged();
    void wallpaperChanged();

private:
    static ThemeInfo readPack(const QString &dir);
    bool writeState(const ThemeInfo &t);
    void saveSettings();
    void loadSettings();
    void watchSettings();
    QString envOverride() const;

    QVector<ThemeInfo> m_themes;
    QString m_currentId;
    QString m_userWallpaper;
    bool m_useThemeWallpaper = true;
    bool m_envOverride = false;
    QFileSystemWatcher *m_watcher = nullptr;
};

} // namespace HagraTheme
