// SPDX-License-Identifier: GPL-3.0-or-later
#include "inputbackend.h"
#include "proc.h"
#include <QDir>
#include <QDomDocument>
#include <QFile>
#include <QFileInfo>
#include <QLoggingCategory>
#include <QRegularExpression>
#include <QSettings>
#include <QStandardPaths>

Q_LOGGING_CATEGORY(lcInput, "hagra.settings.input")

static const struct { const char *key; const char *def; } kDefaults[] = {
    { "keyboard/layout", "us" }, { "keyboard/variant", "" }, { "keyboard/options", "" },
    { "keyboard/repeatRate", "25" }, { "keyboard/repeatDelay", "600" },
    { "pointer/tap", "true" }, { "pointer/naturalScroll", "false" }, { "pointer/leftHanded", "false" }, { "pointer/speed", "0" },
    { "pointer/middleEmulation", "false" },
};

InputBackend::InputBackend(QObject *parent) : QObject(parent) { reload(); }

QString InputBackend::configPath()
{
    return QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation) + QStringLiteral("/hagra/input.conf");
}

QVariantMap InputBackend::load()
{
    QSettings s(configPath(), QSettings::IniFormat);
    QVariantMap m;
    for (const auto &d : kDefaults) m[QString::fromLatin1(d.key)] = s.value(QString::fromLatin1(d.key), QString::fromLatin1(d.def));
    return m;
}

void InputBackend::reload() { m_values = load(); emit changed(); }

void InputBackend::set(const QString &key, const QVariant &value)
{
    QDir().mkpath(QFileInfo(configPath()).absolutePath());
    QSettings s(configPath(), QSettings::IniFormat);
    s.setValue(key, value);
    s.sync();
    reload();
    applyToSession();
}

void InputBackend::resetAll()
{
    QFile::remove(configPath());
    reload();
    applyToSession();
}

QVariantList InputBackend::layouts() const
{
    QVariantList l;
    QFile f(QStringLiteral("/usr/share/X11/xkb/rules/evdev.lst"));
    if (!f.open(QIODevice::ReadOnly | QIODevice::Text)) {
        l << QVariantMap{ { QStringLiteral("code"), QStringLiteral("us") }, { QStringLiteral("name"), QStringLiteral("English (US)") } }
          << QVariantMap{ { QStringLiteral("code"), QStringLiteral("kr") }, { QStringLiteral("name"), QStringLiteral("Korean") } };
        return l;
    }
    bool in = false;
    static const QRegularExpression re(QStringLiteral("^\\s+(\\S+)\\s+(.*)$"));
    while (!f.atEnd()) {
        const QString line = QString::fromUtf8(f.readLine());
        if (line.startsWith(QLatin1String("! "))) { in = line.startsWith(QLatin1String("! layout")); continue; }
        if (!in) continue;
        const auto m = re.match(line);
        if (m.hasMatch()) l << QVariantMap{ { QStringLiteral("code"), m.captured(1) }, { QStringLiteral("name"), m.captured(2).trimmed() } };
    }
    // 한국어·영어를 앞으로
    std::stable_sort(l.begin(), l.end(), [](const QVariant &a, const QVariant &b) {
        auto rank = [](const QString &c) { return c == QLatin1String("kr") ? 0 : c == QLatin1String("us") ? 1 : 2; };
        return rank(a.toMap().value(QStringLiteral("code")).toString()) < rank(b.toMap().value(QStringLiteral("code")).toString());
    });
    return l;
}

bool InputBackend::sessionApplySupported() const
{
    return !qEnvironmentVariableIsEmpty("WAYLAND_DISPLAY") && Proc::has(QStringLiteral("labwc")) && !qEnvironmentVariableIsEmpty("HAGRA_LABWC_CONF");
}

static void setChildText(QDomDocument &doc, QDomElement parent, const QString &tag, const QString &text)
{
    QDomElement e = parent.firstChildElement(tag);
    if (e.isNull()) { e = doc.createElement(tag); parent.appendChild(e); }
    while (!e.firstChild().isNull()) e.removeChild(e.firstChild());
    e.appendChild(doc.createTextNode(text));
}

