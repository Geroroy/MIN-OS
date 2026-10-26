// MIN Shell — 진입점
// SPDX-License-Identifier: GPL-3.0-or-later
#include <QCommandLineParser>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QLoggingCategory>

#include "minlayershell/layershell.h"
#include "minlayershell/layerwindow.h"
#include "hagratheme/thememanager.h"
#include "appindex.h"
#include "power.h"
#include "shellipc.h"
#include "toplevelmodel.h"

int main(int argc, char *argv[])
{
    MinLayerShell::prepareEnvironment();
    // GPU가 없는 환경(QEMU TCG 등)에서는 세션 스크립트가 QT_QUICK_BACKEND=software 를 설정한다.
    QGuiApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("minos-shell"));
    app.setApplicationVersion(QStringLiteral(MINOS_VERSION));
    app.setOrganizationName(QStringLiteral("MIN OS"));
    app.setOrganizationDomain(QStringLiteral("minos.local"));
    app.setDesktopFileName(QStringLiteral("org.minos.shell"));
    app.setQuitOnLastWindowClosed(false);

    QCommandLineParser parser;
    parser.setApplicationDescription(QStringLiteral("HAGRA desktop shell (panel, launcher, power menu)"));
    parser.addHelpOption();
    parser.addVersionOption();
    QCommandLineOption toggleLauncher(QStringLiteral("toggle-launcher"), QStringLiteral("Toggle the application launcher"));
    QCommandLineOption showLauncher(QStringLiteral("show-launcher"), QStringLiteral("Show the application launcher"));
    QCommandLineOption power(QStringLiteral("power"), QStringLiteral("Toggle the power menu"));
    QCommandLineOption quit(QStringLiteral("quit"), QStringLiteral("Ask the running shell to quit"));
    QCommandLineOption terminal(QStringLiteral("terminal"), QStringLiteral("Launch the default terminal"));
    QCommandLineOption appearance(QStringLiteral("appearance"), QStringLiteral("Open the appearance (theme) settings window"));
    parser.addOptions({ toggleLauncher, showLauncher, power, quit, terminal, appearance });
    parser.process(app);

    QString command;
    if (parser.isSet(toggleLauncher)) command = QStringLiteral("toggle-launcher");
    else if (parser.isSet(showLauncher)) command = QStringLiteral("show-launcher");
    else if (parser.isSet(power)) command = QStringLiteral("power");
    else if (parser.isSet(quit)) command = QStringLiteral("quit");
    else if (parser.isSet(terminal)) command = QStringLiteral("terminal");
    else if (parser.isSet(appearance)) command = QStringLiteral("appearance");

    // 이미 실행 중이면 명령만 전달하고 끝낸다.
    if (ShellIpc::sendToRunningInstance(command.isEmpty() ? QStringLiteral("ping") : command))
        return 0;
    if (command == QLatin1String("quit"))
        return 0;

    QQuickStyle::setStyle(QStringLiteral("Basic"));

    ShellIpc ipc;
    ipc.listen();
    Power powerCtl;
    AppIndex apps;
    ToplevelModel toplevels;
    HagraTheme::ThemeManager themeManager;   // 저장된 테마 선택 복원 (~/.config/minos/theme.conf); 외부 변경 감시

    MinLayerShell::LayerWindow::registerQmlTypes();
    HagraTheme::ThemeManager::registerQmlTypes(&themeManager);
    qmlRegisterSingletonInstance("MinShell", 1, 0, "Shell", &ipc);
    qmlRegisterSingletonInstance("MinShell", 1, 0, "Power", &powerCtl);
    qmlRegisterSingletonInstance("MinShell", 1, 0, "Apps", &apps);
    qmlRegisterSingletonInstance("MinShell", 1, 0, "Toplevels", &toplevels);

    QQmlApplicationEngine engine;
    engine.addImportPath(QStringLiteral(MINOS_QML_INSTALL_DIR));
    for (const QString &p : qEnvironmentVariable("MINOS_QML_IMPORT_PATH").split(QLatin1Char(':'), Qt::SkipEmptyParts))
        engine.addImportPath(p);
    engine.load(QUrl(QStringLiteral("qrc:/qml/Main.qml")));
    if (engine.rootObjects().isEmpty())
        return 1;
    HagraTheme::ThemeManager::bindEngine(&engine, &themeManager);   // MinUI.Theme 에 현재 테마 토큰 적용 + 변경 시 재적용

    QObject::connect(&ipc, &ShellIpc::quitRequested, &app, &QGuiApplication::quit, Qt::QueuedConnection);
    QObject::connect(&ipc, &ShellIpc::launchTerminal, &apps, [&apps] { apps.launchCommand(apps.terminalProgram()); });
    if (!command.isEmpty())
        ipc.dispatch(command);

    qInfo("minos-shell %s ready", MINOS_VERSION);
    return app.exec();
}
