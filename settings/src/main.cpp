// hagra-settings — 하그라 설정 앱 진입점
//   hagra-settings [--page NAME]        창 열기 (이미 실행 중이면 그 창을 앞으로, 페이지 전환)
//   hagra-settings --apply              창 없이 저장된 설정을 현재 세션에 적용 (디스플레이·입력). 세션 autostart 가 호출
//   hagra-settings --render-session DIR 세션 설정 디렉터리(labwc -C)에 input.conf 를 반영한 rc.xml/environment 를 쓴다 (hagra-session 이 호출)
// SPDX-License-Identifier: GPL-3.0-or-later
#include <QCommandLineParser>
#include <QDir>
#include <QGuiApplication>
#include <QLocalServer>
#include <QLocalSocket>
#include <QLoggingCategory>
#include <QLocale>
#include <QTranslator>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QQuickWindow>
#include <QTextStream>

#include "hagratheme/thememanager.h"
#include "conffile.h"
#include "displaybackend.h"
#include "inputbackend.h"
#include "localebackend.h"
#include "networkbackend.h"
#include "notifybackend.h"
#include "powerbackend.h"
#include "proc.h"
#include "soundbackend.h"
#include "systeminfo.h"
#include "wallpapers.h"

Q_LOGGING_CATEGORY(lcSettings, "hagra.settings")

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

static QString socketPath()
{
    QString dir = qEnvironmentVariable("XDG_RUNTIME_DIR");
    if (dir.isEmpty()) dir = QStringLiteral("/tmp");
    return dir + QStringLiteral("/hagra-settings-") + qEnvironmentVariable("WAYLAND_DISPLAY", QStringLiteral("wayland-0")) + QStringLiteral(".sock");
}

int main(int argc, char *argv[])
{
    if (qEnvironmentVariableIsEmpty("QT_QPA_PLATFORM") && !qEnvironmentVariableIsEmpty("WAYLAND_DISPLAY")) qputenv("QT_QPA_PLATFORM", "wayland");
    qputenv("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1");   // 창 장식은 labwc(SSD)
    QGuiApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("hagra-settings"));
    app.setApplicationVersion(QStringLiteral(HAGRA_VERSION));
    app.setOrganizationName(QStringLiteral("하그라"));
    app.setDesktopFileName(QStringLiteral("org.hagra.settings"));
    hagraLoadTranslation(app, QStringLiteral("hagra-settings"));

    QCommandLineParser parser;
    parser.setApplicationDescription(QStringLiteral("HAGRA Settings"));
    parser.addHelpOption();
    parser.addVersionOption();
    QCommandLineOption pageOpt(QStringLiteral("page"), QStringLiteral("Open this page: appearance wallpaper display sound input locale network notifications power accessibility about"), QStringLiteral("name"));
    QCommandLineOption applyOpt(QStringLiteral("apply"), QStringLiteral("Apply saved display/input settings to the running session and exit"));
    QCommandLineOption renderOpt(QStringLiteral("render-session"), QStringLiteral("Render input settings into a labwc config directory and exit"), QStringLiteral("dir"));
    parser.addOptions({ pageOpt, applyOpt, renderOpt });
    parser.process(app);

    if (parser.isSet(renderOpt)) {
        QString err;
        const bool ok = InputBackend::renderInto(parser.value(renderOpt), qEnvironmentVariable("HAGRA_LABWC_SYSCONF", QStringLiteral("/etc/hagra/labwc")), InputBackend::load(), &err);
        if (!ok) QTextStream(stderr) << "hagra-settings: render-session failed: " << err << '\n';
        return ok ? 0 : 1;
    }
    if (parser.isSet(applyOpt)) {
        DisplayBackend display;
        const int n = display.applySaved();
        InputBackend input;
        const bool inputOk = input.applyToSession();
        qCInfo(lcSettings) << "applied saved settings: outputs" << n << "input" << inputOk;
        return 0;
    }

    // 단일 인스턴스: 이미 열려 있으면 페이지 이름만 보낸다
    const QString page = parser.value(pageOpt);
    {
        QLocalSocket probe;
        probe.connectToServer(socketPath());
        if (probe.waitForConnected(300)) {
            probe.write((page.isEmpty() ? QStringLiteral("raise") : QStringLiteral("page:") + page).toUtf8() + '\n');
            probe.waitForBytesWritten(300);
            return 0;
        }
        QLocalServer::removeServer(socketPath());
    }
    QLocalServer server;
    server.setSocketOptions(QLocalServer::UserAccessOption);
    server.listen(socketPath());

    QQuickStyle::setStyle(QStringLiteral("Basic"));
    HagraTheme::ThemeManager themeManager;
    HagraTheme::ThemeManager::registerQmlTypes(&themeManager);
    Proc proc;
    SystemInfo sysinfo;
    DisplayBackend display;
    SoundBackend sound;
    InputBackend input;
    LocaleBackend locale;
    NetworkBackend network;
    PowerBackend power;
    NotifyBackend notify;
    Wallpapers wallpapers;
    qmlRegisterSingletonInstance("HagraSettings", 1, 0, "Proc", &proc);
    qmlRegisterSingletonInstance("HagraSettings", 1, 0, "SystemInfo", &sysinfo);
    qmlRegisterSingletonInstance("HagraSettings", 1, 0, "Display", &display);
    qmlRegisterSingletonInstance("HagraSettings", 1, 0, "Sound", &sound);
    qmlRegisterSingletonInstance("HagraSettings", 1, 0, "Input", &input);
    qmlRegisterSingletonInstance("HagraSettings", 1, 0, "LocaleSettings", &locale);   // "Locale" 은 QtQml 내장 타입과 겹친다
    qmlRegisterSingletonInstance("HagraSettings", 1, 0, "Network", &network);
    qmlRegisterSingletonInstance("HagraSettings", 1, 0, "Power", &power);
    qmlRegisterSingletonInstance("HagraSettings", 1, 0, "Notify", &notify);
    qmlRegisterSingletonInstance("HagraSettings", 1, 0, "Wallpapers", &wallpapers);
    qmlRegisterType<ConfFile>("HagraSettings", 1, 0, "ConfFile");

    QQmlApplicationEngine engine;
    engine.addImportPath(QStringLiteral(HAGRA_QML_INSTALL_DIR));
    for (const QString &p : qEnvironmentVariable("HAGRA_QML_IMPORT_PATH").split(QLatin1Char(':'), Qt::SkipEmptyParts))
        engine.addImportPath(p);
    engine.rootContext()->setContextProperty(QStringLiteral("initialPage"), page);
    engine.load(QUrl(QStringLiteral("qrc:/qml/Main.qml")));
    if (engine.rootObjects().isEmpty())
        return 1;
    HagraTheme::ThemeManager::bindEngine(&engine, &themeManager);
    QObject *root = engine.rootObjects().first();

    QObject::connect(&server, &QLocalServer::newConnection, &server, [&server, root] {
        while (QLocalSocket *c = server.nextPendingConnection()) {
            QObject::connect(c, &QLocalSocket::readyRead, c, [c, root] {
                while (c->canReadLine()) {
                    const QString line = QString::fromUtf8(c->readLine()).trimmed();
                    QMetaObject::invokeMethod(root, "handleCommand", Q_ARG(QVariant, line));
                }
            });
            QObject::connect(c, &QLocalSocket::disconnected, c, &QObject::deleteLater);
        }
    });
    qCInfo(lcSettings) << "hagra-settings" << HAGRA_VERSION << "page" << page;
    const int rc = app.exec();
    server.close();
    QLocalServer::removeServer(socketPath());
    return rc;
}
