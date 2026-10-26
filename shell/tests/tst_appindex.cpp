// 하그라 셸 단위 테스트 — .desktop 파싱 및 Exec 분해
#include <QtTest>
#include <QTemporaryDir>
#include "appindex.h"

class TestAppIndex : public QObject
{
    Q_OBJECT
private slots:
    void execToArgs_data()
    {
        QTest::addColumn<QString>("exec");
        QTest::addColumn<QStringList>("expected");
        QTest::newRow("plain")      << "foot" << QStringList{ "foot" };
        QTest::newRow("fieldcodes") << "firefox %u" << QStringList{ "firefox" };
        QTest::newRow("multi")      << "gimp-2.10 %U" << QStringList{ "gimp-2.10" };
        QTest::newRow("quoted")     << "\"/opt/My App/bin/app\" --flag %F" << QStringList{ "/opt/My App/bin/app", "--flag" };
        QTest::newRow("percent")    << "sh -c \"echo 100%%\"" << QStringList{ "sh", "-c", "echo 100%" };
        QTest::newRow("spaces")     << "  env   FOO=bar   prog  " << QStringList{ "env", "FOO=bar", "prog" };
    }
    void execToArgs()
    {
        QFETCH(QString, exec);
        QFETCH(QStringList, expected);
        QCOMPARE(AppIndex::execToArgs(exec), expected);
    }

    void parseDesktopFile()
    {
        QTemporaryDir dir;
        QVERIFY(dir.isValid());
        const QString path = dir.filePath("org.example.Foo.desktop");
        QFile f(path);
        QVERIFY(f.open(QIODevice::WriteOnly));
        f.write("[Desktop Entry]\nType=Application\nName=Foo\nName[ko]=푸\nComment=Does foo\n"
                "Exec=foo --bar %f\nIcon=foo\nTerminal=true\nKeywords=a;b;\n[Desktop Action New]\nName=New\nExec=foo --new\n");
        f.close();

        auto e = AppIndex::parseDesktopFile(path, { "ko_KR", "ko" });
        QVERIFY(e.has_value());
        QCOMPARE(e->name, QString::fromUtf8("푸"));
        QCOMPARE(e->comment, QStringLiteral("Does foo"));
        QCOMPARE(e->exec, QStringLiteral("foo --bar %f"));
        QVERIFY(e->terminal);
        QCOMPARE(e->keywords, (QStringList{ "a", "b" }));
        QVERIFY(!e->noDisplay);

        auto en = AppIndex::parseDesktopFile(path, {});
        QCOMPARE(en->name, QStringLiteral("Foo"));
    }

    void parseRejectsNonApplications()
    {
        QTemporaryDir dir;
        const QString path = dir.filePath("link.desktop");
        QFile f(path);
        QVERIFY(f.open(QIODevice::WriteOnly));
        f.write("[Desktop Entry]\nType=Link\nName=Web\nURL=https://example.org\n");
        f.close();
        QVERIFY(!AppIndex::parseDesktopFile(path, {}).has_value());
    }

    void scanHonoursPrecedenceAndNoDisplay()
    {
        QTemporaryDir high, low;
        auto write = [](const QString &p, const QByteArray &body) {
            QFile f(p); QVERIFY(f.open(QIODevice::WriteOnly)); f.write(body);
        };
        write(high.filePath("a.desktop"), "[Desktop Entry]\nName=A high\nExec=a\n");
        write(low.filePath("a.desktop"), "[Desktop Entry]\nName=A low\nExec=a\n");
        write(low.filePath("b.desktop"), "[Desktop Entry]\nName=B\nExec=b\nNoDisplay=true\n");
        write(low.filePath("c.desktop"), "[Desktop Entry]\nName=C\nExec=c\n");
        const auto list = AppIndex::scan({ high.path(), low.path() }, "HAGRA");
        QCOMPARE(list.size(), 2);
        QCOMPARE(list[0].name, QStringLiteral("A high"));
        QCOMPARE(list[1].name, QStringLiteral("C"));
    }

    void filterScoring()
    {
        AppEntry e; e.name = "Terminal"; e.comment = "Command line"; e.exec = "foot";
        int s = 0;
        QVERIFY(AppIndex::matchesFilter(e, "term", &s)); QCOMPARE(s, 100);
        QVERIFY(AppIndex::matchesFilter(e, "minal", &s)); QCOMPARE(s, 80);
        QVERIFY(AppIndex::matchesFilter(e, "command", &s)); QCOMPARE(s, 30);
        QVERIFY(AppIndex::matchesFilter(e, "foo", &s)); QCOMPARE(s, 40);
        QVERIFY(!AppIndex::matchesFilter(e, "zzz", &s));
    }
};

QTEST_GUILESS_MAIN(TestAppIndex)
#include "tst_appindex.moc"
