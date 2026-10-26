// SPDX-License-Identifier: GPL-3.0-or-later
#include "conffile.h"
#include <QDir>
#include <QFileInfo>
#include <QFileSystemWatcher>
#include <QSettings>
#include <QStandardPaths>
#include <QTimer>

ConfFile::ConfFile(QObject *parent) : QObject(parent) {}

QString ConfFile::dirPath()
{
    return QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation) + QStringLiteral("/hagra");
}

QString ConfFile::pathFor(const QString &name) { return dirPath() + QLatin1Char('/') + name + QStringLiteral(".conf"); }

void ConfFile::setName(const QString &n)
{
    if (m_name == n) return;
    m_name = n;
    emit nameChanged();
    watch();
    ++m_revision;
    emit changed();
}

QVariant ConfFile::get(const QString &key, const QVariant &fallback) const
{
    if (m_name.isEmpty()) return fallback;
    QSettings s(path(), QSettings::IniFormat);
    return s.value(key, fallback);
}

void ConfFile::set(const QString &key, const QVariant &value)
{
    if (m_name.isEmpty()) return;
    QDir().mkpath(dirPath());
    QSettings s(path(), QSettings::IniFormat);
    if (s.value(key) == value && s.contains(key)) return;
    s.setValue(key, value);
    s.sync();
    watch();
    ++m_revision;
    emit changed();
}

void ConfFile::remove(const QString &key)
{
    if (m_name.isEmpty()) return;
    QSettings s(path(), QSettings::IniFormat);
    if (!s.contains(key)) return;
    s.remove(key);
    s.sync();
    ++m_revision;
    emit changed();
}

bool ConfFile::contains(const QString &key) const
{
    if (m_name.isEmpty()) return false;
    QSettings s(path(), QSettings::IniFormat);
    return s.contains(key);
}

QStringList ConfFile::keys(const QString &group) const
{
    if (m_name.isEmpty()) return {};
    QSettings s(path(), QSettings::IniFormat);
    if (!group.isEmpty()) s.beginGroup(group);
    return s.allKeys();
}

void ConfFile::watch()
{
    if (!m_watcher) {
        m_watcher = new QFileSystemWatcher(this);
        auto later = [this] { QTimer::singleShot(150, this, [this] { ++m_revision; emit changed(); watch(); }); };
        connect(m_watcher, &QFileSystemWatcher::fileChanged, this, later);
        connect(m_watcher, &QFileSystemWatcher::directoryChanged, this, later);
    }
    QDir().mkpath(dirPath());
    if (!m_watcher->directories().contains(dirPath())) m_watcher->addPath(dirPath());
    const QString f = path();
    if (QFileInfo::exists(f) && !m_watcher->files().contains(f)) m_watcher->addPath(f);
}
