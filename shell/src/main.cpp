// 하그라 셸 — 진입점
// SPDX-License-Identifier: GPL-3.0-or-later
#include <QCommandLineParser>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QLoggingCategory>
#include <QLocale>
#include <QTranslator>
#include <QProcess>
#include <QTimer>
#include <QWindow>
#include <QStandardPaths>

#include "hagralayershell/layershell.h"
#include "hagralayershell/layerwindow.h"
#include "hagratheme/thememanager.h"
#include "appindex.h"
#include "conffile.h"
#include "notificationserver.h"
#include "systemstatus.h"
#include "appiconprovider.h"
#include "launcherstate.h"
#include "power.h"
#include "shellipc.h"
#include "toplevelmodel.h"


// 번역: 원문은 한국어. LANGUAGE/LC_MESSAGES/LANG 이 한국어가 아니면 <base>_<lang>.qm 을 찾는다 ($HAGRA_TRANSLATIONS → 설치 경로).
static void hagraLoadTranslation(QCoreApplication &app, const QString &base)
{
    QLocale locale;
    if (locale.language() == QLocale::C) locale = QLocale(QStringLiteral("en_US"));   // POSIX/C 로케일은 영어 UI
    if (locale.language() == QLocale::Korean) return;
    static QTranslator translator;
    QStringList dirs;
    const QString env = qEnvironmentVariable("HAGRA_TRANSLATIONS");
    if (!env.isEmpty()) dirs << env;
    dirs << QStringLiteral(HAGRA_TRANSLATIONS_DIR);
    for (const QString &d : dirs) {
        if (translator.load(locale, base, QStringLiteral("_"), d)) {
            app.installTranslator(&translator);
            qInfo("%s: translation loaded: %s (%s)", qPrintable(base), qPrintable(translator.language()), qPrintable(d));
            return;
        }
    }
    qInfo("%s: no translation for %s — Korean UI", qPrintable(base), qPrintable(locale.name()));
}

