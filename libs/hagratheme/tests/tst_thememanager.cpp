// ThemeManager 단위 테스트 — 레지스트리, 선택 저장/복원, 기본 복귀, 왕복, 배경 선택.
// HAGRA_THEME_PATH 는 CMake 가 build/themes 로 넣는다. HOME/XDG 는 임시 디렉터리로 바꿔 사용자 설정을 건드리지 않는다.
#include <QtTest>
#include <QTemporaryDir>
#include <QSettings>
#include "hagratheme/thememanager.h"

using HagraTheme::ThemeManager;

class TestThemeManager : public QObject
{
    Q_OBJECT
    QTemporaryDir home;
private slots:
    void initTestCase()
    {
        QVERIFY(home.isValid());
        qputenv("HOME", home.path().toUtf8());
        qputenv("XDG_CONFIG_HOME", (home.path() + "/.config").toUtf8());
        qputenv("XDG_DATA_HOME", (home.path() + "/.local/share").toUtf8());
        qputenv("XDG_STATE_HOME", (home.path() + "/.local/state").toUtf8());
        qputenv("HAGRA_THEME_NO_SESSION_RELOAD", "1");
        qunsetenv("HAGRA_THEME");
        qunsetenv("WAYLAND_DISPLAY");
        QVERIFY2(!qEnvironmentVariableIsEmpty("HAGRA_THEME_PATH"), "HAGRA_THEME_PATH must point at build/themes");
    }

    void registry()
    {
        ThemeManager m;
        QStringList ids;
        for (const auto &t : m.themes()) ids << t.id;
        QVERIFY2(ids.contains("hagra-dancheong-light"), qPrintable(ids.join(",")));
        QVERIFY2(ids.contains("hagra-dancheong-deep"), qPrintable(ids.join(",")));
        QCOMPARE(m.defaultId(), QString("hagra-dancheong-light"));
        QCOMPARE(m.currentId(), QString("hagra-dancheong-light"));   // 저장된 선택이 없으면 기본
        QCOMPARE(m.theme("hagra-dancheong-deep").displayName, QString("깊은 단청"));
        QVERIFY(QFileInfo::exists(m.theme("hagra-dancheong-deep").wallpaper));
        QVERIFY(QFileInfo::exists(m.theme("hagra-dancheong-deep").labwcThemerc));
    }

    void tokensShape()
    {
        ThemeManager m;
        const QVariantMap t = m.tokensFor(m.theme("hagra-dancheong-deep"));
        QCOMPARE(t.value("themeId").toString(), QString("hagra-dancheong-deep"));
        const QVariantMap c = t.value("color").toMap();
        QCOMPARE(c.value("panel").toString().toUpper(), QString("#183C35"));
        QCOMPARE(c.value("surface").toString().toUpper(), QString("#F2EADB"));
        QCOMPARE(c.value("panelText").toString().toUpper(), QString("#F2EADB"));
        QVERIFY(t.value("assets").toMap().contains("lotus-band"));
        QVERIFY(t.value("assets").toMap().value("lotus-band").toString().startsWith("file://"));
        QCOMPARE(t.value("size").toMap().value("panelHeight").toInt(), 52);
        const QVariantMap light = m.tokensFor(m.theme("hagra-dancheong-light")).value("color").toMap();
        QCOMPARE(light.value("panel").toString().toUpper(), QString("#FAF6EA"));
    }

    void applyPersistRestore()
    {
        {
            ThemeManager m;
            QSignalSpy spy(&m, &ThemeManager::changed);
            QVERIFY(m.apply("hagra-dancheong-deep"));
            QCOMPARE(m.currentId(), QString("hagra-dancheong-deep"));
            QCOMPARE(spy.count(), 1);
            QSettings s(ThemeManager::configFilePath(), QSettings::IniFormat);
            QCOMPARE(s.value("appearance/theme").toString(), QString("hagra-dancheong-deep"));
            // 관리 상태 파일
            QFile cur(ThemeManager::stateDir() + "/current");
            QVERIFY(cur.open(QIODevice::ReadOnly));
            QCOMPARE(QString::fromUtf8(cur.readAll()).trimmed(), QString("hagra-dancheong-deep"));
            QFile rc(ThemeManager::stateDir() + "/themerc-override");
            QVERIFY(rc.open(QIODevice::ReadOnly));
            QVERIFY(rc.readAll().contains("window.active.title.bg.color: #28574A"));
            QFile wp(ThemeManager::stateDir() + "/wallpaper");
            QVERIFY(wp.open(QIODevice::ReadOnly));
            QVERIFY(QString::fromUtf8(wp.readAll()).contains("hagra-dancheong-deep/wallpaper.png"));
        }
        ThemeManager again;   // 새 프로세스를 흉내: 저장된 선택 복원
        QCOMPARE(again.currentId(), QString("hagra-dancheong-deep"));
        QCOMPARE(again.currentName(), QString("깊은 단청"));
    }

