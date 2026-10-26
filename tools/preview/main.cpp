// minui-preview — QML 미리보기 실행기
//   minui-preview FILE.qml [--scale 1.5] [--state NAME] [--icons DIR] [--title T]
// --scale  : QT_SCALE_FACTOR (논리 픽셀 배율). Wayland 출력 배율(wlr-randr --scale)과는 별개.
// --state  : QML 에서 `previewState` 컨텍스트 속성으로 읽는다 (갤러리 섹션, 장면의 메뉴/대화상자 열림 등).
// --icons  : Theme.iconBasePath (기본: $HAGRA_ICON_PATH 또는 설치 경로 /usr/share/hagra/icons)
// SPDX-License-Identifier: GPL-3.0-or-later
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QFileInfo>
#include <QDir>
#include <cstdio>
#include <cstring>
#include "hagratheme/thememanager.h"

int main(int argc, char *argv[])
{
    QString file, state, icons, title, scale;
    for (int i = 1; i < argc; ++i) {
        if (!strcmp(argv[i], "--scale") && i + 1 < argc) scale = argv[++i];
        else if (!strcmp(argv[i], "--state") && i + 1 < argc) state = argv[++i];
        else if (!strcmp(argv[i], "--icons") && i + 1 < argc) icons = argv[++i];
        else if (!strcmp(argv[i], "--title") && i + 1 < argc) title = argv[++i];
        else if (argv[i][0] != '-') file = argv[i];
    }
    if (file.isEmpty()) { fprintf(stderr, "usage: minui-preview FILE.qml [--scale F] [--state NAME] [--icons DIR] [--title T]\n"); return 2; }
    if (!scale.isEmpty()) qputenv("QT_SCALE_FACTOR", scale.toUtf8());
    if (qEnvironmentVariableIsEmpty("QT_QPA_PLATFORM")) qputenv("QT_QPA_PLATFORM", "wayland");
    qputenv("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1"); // 창 장식은 labwc(SSD)

    QGuiApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("minui-preview"));
    app.setDesktopFileName(QStringLiteral("org.hagra.preview"));
    QQuickStyle::setStyle(QStringLiteral("Basic"));

    if (icons.isEmpty()) icons = qEnvironmentVariable("HAGRA_ICON_PATH", QStringLiteral("/usr/share/hagra/icons"));

    HagraTheme::ThemeManager themeManager;   // 저장된 선택 또는 $HAGRA_THEME (캡처용, 저장 안 함)
    HagraTheme::ThemeManager::registerQmlTypes(&themeManager);

    QQmlApplicationEngine engine;
    engine.addImportPath(QStringLiteral(MINOS_QML_INSTALL_DIR));
    for (const QString &p : qEnvironmentVariable("MINOS_QML_IMPORT_PATH").split(QLatin1Char(':'), Qt::SkipEmptyParts))
        engine.addImportPath(p);
    engine.rootContext()->setContextProperty(QStringLiteral("previewState"), state);
    engine.rootContext()->setContextProperty(QStringLiteral("previewTitle"), title);
    engine.rootContext()->setContextProperty(QStringLiteral("previewIconPath"), icons);
    engine.rootContext()->setContextProperty(QStringLiteral("previewScale"), scale.isEmpty() ? 1.0 : scale.toDouble());
    engine.load(QUrl::fromLocalFile(QFileInfo(file).absoluteFilePath()));
    if (engine.rootObjects().isEmpty()) return 1;
    HagraTheme::ThemeManager::bindEngine(&engine, &themeManager);
    fprintf(stderr, "minui-preview: %s state=%s scale=%s theme=%s\n", qPrintable(file), qPrintable(state), scale.isEmpty() ? "1" : qPrintable(scale), qPrintable(themeManager.currentId()));
    return app.exec();
}