int main(int argc, char *argv[])
{
    HagraLayerShell::prepareEnvironment();
    // GPU가 없는 환경(QEMU TCG 등)에서는 세션 스크립트가 QT_QUICK_BACKEND=software 를 설정한다.
    QGuiApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("hagra-shell"));
    app.setApplicationVersion(QStringLiteral(HAGRA_VERSION));
    app.setOrganizationName(QStringLiteral("하그라"));
    app.setOrganizationDomain(QStringLiteral("hagra.local"));
    app.setDesktopFileName(QStringLiteral("org.hagra.shell"));
    app.setQuitOnLastWindowClosed(false);
    hagraLoadTranslation(app, QStringLiteral("hagra-shell"));

    QCommandLineParser parser;
    parser.setApplicationDescription(QStringLiteral("HAGRA desktop shell (panel, launcher, power menu)"));
    parser.addHelpOption();
    parser.addVersionOption();
    QCommandLineOption toggleLauncher(QStringLiteral("toggle-launcher"), QStringLiteral("Toggle the application launcher"));
    QCommandLineOption showLauncher(QStringLiteral("show-launcher"), QStringLiteral("Show the application launcher"));
    QCommandLineOption power(QStringLiteral("power"), QStringLiteral("Toggle the power menu"));
    QCommandLineOption quit(QStringLiteral("quit"), QStringLiteral("Ask the running shell to quit"));
    QCommandLineOption terminal(QStringLiteral("terminal"), QStringLiteral("Launch the default terminal"));
    QCommandLineOption appearance(QStringLiteral("appearance"), QStringLiteral("Open Settings → Appearance & Themes"));
    QCommandLineOption notificationsOpt(QStringLiteral("notifications"), QStringLiteral("Toggle the notification center"));
    QCommandLineOption calendarOpt(QStringLiteral("calendar"), QStringLiteral("Toggle the calendar popup"));
    QCommandLineOption audioOpt(QStringLiteral("audio"), QStringLiteral("Toggle the volume popup"));
    // --settings [PAGE]: 값이 있는 QCommandLineOption 은 값을 반드시 요구하므로(`--settings` 만 쓰면 "Missing value" 오류 — 바탕 화면
    // 메뉴·Super+I 가 이 형태다) 플래그로 두고 페이지 이름은 위치 인자로 받는다.
    QCommandLineOption settings(QStringLiteral("settings"), QStringLiteral("Open the Settings application (optional page name as the next argument)"));
    parser.addOptions({ toggleLauncher, showLauncher, power, quit, terminal, appearance, settings, notificationsOpt, calendarOpt, audioOpt });
    parser.addPositionalArgument(QStringLiteral("page"), QStringLiteral("Settings page for --settings"), QStringLiteral("[page]"));
    parser.process(app);

    QString command;
    if (parser.isSet(toggleLauncher)) command = QStringLiteral("toggle-launcher");
    else if (parser.isSet(showLauncher)) command = QStringLiteral("show-launcher");
    else if (parser.isSet(power)) command = QStringLiteral("power");
    else if (parser.isSet(quit)) command = QStringLiteral("quit");
    else if (parser.isSet(terminal)) command = QStringLiteral("terminal");
    else if (parser.isSet(appearance)) command = QStringLiteral("appearance");
    else if (parser.isSet(notificationsOpt)) command = QStringLiteral("notifications");
    else if (parser.isSet(calendarOpt)) command = QStringLiteral("calendar");
    else if (parser.isSet(audioOpt)) command = QStringLiteral("audio");
    else if (parser.isSet(settings)) {
        const QString page = parser.positionalArguments().value(0);
        command = page.isEmpty() ? QStringLiteral("settings") : QStringLiteral("settings:") + page;
    }

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
    LauncherState launcherState;
    launcherState.seedDefaults(apps.allIds());
    QObject::connect(&apps, &AppIndex::launched, &launcherState, &LauncherState::noteLaunch);
    ToplevelModel toplevels;
    NotificationServer notifications;
    notifications.registerOnBus();
    SystemStatus status;
    HagraTheme::ThemeManager themeManager;   // 저장된 테마 선택 복원 (~/.config/hagra/theme.conf); 외부 변경 감시

    HagraLayerShell::LayerWindow::registerQmlTypes();
    HagraTheme::ThemeManager::registerQmlTypes(&themeManager);
    qmlRegisterSingletonInstance("HagraShell", 1, 0, "Shell", &ipc);
    qmlRegisterSingletonInstance("HagraShell", 1, 0, "Power", &powerCtl);
    qmlRegisterSingletonInstance("HagraShell", 1, 0, "Apps", &apps);
    qmlRegisterSingletonInstance("HagraShell", 1, 0, "Toplevels", &toplevels);
    qmlRegisterSingletonInstance("HagraShell", 1, 0, "LauncherState", &launcherState);
    qmlRegisterSingletonInstance("HagraShell", 1, 0, "Notifications", &notifications);
    qmlRegisterSingletonInstance("HagraShell", 1, 0, "Status", &status);
    qmlRegisterType<ConfFile>("HagraShell", 1, 0, "ConfFile");

    QQmlApplicationEngine engine;
    engine.addImageProvider(QStringLiteral("appicon"), new AppIconProvider);   // image://appicon/<Icon=>
    engine.addImportPath(QStringLiteral(HAGRA_QML_INSTALL_DIR));
    for (const QString &p : qEnvironmentVariable("HAGRA_QML_IMPORT_PATH").split(QLatin1Char(':'), Qt::SkipEmptyParts))
        engine.addImportPath(p);
    engine.load(QUrl(QStringLiteral("qrc:/qml/Main.qml")));
    if (engine.rootObjects().isEmpty())
        return 1;
    HagraTheme::ThemeManager::bindEngine(&engine, &themeManager);   // HagraUI.Theme 에 현재 테마 토큰 적용 + 변경 시 재적용

    QObject::connect(&ipc, &ShellIpc::quitRequested, &app, [&app] {
        // 종료 순서: layer surface(역할 객체)를 먼저 정리하고 나서 wl_surface 가 파괴되게 창을 숨긴다 → "surface was destroyed before its role object" 방지
        for (QWindow *w : QGuiApplication::topLevelWindows()) {
            if (auto *lw = qobject_cast<HagraLayerShell::LayerWindow *>(w))
                lw->setVisible(false);   // LayerWindow::setVisible 은 비가상: layer surface 를 먼저 정리한다
            else
                w->setVisible(false);
        }
        QTimer::singleShot(0, &app, &QGuiApplication::quit);
    }, Qt::QueuedConnection);
    QObject::connect(&ipc, &ShellIpc::launchTerminal, &apps, [&apps] { apps.launchCommand(apps.terminalProgram()); });
    // 설정 앱: hagra-settings [--page NAME]. 설치되어 있지 않으면(개발 호스트) 셸 내장 모양 창으로 대체한다 (모양 페이지만).
    QObject::connect(&ipc, &ShellIpc::openSettings, &ipc, [&ipc, &apps](const QString &page) {
        const QString bin = qEnvironmentVariable("HAGRA_SETTINGS", QStringLiteral("hagra-settings"));
        const QString exe = bin.contains(QLatin1Char('/')) ? bin : QStandardPaths::findExecutable(bin);
        if (!exe.isEmpty()) {
            QStringList args;
            if (!page.isEmpty()) args << QStringLiteral("--page") << page;
            if (QProcess::startDetached(exe, args))
                return;
        }
        qWarning("hagra-settings not available; falling back to the built-in appearance window");
        emit ipc.showAppearance();
    });
    if (!command.isEmpty())
        ipc.dispatch(command);

    qInfo("hagra-shell %s ready", HAGRA_VERSION);
    return app.exec();
}
