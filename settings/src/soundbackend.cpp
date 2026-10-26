// SPDX-License-Identifier: GPL-3.0-or-later
#include "soundbackend.h"
#include "proc.h"
#include <QRegularExpression>

SoundBackend::SoundBackend(QObject *parent) : QObject(parent) { refresh(); }

bool SoundBackend::parseWpctlVolume(const QString &out, int *percent, bool *muted)
{
    static const QRegularExpression re(QStringLiteral("Volume:\\s*([0-9.]+)(\\s*\\[MUTED\\])?"));
    const auto m = re.match(out);
    if (!m.hasMatch()) return false;
    if (percent) *percent = qRound(m.captured(1).toDouble() * 100);
    if (muted) *muted = !m.captured(2).isEmpty();
    return true;
}

QVariantList SoundBackend::parsePactlSinks(const QString &out)
{
    QVariantList l;
    for (const QString &line : out.split(QLatin1Char('\n'), Qt::SkipEmptyParts)) {
        const QStringList f = line.split(QLatin1Char('\t'));
        if (f.size() < 2) continue;
        l << QVariantMap{ { QStringLiteral("id"), f[1] }, { QStringLiteral("name"), f[1] }, { QStringLiteral("state"), f.value(4) } };
    }
    return l;
}

void SoundBackend::refresh()
{
    m_sinks.clear();
    if (Proc::has(QStringLiteral("wpctl"))) {
        m_tool = QStringLiteral("wpctl");
        const ProcResult v = Proc::run(QStringLiteral("wpctl"), { QStringLiteral("get-volume"), QStringLiteral("@DEFAULT_AUDIO_SINK@") });
        if (v.ok() && parseWpctlVolume(v.out, &m_volume, &m_muted)) {
            m_available = true; m_reason.clear();
            const ProcResult mic = Proc::run(QStringLiteral("wpctl"), { QStringLiteral("get-volume"), QStringLiteral("@DEFAULT_AUDIO_SOURCE@") });
            if (mic.ok()) parseWpctlVolume(mic.out, &m_micVolume, &m_micMuted);
            if (Proc::has(QStringLiteral("pactl"))) {
                const ProcResult s = Proc::run(QStringLiteral("pactl"), { QStringLiteral("list"), QStringLiteral("short"), QStringLiteral("sinks") });
                if (s.ok()) m_sinks = parsePactlSinks(s.out);
            }
        } else {
            m_available = false;
            m_reason = tr("wpctl 는 있지만 PipeWire 세션에 연결하지 못했습니다 (pipewire/wireplumber 사용자 서비스가 실행 중인지 확인). ") + v.err.trimmed();
        }
    } else if (Proc::has(QStringLiteral("pactl"))) {
        m_tool = QStringLiteral("pactl");
        const ProcResult v = Proc::run(QStringLiteral("pactl"), { QStringLiteral("get-sink-volume"), QStringLiteral("@DEFAULT_SINK@") });
        static const QRegularExpression pct(QStringLiteral("(\\d+)%"));
        const auto m = pct.match(v.out);
        if (v.ok() && m.hasMatch()) {
            m_available = true; m_reason.clear();
            m_volume = m.captured(1).toInt();
            const ProcResult mu = Proc::run(QStringLiteral("pactl"), { QStringLiteral("get-sink-mute"), QStringLiteral("@DEFAULT_SINK@") });
            m_muted = mu.out.contains(QLatin1String("yes"));
            const ProcResult s = Proc::run(QStringLiteral("pactl"), { QStringLiteral("list"), QStringLiteral("short"), QStringLiteral("sinks") });
            if (s.ok()) m_sinks = parsePactlSinks(s.out);
        } else {
            m_available = false; m_reason = tr("pactl 가 오디오 서버에 연결하지 못했습니다. ") + v.err.trimmed();
        }
    } else {
        m_available = false; m_tool.clear();
        m_reason = tr("오디오 서버 제어 도구가 없습니다. 이 이미지에는 PipeWire(wireplumber) 가 포함되어 있지 않아 볼륨·장치 설정을 제공할 수 없습니다. 설치: pipewire pipewire-pulse wireplumber (명령 wpctl).");
    }
    emit refreshed();
}

bool SoundBackend::setVolume(int percent)
{
    if (!m_available) return false;
    percent = qBound(0, percent, 150);
    ProcResult r;
    if (m_tool == QLatin1String("wpctl"))
        r = Proc::run(QStringLiteral("wpctl"), { QStringLiteral("set-volume"), QStringLiteral("-l"), QStringLiteral("1.5"), QStringLiteral("@DEFAULT_AUDIO_SINK@"), QStringLiteral("%1%").arg(percent) });
    else
        r = Proc::run(QStringLiteral("pactl"), { QStringLiteral("set-sink-volume"), QStringLiteral("@DEFAULT_SINK@"), QStringLiteral("%1%").arg(percent) });
    refresh();
    return r.ok();
}

bool SoundBackend::setMuted(bool muted)
{
    if (!m_available) return false;
    ProcResult r;
    if (m_tool == QLatin1String("wpctl"))
        r = Proc::run(QStringLiteral("wpctl"), { QStringLiteral("set-mute"), QStringLiteral("@DEFAULT_AUDIO_SINK@"), muted ? QStringLiteral("1") : QStringLiteral("0") });
    else
        r = Proc::run(QStringLiteral("pactl"), { QStringLiteral("set-sink-mute"), QStringLiteral("@DEFAULT_SINK@"), muted ? QStringLiteral("1") : QStringLiteral("0") });
    refresh();
    return r.ok();
}

bool SoundBackend::setMicMuted(bool muted)
{
    if (!m_available) return false;
    ProcResult r;
    if (m_tool == QLatin1String("wpctl"))
        r = Proc::run(QStringLiteral("wpctl"), { QStringLiteral("set-mute"), QStringLiteral("@DEFAULT_AUDIO_SOURCE@"), muted ? QStringLiteral("1") : QStringLiteral("0") });
    else
        r = Proc::run(QStringLiteral("pactl"), { QStringLiteral("set-source-mute"), QStringLiteral("@DEFAULT_SOURCE@"), muted ? QStringLiteral("1") : QStringLiteral("0") });
    refresh();
    return r.ok();
}

bool SoundBackend::setDefaultSink(const QString &id)
{
    if (!m_available || !Proc::has(QStringLiteral("pactl"))) return false;
    const ProcResult r = Proc::run(QStringLiteral("pactl"), { QStringLiteral("set-default-sink"), id });
    refresh();
    return r.ok();
}
