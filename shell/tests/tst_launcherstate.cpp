// 실행 메뉴 상태(즐겨찾기·최근) 단위 테스트 — 임시 HOME 에서 저장·복원·기본값·상한을 검사한다.
#include <QtTest>
#include <QTemporaryDir>
#include "launcherstate.h"

class TestLauncherState : public QObject
{
    Q_OBJECT
    QTemporaryDir home;
private slots:
    void initTestCase()
    {
        QVERIFY(home.isValid());
        qputenv("HOME", home.path().toUtf8());
        qputenv("XDG_CONFIG_HOME", (home.path() + "/.config").toUtf8());
        qputenv("XDG_STATE_HOME", (home.path() + "/.local/state").toUtf8());
    }
    void defaultsAreSeededFromInstalledApps()
    {
        LauncherState s;
        QVERIFY(s.favorites().isEmpty());
        s.seedDefaults({ "org.codeberg.dnkl.foot", "vim", "org.hagra.settings", "org.hagra.browser" });
        QCOMPARE(s.favorites(), (QStringList{ "org.hagra.browser", "org.hagra.settings", "org.codeberg.dnkl.foot" }));
        QVERIFY(!QFileInfo::exists(LauncherState::configPath()));   // 기본값은 저장하지 않는다
    }
    void favoritesPersistAndReorder()
    {
        {
            LauncherState s;
            s.addFavorite("a"); s.addFavorite("b"); s.addFavorite("a");
            QCOMPARE(s.favorites(), (QStringList{ "a", "b" }));
            s.moveFavorite("b", -1);
            QCOMPARE(s.favorites(), (QStringList{ "b", "a" }));
            s.toggleFavorite("a");
            QCOMPARE(s.favorites(), (QStringList{ "b" }));
        }
        LauncherState again;
        QCOMPARE(again.favorites(), (QStringList{ "b" }));
        again.seedDefaults({ "org.codeberg.dnkl.foot" });   // 설정이 있으면 기본값으로 덮지 않는다
        QCOMPARE(again.favorites(), (QStringList{ "b" }));
    }
    void recentIsBoundedAndMostRecentFirst()
    {
        LauncherState s;
        for (int i = 0; i < 12; ++i) s.noteLaunch(QStringLiteral("app%1").arg(i));
        QCOMPARE(s.recent().size(), s.maxRecent());
        QCOMPARE(s.recent().first(), QStringLiteral("app11"));
        s.noteLaunch("app5");
        QCOMPARE(s.recent().first(), QStringLiteral("app5"));
        QCOMPARE(s.recent().count("app5"), 1);
        s.noteLaunch("/usr/bin/foot");   // 임의 명령은 기록하지 않는다
        QCOMPARE(s.recent().first(), QStringLiteral("app5"));
        LauncherState again;
        QCOMPARE(again.recent(), s.recent());
        again.clearRecent();
        QVERIFY(again.recent().isEmpty());
    }
};

QTEST_GUILESS_MAIN(TestLauncherState)
#include "tst_launcherstate.moc"
