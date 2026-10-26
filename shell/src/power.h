// 하그라 셸 — 전원 제어 (logind D-Bus)
// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once
#include <QObject>

class Power : public QObject
{
    Q_OBJECT
public:
    explicit Power(QObject *parent = nullptr);

    Q_INVOKABLE void powerOff();
    Q_INVOKABLE void reboot();
    Q_INVOKABLE void suspend();
    /// 세션 종료: 컴포지터(labwc)에 종료 요청 → greetd가 세션을 정리한다.
    Q_INVOKABLE void logout();

Q_SIGNALS:
    void failed(const QString &action, const QString &reason);

private:
    bool callLogind(const QString &method);
};
