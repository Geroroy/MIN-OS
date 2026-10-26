// 하그라 셸 — 실행 메뉴 상태: 즐겨찾기(설정)와 최근 실행(상태). 두 파일 모두 사용자 디렉터리에 있고 다른 셸 인스턴스/설정 앱이 바꾸면 따라간다.
//   즐겨찾기: ~/.config/hagra/launcher.conf   [launcher] favorites=id1,id2   (기본: 터미널·설정·파일 관리자 중 설치된 것)
//   최근 실행: ~/.local/state/hagra/launcher-recent.conf [recent] ids=...   (최대 8개, 최신 우선)
// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once
#include <QObject>
#include <QStringList>

class QFileSystemWatcher;

class LauncherState : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QStringList favorites READ favorites NOTIFY favoritesChanged)
    Q_PROPERTY(QStringList recent READ recent NOTIFY recentChanged)
    Q_PROPERTY(int maxRecent READ maxRecent CONSTANT)
public:
    explicit LauncherState(QObject *parent = nullptr);

    static QString configPath();   // launcher.conf
    static QString statePath();    // launcher-recent.conf

    QStringList favorites() const { return m_favorites; }
    QStringList recent() const { return m_recent; }
    int maxRecent() const { return 8; }

    Q_INVOKABLE bool isFavorite(const QString &id) const { return m_favorites.contains(id); }
    Q_INVOKABLE void addFavorite(const QString &id);
    Q_INVOKABLE void removeFavorite(const QString &id);
    Q_INVOKABLE void toggleFavorite(const QString &id);
    Q_INVOKABLE void moveFavorite(const QString &id, int delta);
    Q_INVOKABLE void noteLaunch(const QString &id);
    Q_INVOKABLE void clearRecent();
    /// 설정 파일에 즐겨찾기가 전혀 없을 때 쓰는 기본 목록 (설치된 항목만). availableIds 는 색인된 앱 ID.
    void seedDefaults(const QStringList &availableIds);
    Q_INVOKABLE void reload();

Q_SIGNALS:
    void favoritesChanged();
    void recentChanged();

private:
    void saveFavorites();
    void saveRecent();
    void watch();
    QStringList m_favorites;
    QStringList m_recent;
    bool m_hasConfig = false;
    QFileSystemWatcher *m_watcher = nullptr;
};