    void roundTripBackToDefault()
    {
        ThemeManager m;
        QVERIFY(m.apply("hagra-dancheong-light"));
        QCOMPARE(m.currentId(), QString("hagra-dancheong-light"));
        ThemeManager again;
        QCOMPARE(again.currentId(), QString("hagra-dancheong-light"));
        QFile rc(ThemeManager::stateDir() + "/themerc-override");
        QVERIFY(rc.open(QIODevice::ReadOnly));
        QVERIFY(rc.readAll().contains("window.active.title.bg.color: #D2E2D5"));
    }

    void unknownIdFallsBack()
    {
        ThemeManager m;
        QVERIFY(m.apply("hagra-dancheong-deep"));
        QVERIFY(!m.apply("no-such-theme"));
        QCOMPARE(m.currentId(), QString("hagra-dancheong-light"));
        ThemeManager again;
        QCOMPARE(again.currentId(), QString("hagra-dancheong-light"));
    }

    void savedUnknownIdFallsBack()
    {
        {
            QSettings s(ThemeManager::configFilePath(), QSettings::IniFormat);
            s.setValue("appearance/theme", "vanished-theme");
        }
        ThemeManager m;
        QCOMPARE(m.currentId(), QString("hagra-dancheong-light"));
    }

    void envOverrideNotPersisted()
    {
        qputenv("HAGRA_THEME", "hagra-dancheong-deep");
        ThemeManager m;
        QCOMPARE(m.currentId(), QString("hagra-dancheong-deep"));
        qunsetenv("HAGRA_THEME");
        ThemeManager again;
        QCOMPARE(again.currentId(), QString("hagra-dancheong-light"));
    }

    void wallpaperChoice()
    {
        ThemeManager m;
        QVERIFY(m.apply("hagra-dancheong-deep"));
        QVERIFY(m.effectiveWallpaper().endsWith("hagra-dancheong-deep/wallpaper.png"));
        // 사용자 배경 (존재하는 파일)
        const QString user = home.path() + "/my.png";
        QFile f(user); QVERIFY(f.open(QIODevice::WriteOnly)); f.write("x"); f.close();
        m.setUserWallpaper(user);
        QVERIFY(!m.useThemeWallpaper());
        QCOMPARE(m.effectiveWallpaper(), user);
        ThemeManager again;
        QCOMPARE(again.effectiveWallpaper(), user);   // 테마와 별도로 유지
        again.setUseThemeWallpaper(true);
        QVERIFY(again.effectiveWallpaper().endsWith("hagra-dancheong-deep/wallpaper.png"));
        // 사용자 배경 파일이 사라지면 테마 기본으로
        again.setUseThemeWallpaper(false);
        QFile::remove(user);
        QVERIFY(again.effectiveWallpaper().endsWith("hagra-dancheong-deep/wallpaper.png"));
        QVERIFY(again.apply("hagra-dancheong-light"));
    }

    void otherSettingsUntouched()
    {
        {
            QSettings s(ThemeManager::configFilePath(), QSettings::IniFormat);
            s.setValue("sound/login", "pungkyung");
            s.setValue("panel/position", "bottom");
        }
        ThemeManager m;
        QVERIFY(m.apply("hagra-dancheong-deep"));
        QSettings s(ThemeManager::configFilePath(), QSettings::IniFormat);
        QCOMPARE(s.value("sound/login").toString(), QString("pungkyung"));
        QCOMPARE(s.value("panel/position").toString(), QString("bottom"));
        QVERIFY(m.apply("hagra-dancheong-light"));
    }

    void externalChangeIsFollowed()
    {
        ThemeManager m;
        QCOMPARE(m.currentId(), QString("hagra-dancheong-light"));
        QSignalSpy spy(&m, &ThemeManager::changed);
        {
            ThemeManager other;   // 다른 프로세스(설정 앱·CLI) 흉내
            QVERIFY(other.apply("hagra-dancheong-deep"));
        }
        QTRY_COMPARE_WITH_TIMEOUT(spy.count(), 1, 3000);
        QCOMPARE(m.currentId(), QString("hagra-dancheong-deep"));
        QVERIFY(m.apply("hagra-dancheong-light"));
    }
};

QTEST_GUILESS_MAIN(TestThemeManager)
#include "tst_thememanager.moc"
