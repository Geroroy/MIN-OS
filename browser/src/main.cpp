// hagra-browser — 하그라 브라우저 진입점 (Qt WebEngine + HagraUI)
//   hagra-browser [주소|파일 ...]   창 열기. 이미 실행 중이면 그 창에 새 탭으로 연다 (단일 인스턴스 소켓 "open:<주소>")
// SPDX-License-Identifier: GPL-3.0-or-later
#include <QCommandLineParser>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QGuiApplication>
#include <QLocalServer>
#include <QLocalSocket>
#include <QLocale>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QTranslator>
#include <QtWebEngineQuick/qtwebenginequickglobal.h>
#include <unistd.h>

#include "hagratheme/thememanager.h"
#include "browserhelper.h"

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
    return dir + QStringLiteral("/hagra-browser-") + qEnvironmentVariable("WAYLAND_DISPLAY", QStringLiteral("wayland-0")) + QStringLiteral(".sock");
}

// Chromium 플래그: 소프트웨어 렌더링 세션(hagra-session 이 QT_QUICK_BACKEND=software 를 설정)에서는 GPU 를 끄고,
// 모바일 프로필(Termux QEMU)에서는 렌더러 프로세스 수를 줄여 메모리를 아낀다. 사용자가 준 플래그 뒤에 덧붙인다.
static void setupChromiumFlags()
{
    QStringList flags = qEnvironmentVariable("QTWEBENGINE_CHROMIUM_FLAGS").split(QLatin1Char(' '), Qt::SkipEmptyParts);
    auto add = [&flags](const QString &f) { if (!flags.contains(f)) flags << f; };
    const bool software = qEnvironmentVariable("QT_QUICK_BACKEND") == QLatin1String("software")
                       || QDir(QStringLiteral("/dev/dri")).entryList({ QStringLiteral("renderD*") }, QDir::System).isEmpty();
    if (software) add(QStringLiteral("--disable-gpu"));
    QFile profile(QStringLiteral("/etc/hagra/profile"));
    if (profile.open(QIODevice::ReadOnly) && profile.readAll().contains("HAGRA_PROFILE=mobile"))
        add(QStringLiteral("--renderer-process-limit=2"));
    qputenv("QTWEBENGINE_CHROMIUM_FLAGS", flags.join(QLatin1Char(' ')).toUtf8());
    // Chromium 샌드박스는 root 로 실행할 수 없다 (개발 이미지의 root 셸·헤드리스 검사). 일반 사용자는 샌드박스를 유지한다.
    if (geteuid() == 0 && qEnvironmentVariableIsEmpty("QTWEBENGINE_DISABLE_SANDBOX")) {
        qputenv("QTWEBENGINE_DISABLE_SANDBOX", "1");
        qWarning("hagra-browser: running as root — Chromium sandbox disabled");
    }
}

// 명령줄 인자 → 열 주소 (존재하는 파일은 file://, 나머지는 주소 표시줄과 같은 규칙)
static QStringList urlsFromArgs(const QStringList &args, const BrowserHelper &helper)
{
    QStringList out;
    for (const QString &a : args) {
        const QFileInfo fi(a);
        if (!a.contains(QStringLiteral("://")) && fi.exists()) out << QUrl::fromLocalFile(fi.absoluteFilePath()).toString();
        else if (const QString u = helper.fixup(a); !u.isEmpty()) out << u;
    }
    return out;
}

int main(int argc, char *argv[])
{
    if (qEnvironmentVariableIsEmpty("QT_QPA_PLATFORM") && !qEnvironmentVariableIsEmpty("WAYLAND_DISPLAY")) qputenv("QT_QPA_PLATFORM", "wayland");
    qputenv("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1");   // 창 장식은 labwc(SSD)
    setupChromiumFlags();
    QtWebEngineQuick::initialize();   // QGuiApplication 보다 먼저 (OpenGL 컨텍스트 공유)
    QGuiApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("hagra-browser"));
    app.setApplicationVersion(QStringLiteral(HAGRA_VERSION));
    app.setOrganizationName(QStringLiteral("hagra"));
    app.setDesktopFileName(QStringLiteral("org.hagra.browser"));
    hagraLoadTranslation(app, QStringLiteral("hagra-browser"));

    QCommandLineParser parser;
    parser.setApplicationDescription(QStringLiteral("HAGRA Browser"));
    parser.addHelpOption();
    parser.addVersionOption();
    parser.addPositionalArgument(QStringLiteral("url"), QStringLiteral("Addresses or files to open in new tabs"), QStringLiteral("[url...]"));
    parser.process(app);

    BrowserHelper helper;
    const QStringList urls = urlsFromArgs(parser.positionalArguments(), helper);

    // 단일 인스턴스: 이미 열려 있으면 주소만 보낸다
    {
        QLocalSocket probe;
        probe.connectToServer(socketPath());
        if (probe.waitForConnected(300)) {
            QByteArray msg;
            for (const QString &u : urls) msg += "open:" + u.toUtf8() + '\n';
            if (urls.isEmpty()) msg = "raise\n";
            probe.write(msg);
            probe.waitForBytesWritten(300);
            return 0;
        }
        QLocalServer::removeServer(socketPath());
    }
    QLocalServer server;
    server.setSocketOptions(QLocalServer::UserAccessOption);
    server.listen(socketPath());

    QQuickStyle::setStyle(QStringLiteral("Basic"));   // 웹 페이지의 기본 대화 상자(알림·파일 선택)도 Basic 스타일
    HagraTheme::ThemeManager themeManager;
    HagraTheme::ThemeManager::registerQmlTypes(&themeManager);
    qmlRegisterSingletonInstance("HagraBrowser", 1, 0, "Browser", &helper);

    QQmlApplicationEngine engine;
    engine.addImportPath(QStringLiteral(HAGRA_QML_INSTALL_DIR));
    for (const QString &p : qEnvironmentVariable("HAGRA_QML_IMPORT_PATH").split(QLatin1Char(':'), Qt::SkipEmptyParts))
        engine.addImportPath(p);
    engine.rootContext()->setContextProperty(QStringLiteral("initialUrls"), urls);
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
    qCInfo(lcBrowser) << "hagra-browser" << HAGRA_VERSION << "flags" << qEnvironmentVariable("QTWEBENGINE_CHROMIUM_FLAGS");
    const int rc = app.exec();
    server.close();
    QLocalServer::removeServer(socketPath());
    return rc;
}
