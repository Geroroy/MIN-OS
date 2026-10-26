// SPDX-License-Identifier: GPL-3.0-or-later
#include "displaybackend.h"
#include "proc.h"
#include <QDir>
#include <QFileInfo>
#include <QLoggingCategory>
#include <QRegularExpression>
#include <QSettings>
#include <QStandardPaths>

Q_LOGGING_CATEGORY(lcDisplay, "hagra.settings.display")

QString OutputMode::label() const
{
    return refresh > 0 ? QStringLiteral("%1x%2@%3").arg(width).arg(height).arg(QString::number(refresh, 'f', 3)) : QStringLiteral("%1x%2").arg(width).arg(height);
}

QString OutputInfo::currentMode() const
{
    for (const OutputMode &m : modes) if (m.current) return m.label();
    return {};
}

DisplayBackend::DisplayBackend(QObject *parent) : QObject(parent) { refresh(); }

QString DisplayBackend::configPath()
{
    return QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation) + QStringLiteral("/hagra/display.conf");
}

// wlr-randr 텍스트 출력 파서 (0.4.x; --json 이 없는 판도 지원):
//   NAME "description"
//     Make: x / Model: y / Serial: z
//     Enabled: yes
//     Modes:
//       1920x1080 px, 60.000000 Hz (preferred, current)
//     Position: 0,0 / Transform: normal / Scale: 1.000000
QList<OutputInfo> DisplayBackend::parse(const QString &text)
{
    QList<OutputInfo> list;
    static const QRegularExpression head(QStringLiteral("^(\\S+)(?:\\s+\"(.*)\")?\\s*$"));
    static const QRegularExpression mode(QStringLiteral("^\\s+(\\d+)x(\\d+) px(?:, ([0-9.]+) Hz)?(?: \\(([^)]*)\\))?"));
    static const QRegularExpression kv(QStringLiteral("^\\s+([A-Za-z ]+): (.*)$"));
    for (const QString &line : text.split(QLatin1Char('\n'))) {
        if (line.trimmed().isEmpty()) continue;
        if (!line.startsWith(QLatin1Char(' '))) {
            const auto m = head.match(line);
            if (!m.hasMatch()) continue;
            OutputInfo o; o.name = m.captured(1); o.description = m.captured(2);
            list.append(o);
            continue;
        }
        if (list.isEmpty()) continue;
        OutputInfo &o = list.last();
        const auto mm = mode.match(line);
        if (mm.hasMatch()) {
            OutputMode md; md.width = mm.captured(1).toInt(); md.height = mm.captured(2).toInt();
            md.refresh = mm.captured(3).isEmpty() ? 0 : mm.captured(3).toDouble();
            md.current = mm.captured(4).contains(QLatin1String("current"));
            md.preferred = mm.captured(4).contains(QLatin1String("preferred"));
            o.modes.append(md);
            continue;
        }
        const auto k = kv.match(line);
        if (!k.hasMatch()) continue;
        const QString key = k.captured(1).trimmed(), val = k.captured(2).trimmed();
        if (key == QLatin1String("Make")) o.make = val == QLatin1String("(null)") ? QString() : val;
        else if (key == QLatin1String("Model")) o.model = val == QLatin1String("(null)") ? QString() : val;
        else if (key == QLatin1String("Enabled")) o.enabled = val == QLatin1String("yes");
        else if (key == QLatin1String("Position")) { const auto p = val.split(QLatin1Char(',')); if (p.size() == 2) { o.x = p[0].toInt(); o.y = p[1].toInt(); } }
        else if (key == QLatin1String("Transform")) o.transform = val;
        else if (key == QLatin1String("Scale")) o.scale = val.toDouble();
    }
    return list;
}

void DisplayBackend::refresh()
{
    m_outputs.clear();
    if (qEnvironmentVariableIsEmpty("WAYLAND_DISPLAY")) { m_available = false; m_reason = QStringLiteral("Wayland 세션 밖에서 실행 중입니다 (WAYLAND_DISPLAY 없음)."); emit refreshed(); return; }
    if (!Proc::has(QStringLiteral("wlr-randr"))) { m_available = false; m_reason = QStringLiteral("wlr-randr 가 설치되어 있지 않습니다. 디스플레이 설정은 wlr-output-management 클라이언트가 필요합니다."); emit refreshed(); return; }
    const ProcResult r = Proc::run(QStringLiteral("wlr-randr"));
    if (!r.ok()) { m_available = false; m_reason = QStringLiteral("wlr-randr 실행 실패: ") + (r.err.isEmpty() ? QString::number(r.code) : r.err.trimmed()); emit refreshed(); return; }
    m_outputs = parse(r.out);
    m_available = !m_outputs.isEmpty();
    m_reason = m_available ? QString() : QStringLiteral("컴포지터가 출력 정보를 주지 않았습니다.");
    emit refreshed();
}

