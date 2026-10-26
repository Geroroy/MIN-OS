// SPDX-License-Identifier: GPL-3.0-or-later
#include "launcherstate.h"

#include <QDir>
#include <QFileInfo>
#include <QFileSystemWatcher>
#include <QLoggingCategory>
#include <QSettings>
#include <QStandardPaths>
#include <QTimer>

Q_LOGGING_CATEGORY(lcLauncher, "hagra.launcher")

LauncherState::LauncherState(QObject *parent) : QObject(parent)
{
    reload();
    watch();
}

QString LauncherState::configPath()
{
    return QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation) + QStringLiteral("/hagra/launcher.conf");
}

QString LauncherState::statePath()
{
    QString base = qEnvironmentVariable("XDG_STATE_HOME");
    if (base.isEmpty())
        base = QDir::homePath() + QStringLiteral("/.local/state");
    return base + QStringLiteral("/hagra/launcher-recent.conf");
}

void LauncherState::reload()
{
    const QStringList favBefore = m_favorites, recBefore = m_recent;
    QSettings s(configPath(), QSettings::IniFormat);
    m_hasConfig = s.contains(QStringLiteral("launcher/favorites"));
    m_favorites = s.value(QStringLiteral("launcher/favorites")).toStringList();
    m_favorites.removeAll(QString());
    m_favorites.removeDuplicates();
    QSettings r(statePath(), QSettings::IniFormat);
    m_recent = r.value(QStringLiteral("recent/ids")).toStringList();
    m_recent.removeAll(QString());
    m_recent.removeDuplicates();
    while (m_recent.size() > maxRecent())
        m_recent.removeLast();
    if (favBefore != m_favorites)
        emit favoritesChanged();
    if (recBefore != m_recent)
        emit recentChanged();
}

void LauncherState::seedDefaults(const QStringList &availableIds)
{
    if (m_hasConfig)
        return;
    QStringList seed;
    for (const QString &cand : { QStringLiteral("org.hagra.settings"), QStringLiteral("org.codeberg.dnkl.foot"),
                                 QStringLiteral("hagra-terminal"), QStringLiteral("org.hagra.files") })
        if (availableIds.contains(cand))
            seed << cand;
    if (seed == m_favorites)
        return;
    m_favorites = seed;
    emit favoritesChanged();   // 저장하지 않는다: 사용자가 처음 바꿀 때 파일이 생긴다
}

void LauncherState::addFavorite(const QString &id)
{
    if (id.isEmpty() || m_favorites.contains(id))
        return;
    m_favorites << id;
    saveFavorites();
    emit favoritesChanged();
}

void LauncherState::removeFavorite(const QString &id)
{
    if (!m_favorites.removeAll(id))
        return;
    saveFavorites();
    emit favoritesChanged();
}

void LauncherState::toggleFavorite(const QString &id)
{
    if (m_favorites.contains(id)) removeFavorite(id); else addFavorite(id);
}

void LauncherState::moveFavorite(const QString &id, int delta)
{
    const int i = m_favorites.indexOf(id);
    const int j = i + delta;
    if (i < 0 || j < 0 || j >= m_favorites.size())
        return;
    m_favorites.move(i, j);
    saveFavorites();
    emit favoritesChanged();
}

void LauncherState::noteLaunch(const QString &id)
{
    if (id.isEmpty() || id.contains(QLatin1Char('/')) || id.contains(QLatin1Char(' ')))
        return;   // 임의 명령(launchCommand)은 기록하지 않는다
    m_recent.removeAll(id);
    m_recent.prepend(id);
    while (m_recent.size() > maxRecent())
        m_recent.removeLast();
    saveRecent();
    emit recentChanged();
}

void LauncherState::clearRecent()
{
    if (m_recent.isEmpty())
        return;
    m_recent.clear();
    saveRecent();
    emit recentChanged();
}

void LauncherState::saveFavorites()
{
    QDir().mkpath(QFileInfo(configPath()).absolutePath());
    QSettings s(configPath(), QSettings::IniFormat);
    s.setValue(QStringLiteral("launcher/favorites"), m_favorites);
    s.sync();
    m_hasConfig = true;
    watch();
}

void LauncherState::saveRecent()
{
    QDir().mkpath(QFileInfo(statePath()).absolutePath());
    QSettings r(statePath(), QSettings::IniFormat);
    r.setValue(QStringLiteral("recent/ids"), m_recent);
    r.sync();
    watch();
}

void LauncherState::watch()
{
    if (!m_watcher) {
        m_watcher = new QFileSystemWatcher(this);
        auto later = [this] { QTimer::singleShot(150, this, [this] { reload(); watch(); }); };
        connect(m_watcher, &QFileSystemWatcher::fileChanged, this, later);
        connect(m_watcher, &QFileSystemWatcher::directoryChanged, this, later);
    }
    for (const QString &f : { configPath(), statePath() }) {
        const QString dir = QFileInfo(f).absolutePath();
        QDir().mkpath(dir);
        if (QFileInfo::exists(f) && !m_watcher->files().contains(f))
            m_watcher->addPath(f);
        if (!m_watcher->directories().contains(dir))
            m_watcher->addPath(dir);
    }
}
