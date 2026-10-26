// hagra-settings — 전원: logind(org.freedesktop.login1) 로 종료·재시작·절전 가능 여부와 실행, 배터리는 /sys/class/power_supply.
//   유휴 동작(화면 끄기·자동 절전)은 swayidle 이 있을 때만 설정 가능 (~/.config/hagra/power.conf → 세션 autostart 가 읽음).
// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once
#include <QObject>
#include <QVariantList>
#include <QVariantMap>

class PowerBackend : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantMap logind READ logind NOTIFY refreshed)          // canPowerOff/canReboot/canSuspend/canHibernate ("yes"/"no"/"na"/"challenge")
    Q_PROPERTY(QVariantList batteries READ batteries NOTIFY refreshed)
    Q_PROPERTY(bool onBattery READ onBattery NOTIFY refreshed)
    Q_PROPERTY(bool idleToolAvailable READ idleToolAvailable CONSTANT)
    Q_PROPERTY(QString idleReason READ idleReason CONSTANT)
public:
    explicit PowerBackend(QObject *parent = nullptr);
    QVariantMap logind() const { return m_logind; }
    QVariantList batteries() const { return m_batteries; }
    bool onBattery() const { return m_onBattery; }
    bool idleToolAvailable() const;
    QString idleReason() const;
    Q_INVOKABLE void refresh();
    Q_INVOKABLE bool action(const QString &name);   // PowerOff | Reboot | Suspend | Hibernate
    static QVariantList readBatteries(const QString &sysDir);
Q_SIGNALS:
    void refreshed();
    void failed(const QString &message);
private:
    QVariantMap m_logind;
    QVariantList m_batteries;
    bool m_onBattery = false;
};