QVariantList DisplayBackend::outputsForQml() const
{
    QVariantList l;
    for (const OutputInfo &o : m_outputs) {
        QVariantMap m;
        m[QStringLiteral("name")] = o.name;
        m[QStringLiteral("description")] = o.description.isEmpty() ? o.name : o.description;
        m[QStringLiteral("make")] = o.make; m[QStringLiteral("model")] = o.model;
        m[QStringLiteral("enabled")] = o.enabled;
        m[QStringLiteral("x")] = o.x; m[QStringLiteral("y")] = o.y;
        m[QStringLiteral("transform")] = o.transform;
        m[QStringLiteral("scale")] = o.scale;
        m[QStringLiteral("currentMode")] = o.currentMode();
        QVariantList modes;
        for (const OutputMode &md : o.modes) {
            modes << QVariantMap{ { QStringLiteral("label"), md.label() }, { QStringLiteral("width"), md.width }, { QStringLiteral("height"), md.height },
                                  { QStringLiteral("refresh"), md.refresh }, { QStringLiteral("current"), md.current }, { QStringLiteral("preferred"), md.preferred } };
        }
        m[QStringLiteral("modes")] = modes;
        m[QStringLiteral("saved")] = hasSaved(o.name);
        l << m;
    }
    return l;
}

static QStringList argsFor(const QString &output, const QString &mode, double scale, const QString &transform, bool enabled)
{
    QStringList a{ QStringLiteral("--output"), output };
    if (!enabled) { a << QStringLiteral("--off"); return a; }
    a << QStringLiteral("--on");
    if (!mode.isEmpty()) a << QStringLiteral("--mode") << mode;
    if (scale > 0) a << QStringLiteral("--scale") << QString::number(scale, 'g', 4);
    if (!transform.isEmpty()) a << QStringLiteral("--transform") << transform;
    return a;
}

bool DisplayBackend::apply(const QString &output, const QString &mode, double scale, const QString &transform, bool enabled, bool persist)
{
    const ProcResult r = Proc::run(QStringLiteral("wlr-randr"), argsFor(output, mode, scale, transform, enabled), 6000);
    if (!r.ok()) {
        const QString msg = r.err.trimmed().isEmpty() ? QStringLiteral("wlr-randr 종료 코드 %1").arg(r.code) : r.err.trimmed();
        qCWarning(lcDisplay) << "apply failed" << output << msg;
        emit error(msg);
        refresh();
        return false;
    }
    if (persist) {
        QDir().mkpath(QFileInfo(configPath()).absolutePath());
        QSettings s(configPath(), QSettings::IniFormat);
        s.beginGroup(QStringLiteral("output.") + output);
        s.setValue(QStringLiteral("enabled"), enabled);
        if (!mode.isEmpty()) s.setValue(QStringLiteral("mode"), mode);
        if (scale > 0) s.setValue(QStringLiteral("scale"), scale);
        if (!transform.isEmpty()) s.setValue(QStringLiteral("transform"), transform);
        s.endGroup();
        s.sync();
    }
    refresh();
    return true;
}

bool DisplayBackend::setPosition(const QString &output, int x, int y, bool persist)
{
    const ProcResult r = Proc::run(QStringLiteral("wlr-randr"), { QStringLiteral("--output"), output, QStringLiteral("--pos"), QStringLiteral("%1,%2").arg(x).arg(y) }, 6000);
    if (!r.ok()) { emit error(r.err.trimmed()); refresh(); return false; }
    if (persist) {
        QSettings s(configPath(), QSettings::IniFormat);
        s.setValue(QStringLiteral("output.%1/pos").arg(output), QStringLiteral("%1,%2").arg(x).arg(y));
        s.sync();
    }
    refresh();
    return true;
}

void DisplayBackend::forget(const QString &output)
{
    QSettings s(configPath(), QSettings::IniFormat);
    s.remove(QStringLiteral("output.") + output);
    s.sync();
    emit refreshed();
}

bool DisplayBackend::hasSaved(const QString &output) const
{
    QSettings s(configPath(), QSettings::IniFormat);
    return s.childGroups().contains(QStringLiteral("output.") + output);
}

int DisplayBackend::applySaved()
{
    if (!QFileInfo::exists(configPath()) || !Proc::has(QStringLiteral("wlr-randr"))) return 0;
    QSettings s(configPath(), QSettings::IniFormat);
    int n = 0;
    QStringList present;
    for (const OutputInfo &o : m_outputs) present << o.name;
    for (const QString &g : s.childGroups()) {
        if (!g.startsWith(QLatin1String("output."))) continue;
        const QString name = g.mid(7);
        if (!present.contains(name)) { qCInfo(lcDisplay) << "saved output not connected:" << name; continue; }
        s.beginGroup(g);
        QStringList a = argsFor(name, s.value(QStringLiteral("mode")).toString(), s.value(QStringLiteral("scale"), 0.0).toDouble(),
                                s.value(QStringLiteral("transform")).toString(), s.value(QStringLiteral("enabled"), true).toBool());
        const QString pos = s.value(QStringLiteral("pos")).toString();
        if (!pos.isEmpty()) a << QStringLiteral("--pos") << pos;
        s.endGroup();
        const ProcResult r = Proc::run(QStringLiteral("wlr-randr"), a, 6000);
        if (r.ok()) ++n; else qCWarning(lcDisplay) << "restore failed for" << name << r.err;
    }
    refresh();
    return n;
}
