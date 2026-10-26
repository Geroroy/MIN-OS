// hagra-settings — 소리: PipeWire(wireplumber `wpctl`) 또는 PulseAudio(`pactl`) 가 있을 때만 동작. 둘 다 없으면 이유를 보여 준다.
// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once
#include <QObject>
#include <QVariantList>

class SoundBackend : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool available READ available NOTIFY refreshed)
    Q_PROPERTY(QString reason READ reason NOTIFY refreshed)
    Q_PROPERTY(QString tool READ tool NOTIFY refreshed)
    Q_PROPERTY(int volume READ volume NOTIFY refreshed)          // 0..150 (%)
    Q_PROPERTY(bool muted READ muted NOTIFY refreshed)
    Q_PROPERTY(int micVolume READ micVolume NOTIFY refreshed)
    Q_PROPERTY(bool micMuted READ micMuted NOTIFY refreshed)
    Q_PROPERTY(QVariantList sinks READ sinks NOTIFY refreshed)
public:
    explicit SoundBackend(QObject *parent = nullptr);
    bool available() const { return m_available; }
    QString reason() const { return m_reason; }
    QString tool() const { return m_tool; }
    int volume() const { return m_volume; }
    bool muted() const { return m_muted; }
    int micVolume() const { return m_micVolume; }
    bool micMuted() const { return m_micMuted; }
    QVariantList sinks() const { return m_sinks; }

    Q_INVOKABLE void refresh();
    Q_INVOKABLE bool setVolume(int percent);
    Q_INVOKABLE bool setMuted(bool muted);
    Q_INVOKABLE bool setMicMuted(bool muted);
    Q_INVOKABLE bool setDefaultSink(const QString &id);

    static bool parseWpctlVolume(const QString &out, int *percent, bool *muted);   // "Volume: 0.45 [MUTED]"
    static QVariantList parsePactlSinks(const QString &out);                       // pactl list short sinks
Q_SIGNALS:
    void refreshed();
private:
    bool m_available = false;
    QString m_reason, m_tool;
    int m_volume = 0, m_micVolume = 0;
    bool m_muted = false, m_micMuted = false;
    QVariantList m_sinks;
};
