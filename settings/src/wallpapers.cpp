// SPDX-License-Identifier: GPL-3.0-or-later
#include "wallpapers.h"
#include <QDir>
#include <QFileInfo>
#include <QImageReader>
#include <QStandardPaths>
#include <QUrl>
#include "hagratheme/thememanager.h"

Wallpapers::Wallpapers(QObject *parent) : QObject(parent) { refresh(); }

QString Wallpapers::userDir() const
{
    return QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation) + QStringLiteral("/hagra/wallpapers");
}

QStringList Wallpapers::searchDirs() const
{
    QStringList d;
    d << userDir();
    d << QStandardPaths::writableLocation(QStandardPaths::PicturesLocation) + QStringLiteral("/Wallpapers");
    d << QStandardPaths::writableLocation(QStandardPaths::PicturesLocation) + QStringLiteral("/배경");
    for (const QString &g : QStandardPaths::standardLocations(QStandardPaths::GenericDataLocation))
        d << g + QStringLiteral("/hagra/wallpaper") << g + QStringLiteral("/backgrounds");
    for (const QString &p : qEnvironmentVariable("HAGRA_WALLPAPER_PATH").split(QLatin1Char(':'), Qt::SkipEmptyParts)) d.prepend(p);
    d.removeDuplicates();
    return d;
}

bool Wallpapers::isImage(const QString &path) const
{
    QString p = path;
    if (p.startsWith(QLatin1String("file://"))) p = QUrl(p).toLocalFile();
    if (!QFileInfo(p).isFile()) return false;
    QImageReader r(p);
    return r.canRead();
}

void Wallpapers::refresh()
{
    m_items.clear();
    QStringList seen;
    auto add = [&](const QString &path, const QString &title, const QString &source) {
        const QString abs = QFileInfo(path).absoluteFilePath();
        if (seen.contains(abs) || !QFileInfo(abs).isFile()) return;
        seen << abs;
        m_items << QVariantMap{ { QStringLiteral("path"), abs }, { QStringLiteral("url"), QUrl::fromLocalFile(abs).toString() },
                                { QStringLiteral("title"), title }, { QStringLiteral("source"), source } };
    };
    HagraTheme::ThemeManager tm;   // 테마 팩 배경 (설정 저장 없음, 조회만)
    for (const auto &t : tm.themes())
        add(t.wallpaper, t.displayName + QStringLiteral(" 테마 배경"), QStringLiteral("theme"));
    for (const QString &dir : searchDirs()) {
        QDir d(dir);
        if (!d.exists()) continue;
        for (const QString &f : d.entryList({ QStringLiteral("*.png"), QStringLiteral("*.jpg"), QStringLiteral("*.jpeg"), QStringLiteral("*.webp") }, QDir::Files, QDir::Name))
            add(d.absoluteFilePath(f), QFileInfo(f).completeBaseName(), dir.startsWith(QDir::homePath()) ? QStringLiteral("user") : QStringLiteral("system"));
    }
    emit refreshed();
}