QString InputBackend::renderRc(const QString &rcXml, const QVariantMap &v, QString *error)
{
    QDomDocument doc;
    QString err; int line = 0;
    if (!doc.setContent(rcXml, &err, &line)) { if (error) *error = QStringLiteral("rc.xml parse error line %1: %2").arg(line).arg(err); return {}; }
    QDomElement root = doc.documentElement();
    if (root.tagName() != QLatin1String("labwc_config")) { if (error) *error = QStringLiteral("not a labwc_config"); return {}; }
    auto yesno = [](const QVariant &b) { return b.toBool() || b.toString() == QLatin1String("true") ? QStringLiteral("yes") : QStringLiteral("no"); };
    QDomElement kb = root.firstChildElement(QStringLiteral("keyboard"));
    if (kb.isNull()) { kb = doc.createElement(QStringLiteral("keyboard")); root.appendChild(kb); }
    setChildText(doc, kb, QStringLiteral("repeatRate"), v.value(QStringLiteral("keyboard/repeatRate"), 25).toString());
    setChildText(doc, kb, QStringLiteral("repeatDelay"), v.value(QStringLiteral("keyboard/repeatDelay"), 600).toString());
    QDomElement li = root.firstChildElement(QStringLiteral("libinput"));
    if (li.isNull()) { li = doc.createElement(QStringLiteral("libinput")); root.appendChild(li); }
    QDomElement dev;
    for (QDomElement d = li.firstChildElement(QStringLiteral("device")); !d.isNull(); d = d.nextSiblingElement(QStringLiteral("device")))
        if (d.attribute(QStringLiteral("category"), QStringLiteral("default")) == QLatin1String("default")) { dev = d; break; }
    if (dev.isNull()) { dev = doc.createElement(QStringLiteral("device")); dev.setAttribute(QStringLiteral("category"), QStringLiteral("default")); li.appendChild(dev); }
    setChildText(doc, dev, QStringLiteral("naturalScroll"), yesno(v.value(QStringLiteral("pointer/naturalScroll"))));
    setChildText(doc, dev, QStringLiteral("tap"), yesno(v.value(QStringLiteral("pointer/tap"), true)));
    setChildText(doc, dev, QStringLiteral("leftHanded"), yesno(v.value(QStringLiteral("pointer/leftHanded"))));
    setChildText(doc, dev, QStringLiteral("middleEmulation"), yesno(v.value(QStringLiteral("pointer/middleEmulation"))));
    setChildText(doc, dev, QStringLiteral("pointerSpeed"), QString::number(qBound(-1.0, v.value(QStringLiteral("pointer/speed")).toDouble(), 1.0), 'f', 2));
    return doc.toString(2);
}

QString InputBackend::renderEnvironment(const QString &envText, const QVariantMap &v)
{
    QStringList out;
    for (const QString &line : envText.split(QLatin1Char('\n')))
        if (!line.startsWith(QLatin1String("XKB_DEFAULT_LAYOUT=")) && !line.startsWith(QLatin1String("XKB_DEFAULT_VARIANT=")) && !line.startsWith(QLatin1String("XKB_DEFAULT_OPTIONS=")))
            out << line;
    while (!out.isEmpty() && out.last().trimmed().isEmpty()) out.removeLast();
    out << QStringLiteral("# hagra-settings: 키보드 배치 (input.conf)");
    out << QStringLiteral("XKB_DEFAULT_LAYOUT=") + v.value(QStringLiteral("keyboard/layout"), QStringLiteral("us")).toString();
    const QString variant = v.value(QStringLiteral("keyboard/variant")).toString();
    if (!variant.isEmpty()) out << QStringLiteral("XKB_DEFAULT_VARIANT=") + variant;
    const QString options = v.value(QStringLiteral("keyboard/options")).toString();
    if (!options.isEmpty()) out << QStringLiteral("XKB_DEFAULT_OPTIONS=") + options;
    return out.join(QLatin1Char('\n')) + QLatin1Char('\n');
}

bool InputBackend::renderInto(const QString &confDir, const QString &sysDir, const QVariantMap &v, QString *error)
{
    auto readAll = [](const QString &p) { QFile f(p); return f.open(QIODevice::ReadOnly) ? QString::fromUtf8(f.readAll()) : QString(); };
    auto writeAll = [](const QString &p, const QString &s) {
        QFile::remove(p);   // 심볼릭 링크(시스템 파일)를 실제 파일로 바꾼다
        QFile f(p); if (!f.open(QIODevice::WriteOnly | QIODevice::Truncate)) return false; f.write(s.toUtf8()); return true;
    };
    const QString userDir = QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation) + QStringLiteral("/hagra/labwc");
    bool ok = true;
    // 사용자가 rc.xml 을 직접 두면 손대지 않는다 (사용자 재정의 > 설정 앱)
    if (!QFileInfo::exists(userDir + QStringLiteral("/rc.xml"))) {
        QString src = readAll(confDir + QStringLiteral("/rc.xml"));
        if (src.isEmpty()) src = readAll(sysDir + QStringLiteral("/rc.xml"));
        const QString rc = renderRc(src, v, error);
        if (rc.isEmpty()) return false;
        ok = writeAll(confDir + QStringLiteral("/rc.xml"), rc) && ok;
    }
    if (!QFileInfo::exists(userDir + QStringLiteral("/environment"))) {
        QString src = readAll(sysDir + QStringLiteral("/environment"));
        if (src.isEmpty()) src = readAll(confDir + QStringLiteral("/environment"));
        ok = writeAll(confDir + QStringLiteral("/environment"), renderEnvironment(src, v)) && ok;
    }
    return ok;
}

bool InputBackend::applyToSession()
{
    const QString conf = qEnvironmentVariable("HAGRA_LABWC_CONF");
    if (conf.isEmpty() || !QDir(conf).exists()) { qCInfo(lcInput) << "no session config dir (HAGRA_LABWC_CONF); input settings apply at next login"; return false; }
    QString err;
    if (!renderInto(conf, qEnvironmentVariable("HAGRA_LABWC_SYSCONF", QStringLiteral("/etc/hagra/labwc")), m_values, &err)) { qCWarning(lcInput) << err; return false; }
    return Proc::reconfigureLabwc();
}
