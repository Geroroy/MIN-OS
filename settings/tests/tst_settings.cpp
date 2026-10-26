// hagra-settings 백엔드 단위 테스트 — 외부 도구 출력 파서와 labwc 설정 렌더링 (도구 없이 실행 가능).
#include <QtTest>
#include <QTemporaryDir>
#include "displaybackend.h"
#include "soundbackend.h"
#include "inputbackend.h"
#include "networkbackend.h"
#include "localebackend.h"
#include "powerbackend.h"
#include "systeminfo.h"

class TestSettings : public QObject
{
    Q_OBJECT
private slots:
    void wlrRandrParse()
    {
        const QString text = QStringLiteral(
            "HEADLESS-1 \"Headless output 1\"\n  Make: (null)\n  Model: (null)\n  Serial: (null)\n  Enabled: yes\n  Modes:\n    1280x720 px (current)\n"
            "  Position: 0,0\n  Transform: normal\n  Scale: 1.000000\n  Adaptive Sync: disabled\n"
            "eDP-1 \"Chimei Innolux Corporation 0x14D3 (eDP-1)\"\n  Make: Chimei Innolux Corporation\n  Model: 0x14D3\n  Enabled: yes\n  Modes:\n"
            "    1920x1080 px, 60.001999 Hz (preferred, current)\n    1680x1050 px, 59.954002 Hz\n  Position: 1280,0\n  Transform: 90\n  Scale: 1.500000\n");
        const auto outs = DisplayBackend::parse(text);
        QCOMPARE(outs.size(), 2);
        QCOMPARE(outs[0].name, QStringLiteral("HEADLESS-1"));
        QCOMPARE(outs[0].description, QStringLiteral("Headless output 1"));
        QVERIFY(outs[0].make.isEmpty());
        QCOMPARE(outs[0].modes.size(), 1);
        QVERIFY(outs[0].modes[0].current);
        QCOMPARE(outs[0].currentMode(), QStringLiteral("1280x720"));
        QCOMPARE(outs[1].modes.size(), 2);
        QVERIFY(outs[1].modes[0].preferred && outs[1].modes[0].current);
        QCOMPARE(outs[1].modes[0].width, 1920);
        QCOMPARE(outs[1].x, 1280);
        QCOMPARE(outs[1].transform, QStringLiteral("90"));
        QCOMPARE(outs[1].scale, 1.5);
        QCOMPARE(outs[1].make, QStringLiteral("Chimei Innolux Corporation"));
    }
    void wpctlParse()
    {
        int p = 0; bool m = false;
        QVERIFY(SoundBackend::parseWpctlVolume("Volume: 0.45", &p, &m)); QCOMPARE(p, 45); QVERIFY(!m);
        QVERIFY(SoundBackend::parseWpctlVolume("Volume: 1.00 [MUTED]\n", &p, &m)); QCOMPARE(p, 100); QVERIFY(m);
        QVERIFY(!SoundBackend::parseWpctlVolume("error", &p, &m));
        const auto sinks = SoundBackend::parsePactlSinks("0\talsa_output.pci-0000_00_1f.3.analog-stereo\tPipeWire\ts32le 2ch 48000Hz\tSUSPENDED\n");
        QCOMPARE(sinks.size(), 1);
        QCOMPARE(sinks[0].toMap().value("id").toString(), QStringLiteral("alsa_output.pci-0000_00_1f.3.analog-stereo"));
    }
    void rcRender()
    {
        const QString rc = QStringLiteral("<?xml version=\"1.0\"?>\n<labwc_config>\n  <keyboard>\n    <default />\n  </keyboard>\n  <libinput>\n    <device category=\"default\">\n      <naturalScroll>no</naturalScroll>\n      <tap>yes</tap>\n    </device>\n  </libinput>\n</labwc_config>\n");
        QVariantMap v{ { "keyboard/repeatRate", 40 }, { "keyboard/repeatDelay", 300 }, { "pointer/naturalScroll", true }, { "pointer/tap", false }, { "pointer/speed", 0.5 }, { "pointer/leftHanded", false } };
        QString err;
        const QString out = InputBackend::renderRc(rc, v, &err);
        QVERIFY2(!out.isEmpty(), qPrintable(err));
        QVERIFY(out.contains("<repeatRate>40</repeatRate>"));
        QVERIFY(out.contains("<repeatDelay>300</repeatDelay>"));
        QVERIFY(out.contains("<naturalScroll>yes</naturalScroll>"));
        QVERIFY(out.contains("<tap>no</tap>"));
        QVERIFY(out.contains("<pointerSpeed>0.50</pointerSpeed>"));
        QVERIFY(out.contains("<default/>") || out.contains("<default />"));   // 기존 내용 보존
        QVERIFY(InputBackend::renderRc("<nope/>", v, &err).isEmpty());
        const QString env = InputBackend::renderEnvironment("XDG_CURRENT_DESKTOP=HAGRA\nXKB_DEFAULT_LAYOUT=us\n", { { "keyboard/layout", "kr,us" }, { "keyboard/options", "grp:alt_shift_toggle" } });
        QCOMPARE(env.count("XKB_DEFAULT_LAYOUT="), 1);
        QVERIFY(env.contains("XKB_DEFAULT_LAYOUT=kr,us\n"));
        QVERIFY(env.contains("XKB_DEFAULT_OPTIONS=grp:alt_shift_toggle"));
        QVERIFY(env.startsWith("XDG_CURRENT_DESKTOP=HAGRA\n"));
    }
    void renderIntoRespectsUserOverride()
    {
        QTemporaryDir sys, conf, home;
        qputenv("XDG_CONFIG_HOME", (home.path() + "/.config").toUtf8());
        auto write = [](const QString &p, const QByteArray &b) { QDir().mkpath(QFileInfo(p).absolutePath()); QFile f(p); QVERIFY(f.open(QIODevice::WriteOnly)); f.write(b); };
        write(sys.path() + "/rc.xml", "<labwc_config><libinput/></labwc_config>");
        write(sys.path() + "/environment", "A=1\n");
        QString err;
        QVERIFY2(InputBackend::renderInto(conf.path(), sys.path(), { { "pointer/tap", true }, { "keyboard/layout", "kr" } }, &err), qPrintable(err));
        QFile rc(conf.path() + "/rc.xml"); QVERIFY(rc.open(QIODevice::ReadOnly)); QVERIFY(rc.readAll().contains("<tap>yes</tap>"));
        QFile env(conf.path() + "/environment"); QVERIFY(env.open(QIODevice::ReadOnly)); QVERIFY(env.readAll().contains("XKB_DEFAULT_LAYOUT=kr"));
        // 사용자가 rc.xml 을 직접 두면 건드리지 않는다
        write(home.path() + "/.config/hagra/labwc/rc.xml", "<labwc_config/>");
        QFile::remove(conf.path() + "/rc.xml");
        QVERIFY(InputBackend::renderInto(conf.path(), sys.path(), { { "pointer/tap", true } }, &err));
        QVERIFY(!QFileInfo::exists(conf.path() + "/rc.xml"));
    }
    void networkParsers()
    {
        QCOMPARE(NetworkBackend::parseDefaultRoute("Iface\tDestination\tGateway\tFlags\nlo\t0000007F\t00000000\t0001\neth0\t00000000\t0101A8C0\t0003\n"), QStringLiteral("eth0"));
        QVERIFY(NetworkBackend::parseDefaultRoute("Iface\tDestination\n").isEmpty());
        const auto w = NetworkBackend::parseNmcliWifi("Home\\:Net:78:WPA2:*\nCafe:40:--: \n");
        QCOMPARE(w.size(), 2);
        QCOMPARE(w[0].toMap().value("ssid").toString(), QStringLiteral("Home:Net"));
        QVERIFY(w[0].toMap().value("inUse").toBool());
        QCOMPARE(w[1].toMap().value("signal").toInt(), 40);
        QVERIFY(!w[1].toMap().value("inUse").toBool());
    }
    void localeList()
    {
        const auto l = LocaleBackend::parseLocaleList("C\nC.utf8\nPOSIX\nen_US.utf8\nko_KR.utf8\nko_KR\n");
        QCOMPARE(l.size(), 3);
        QCOMPARE(l[0].toMap().value("code").toString(), QStringLiteral("ko_KR.UTF-8"));
        QCOMPARE(l[1].toMap().value("code").toString(), QStringLiteral("en_US.UTF-8"));
        QCOMPARE(l[2].toMap().value("code").toString(), QStringLiteral("C.UTF-8"));
    }
    void batteries()
    {
        QTemporaryDir d;
        auto write = [](const QString &p, const QByteArray &b) { QDir().mkpath(QFileInfo(p).absolutePath()); QFile f(p); QVERIFY(f.open(QIODevice::WriteOnly)); f.write(b); };
        write(d.path() + "/BAT0/type", "Battery\n"); write(d.path() + "/BAT0/capacity", "73\n"); write(d.path() + "/BAT0/status", "Discharging\n");
        write(d.path() + "/BAT0/energy_full", "40000000\n"); write(d.path() + "/BAT0/energy_full_design", "50000000\n");
        write(d.path() + "/AC/type", "Mains\n");
        const auto b = PowerBackend::readBatteries(d.path());
        QCOMPARE(b.size(), 1);
        QCOMPARE(b[0].toMap().value("capacity").toInt(), 73);
        QCOMPARE(b[0].toMap().value("health").toInt(), 80);
        QCOMPARE(b[0].toMap().value("status").toString(), QStringLiteral("Discharging"));
    }
    void keyValueFile()
    {
        QTemporaryDir d;
        QFile f(d.path() + "/rel"); QVERIFY(f.open(QIODevice::WriteOnly)); f.write("HAGRA_NAME=\"HAGRA\"\n# c\nHAGRA_VERSION=0.1\n"); f.close();
        const auto m = SystemInfo::readKeyValueFile(f.fileName());
        QCOMPARE(m.value("HAGRA_NAME").toString(), QStringLiteral("HAGRA"));
        QCOMPARE(m.value("HAGRA_VERSION").toString(), QStringLiteral("0.1"));
        QCOMPARE(SystemInfo::humanSize(1536), QStringLiteral("2 KiB"));
        QCOMPARE(SystemInfo::humanSize(3LL * 1024 * 1024 * 1024), QStringLiteral("3.0 GiB"));
    }
};

QTEST_MAIN(TestSettings)
#include "tst_settings.moc"
