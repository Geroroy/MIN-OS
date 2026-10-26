// SPDX-License-Identifier: GPL-3.0-or-later
#include "appiconprovider.h"

#include <QDir>
#include <QFileInfo>
#include <QIcon>
#include <QPixmap>
#include <QStandardPaths>

AppIconProvider::AppIconProvider() : QQuickImageProvider(QQuickImageProvider::Pixmap)
{
    setupTheme();
}

void AppIconProvider::setupTheme()
{
    QStringList paths = QIcon::themeSearchPaths();
    for (const QString &d : QStandardPaths::standardLocations(QStandardPaths::GenericDataLocation)) {
        const QString p = d + QStringLiteral("/icons");
        if (!paths.contains(p) && QFileInfo::exists(p))
            paths.prepend(p);
    }
    QIcon::setThemeSearchPaths(paths);
    if (QIcon::themeName().isEmpty()) {
        // 설치된 테마 중 하나를 고른다: 환경 변수 > Adwaita > breeze > hicolor
        const QString env = qEnvironmentVariable("HAGRA_ICON_THEME");
        QStringList cands;
        if (!env.isEmpty()) cands << env;
        cands << QStringLiteral("Adwaita") << QStringLiteral("breeze") << QStringLiteral("hicolor");
        for (const QString &c : cands) {
            for (const QString &p : paths)
                if (QFileInfo::exists(p + QLatin1Char('/') + c + QStringLiteral("/index.theme"))) { QIcon::setThemeName(c); break; }
            if (!QIcon::themeName().isEmpty()) break;
        }
    }
    QIcon::setFallbackThemeName(QStringLiteral("hicolor"));
}

QString AppIconProvider::resolve(const QString &iconName)
{
    if (iconName.isEmpty())
        return {};
    if (iconName.startsWith(QLatin1Char('/')))
        return QFileInfo::exists(iconName) ? iconName : QString();
    QString base = iconName;
    for (const char *ext : { ".png", ".svg", ".xpm" })
        if (base.endsWith(QLatin1String(ext))) base.chop(int(strlen(ext)));
    for (const QString &d : QStandardPaths::standardLocations(QStandardPaths::GenericDataLocation)) {
        for (const char *ext : { ".svg", ".png", ".xpm" }) {
            const QString p = d + QStringLiteral("/pixmaps/") + base + QLatin1String(ext);
            if (QFileInfo::exists(p)) return p;
        }
    }
    return {};
}

QPixmap AppIconProvider::requestPixmap(const QString &id, QSize *size, const QSize &requestedSize)
{
    const int want = requestedSize.width() > 0 ? requestedSize.width() : 48;
    QPixmap pm;
    QString name = id;
    for (const char *ext : { ".png", ".svg", ".xpm" })
        if (name.endsWith(QLatin1String(ext)) && !name.startsWith(QLatin1Char('/'))) name.chop(int(strlen(ext)));
    if (!name.startsWith(QLatin1Char('/'))) {
        const QIcon icon = QIcon::fromTheme(name);
        if (!icon.isNull())
            pm = icon.pixmap(QSize(want, want));
    }
    if (pm.isNull()) {
        const QString file = resolve(id);
        if (!file.isEmpty()) {
            if (file.endsWith(QLatin1String(".svg")))
                pm = QIcon(file).pixmap(QSize(want, want));
            else
                pm = QPixmap(file).scaled(want, want, Qt::KeepAspectRatio, Qt::SmoothTransformation);
        }
    }
    if (size) *size = pm.size();
    return pm;   // 빈 픽스맵 → Image.status === Error → QML 대체
}
