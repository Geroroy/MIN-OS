// 하그라 셸 — 패널 표시기용 시스템 상태 (주기 폴링, 외부 데몬 없이 커널 인터페이스 우선):
//   네트워크: /proc/net/route 기본 경로 → 인터페이스 종류(/sys/class/net/<if>/wireless 유무) · 주소(QNetworkInterface) · Wi-Fi 신호(/proc/net/wireless)
//   배터리:   /sys/class/power_supply (없으면 표시기 숨김)
//   소리:     wpctl 또는 pactl 이 있을 때만 (없으면 표시기 숨김; 설정 앱이 이유를 설명)
// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once
#include <QObject>
#include <QString>

class QTimer;

class SystemStatus : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool online READ online NOTIFY changed)
    Q_PROPERTY(QString networkKind READ networkKind NOTIFY changed)      // "wifi" | "ethernet" | "none"
    Q_PROPERTY(QString networkIface READ networkIface NOTIFY changed)
    Q_PROPERTY(QString networkAddress READ networkAddress NOTIFY changed)
    Q_PROPERTY(int wifiSignal READ wifiSignal NOTIFY changed)             // 0..100, -1 = 알 수 없음
    Q_PROPERTY(bool batteryPresent READ batteryPresent NOTIFY changed)
    Q_PROPERTY(int batteryPercent READ batteryPercent NOTIFY changed)
    Q_PROPERTY(bool charging READ charging NOTIFY changed)
    Q_PROPERTY(bool audioAvailable READ audioAvailable NOTIFY changed)
    Q_PROPERTY(int volume READ volume NOTIFY changed)
    Q_PROPERTY(bool muted READ muted NOTIFY changed)
public:
    explicit SystemStatus(QObject *parent = nullptr);
    bool online() const { return m_online; }
    QString networkKind() const { return m_kind; }
    QString networkIface() const { return m_iface; }
    QString networkAddress() const { return m_address; }
    int wifiSignal() const { return m_signal; }
    bool batteryPresent() const { return m_batteryPresent; }
    int batteryPercent() const { return m_batteryPercent; }
    bool charging() const { return m_charging; }
    bool audioAvailable() const { return m_audio; }
    int volume() const { return m_volume; }
    bool muted() const { return m_muted; }

    Q_INVOKABLE void refresh();
    Q_INVOKABLE bool setVolume(int percent);
    Q_INVOKABLE bool setMuted(bool muted);

    static QString defaultRouteIface(const QString &procNetRoute);
    static int wifiSignalPercent(const QString &procNetWireless, const QString &iface);   // 링크 품질 → 0..100
Q_SIGNALS:
    void changed();
private:
    void pollNetwork();
    void pollBattery();
    void pollAudio();
    QTimer *m_timer = nullptr;
    bool m_online = false, m_batteryPresent = false, m_charging = false, m_audio = false, m_muted = false;
    QString m_kind = QStringLiteral("none"), m_iface, m_address, m_audioTool;
    int m_signal = -1, m_batteryPercent = -1, m_volume = 0, m_tick = 0;
};
