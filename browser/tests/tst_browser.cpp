// 보그라 도우미 단위 테스트 — 주소 입력 해석, 검색 엔진·자주 가는 곳 저장(임시 HOME), Accept-Language.
#include <QtTest>
#include <QTemporaryDir>
#include "browserhelper.h"

class TestBrowser : public QObject
{
    Q_OBJECT
    QTemporaryDir home;
private slots:
    void initTestCase()
    {
        QVERIFY(home.isValid());
        qputenv("HOME", home.path().toUtf8());
        qputenv("XDG_CONFIG_HOME", (home.path() + "/.config").toUtf8());
        qputenv("LANG", "ko_KR.UTF-8");
    }
    void fixup_data()
    {
        QTest::addColumn<QString>("input");
        QTest::addColumn<QString>("expected");
        const QString g = QStringLiteral("https://www.google.com/search?q=");
        QTest::newRow("empty") << "   " << "";
        QTest::newRow("domain") << "example.com" << "https://example.com";
        QTest::newRow("domain+path") << "naver.com/news?a=1" << "https://naver.com/news?a=1";
        QTest::newRow("scheme kept") << "http://example.com/x" << "http://example.com/x";
        QTest::newRow("trimmed") << "  https://a.kr  " << "https://a.kr";
        QTest::newRow("localhost port") << "localhost:8080/app" << "http://localhost:8080/app";
        QTest::newRow("ipv4") << "192.168.0.1" << "http://192.168.0.1";
        QTest::newRow("korean domain") << "한글.kr" << "https://한글.kr";
        QTest::newRow("about") << "about:blank" << "about:blank";
        QTest::newRow("view-source") << "view-source:https://a.com" << "view-source:https://a.com";
        QTest::newRow("words") << "날씨 서울" << g + "%EB%82%A0%EC%94%A8%20%EC%84%9C%EC%9A%B8";
        QTest::newRow("single word") << "하그라" << g + "%ED%95%98%EA%B7%B8%EB%9D%BC";
        QTest::newRow("number") << "3.14" << g + "3.14";
        QTest::newRow("unknown scheme") << "c++:templates" << g + "c%2B%2B%3Atemplates";
        QTest::newRow("http without slashes") << "http:문서" << g + "http%3A%EB%AC%B8%EC%84%9C";
        QTest::newRow("dot only") << "a..b" << g + "a..b";
        QTest::newRow("missing file") << "/no/such/file.html" << g + "%2Fno%2Fsuch%2Ffile.html";
    }
    void fixup()
    {
        QFETCH(QString, input);
        QFETCH(QString, expected);
        BrowserHelper b;
        QCOMPARE(b.fixup(input), expected);
    }
    void localFile()
    {
        BrowserHelper b;
        const QString path = home.path() + "/page.html";
        QFile f(path); QVERIFY(f.open(QIODevice::WriteOnly)); f.write("<title>x</title>"); f.close();
        QCOMPARE(b.fixup(path), QUrl::fromLocalFile(path).toString());
        QCOMPARE(b.fixup("~/page.html"), QUrl::fromLocalFile(path).toString());
    }
    void searchEnginePersists()
    {
        {
            BrowserHelper b;
            QCOMPARE(b.searchEngine(), QStringLiteral("google"));
            QSignalSpy spy(&b, &BrowserHelper::searchEngineChanged);
            b.setSearchEngine("naver");
            b.setSearchEngine("no-such-engine");   // 모르는 엔진은 무시
            QCOMPARE(spy.count(), 1);
            QCOMPARE(b.searchUrl("하그라 운영체제"), QStringLiteral("https://search.naver.com/search.naver?query=%ED%95%98%EA%B7%B8%EB%9D%BC%20%EC%9A%B4%EC%98%81%EC%B2%B4%EC%A0%9C"));
        }
        BrowserHelper again;
        QCOMPARE(again.searchEngine(), QStringLiteral("naver"));
        again.setSearchEngine("google");
    }
    void shortcuts()
    {
        QFile::remove(BrowserHelper::configPath());
        {
            BrowserHelper b;
            QCOMPARE(b.shortcuts().size(), 5);                 // 기본 목록
            QVERIFY(b.hasShortcut("https://www.naver.com"));   // 끝의 / 는 무시
            b.addShortcut("하그라", "https://github.com/Geroroy/MIN-OS");
            b.addShortcut("중복", "https://github.com/Geroroy/MIN-OS/");
            QCOMPARE(b.shortcuts().size(), 6);
            b.toggleShortcut("", "https://www.daum.net/");      // 있으면 뺀다
            QCOMPARE(b.shortcuts().size(), 5);
        }
        BrowserHelper again;
        const QVariantList list = again.shortcuts();
        QCOMPARE(list.size(), 5);
        QCOMPARE(list.last().toMap().value("title").toString(), QStringLiteral("하그라"));
        QVERIFY(!again.hasShortcut("https://www.daum.net/"));
        for (const QVariant &v : list) again.removeShortcut(v.toMap().value("url").toString());
        BrowserHelper empty;                                    // 모두 지우면 기본 목록으로 돌아가지 않는다
        QVERIFY(empty.shortcuts().isEmpty());
        empty.addShortcut("", "https://www.example.org/");
        QCOMPARE(empty.shortcuts().first().toMap().value("title").toString(), QStringLiteral("example.org"));   // 제목이 없으면 호스트
    }
    void acceptLanguage()
    {
        BrowserHelper b;
        const QString al = b.acceptLanguage();
        QVERIFY2(al.startsWith("ko"), qPrintable(al));
        QVERIFY2(al.contains("en;q="), qPrintable(al));
    }
};

QTEST_GUILESS_MAIN(TestBrowser)
#include "tst_browser.moc"
