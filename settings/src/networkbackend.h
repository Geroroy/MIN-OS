// hagra-settings — 네트워크: NetworkManager(nmcli) 가 있으면 연결 목록·Wi-Fi 검색·연결을, 없으면 QNetworkInterface/proc 기반 읽기 전용 상태를 보여 준다.
// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once
#include <QObject>
#include <QVariantList>

class NetworkBackend : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool managerAvailable READ managerAvailable NOTIFY refreshed)
    Q_PROPERTY(QString reason READ reason NOTIFY refreshed)
    Q_PROPERTY(QVariantList interfaces READ interfaces NOTIFY refreshed)
    Q_PROPERTY(QVariantList wifi READ wifi NOTIFY refreshed)
    Q_PROPERTY(QString defaultRoute READ defaultRoute NOTIFY refreshed)
    Q_PROPERTY(bool online READ online NOTIFY refreshed)
public:
    explicit NetworkBackend(QObject *parent = nullptr);
    bool managerAvailable() const { return m_nm; }
    QString reason() const { return m_reason; }
    QVariantList interfaces() const { return m_ifaces; }
    QVariantList wifi() const { return m_wifi; }
    QString defaultRoute() const { return m_route; }
    bool online() const { return !m_route.isEmpty(); }
    Q_INVOKABLE void refresh();
    Q_INVOKABLE void scanWifi();
    Q_INVOKABLE QVariantMap connectWifi(const QString &ssid, const QString &password);
    Q_INVOKABLE QVariantMap disconnect(const QString &iface);
    static QString parseDefaultRoute(const QString &procNetRoute);   // /proc/net/route → 인터페이스 이름
    static QVariantList parseNmcliWifi(const QString &out);         // nmcli -t -f SSID,SIGNAL,SECURITY,IN-USE dev wifi
Q_SIGNALS:
    void refreshed();
private:
    bool m_nm = false;
    QString m_reason, m_route;
    QVariantList m_ifaces, m_wifi;
};
