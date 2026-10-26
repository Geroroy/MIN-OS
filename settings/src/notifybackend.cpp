// SPDX-License-Identifier: GPL-3.0-or-later
#include "notifybackend.h"
#include <QDBusConnection>
#include <QDBusConnectionInterface>
#include <QDBusInterface>
#include <QDBusReply>

NotifyBackend::NotifyBackend(QObject *parent) : QObject(parent) { refresh(); }

void NotifyBackend::refresh()
{
    QVariantMap m;
    QDBusConnection bus = QDBusConnection::sessionBus();
    m[QStringLiteral("busOk")] = bus.isConnected();
    bool running = bus.isConnected() && bus.interface()->isServiceRegistered(QStringLiteral("org.freedesktop.Notifications"));
    m[QStringLiteral("running")] = running;
    if (running) {
        QDBusInterface n(QStringLiteral("org.freedesktop.Notifications"), QStringLiteral("/org/freedesktop/Notifications"), QStringLiteral("org.freedesktop.Notifications"), bus);
        QDBusMessage r = n.call(QStringLiteral("GetServerInformation"));
        if (r.type() == QDBusMessage::ReplyMessage && r.arguments().size() >= 3) {
            m[QStringLiteral("name")] = r.arguments().at(0); m[QStringLiteral("vendor")] = r.arguments().at(1); m[QStringLiteral("version")] = r.arguments().at(2);
        }
    }
    m_server = m;
    emit refreshed();
}

bool NotifyBackend::sendTest(const QString &summary, const QString &body)
{
    QDBusInterface n(QStringLiteral("org.freedesktop.Notifications"), QStringLiteral("/org/freedesktop/Notifications"), QStringLiteral("org.freedesktop.Notifications"), QDBusConnection::sessionBus());
    if (!n.isValid()) return false;
    QDBusReply<uint> r = n.call(QStringLiteral("Notify"), QStringLiteral("hagra-settings"), 0u, QStringLiteral("preferences-desktop"), summary, body, QStringList(), QVariantMap(), 5000);
    refresh();
    return r.isValid();
}
