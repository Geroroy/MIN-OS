// hagra-settings — 알림: 세션의 org.freedesktop.Notifications 서버(하그라 셸 내장) 상태, 테스트 알림 보내기, 방해 금지(notifications.conf) 설정.
// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once
#include <QObject>
#include <QVariantMap>

class NotifyBackend : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantMap server READ server NOTIFY refreshed)   // running, name, vendor, version
public:
    explicit NotifyBackend(QObject *parent = nullptr);
    QVariantMap server() const { return m_server; }
    Q_INVOKABLE void refresh();
    Q_INVOKABLE bool sendTest(const QString &summary, const QString &body);
Q_SIGNALS:
    void refreshed();
private:
    QVariantMap m_server;
};
