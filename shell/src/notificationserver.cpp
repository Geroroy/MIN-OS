// SPDX-License-Identifier: GPL-3.0-or-later
#include "notificationserver.h"
#include <QDBusConnection>
#include <QDBusConnectionInterface>
#include <QDir>
#include <QFileInfo>
#include <QFileSystemWatcher>
#include <QLoggingCategory>
#include <QSettings>
#include <QStandardPaths>
#include <QTimer>

Q_LOGGING_CATEGORY(lcNotify, "hagra.notify")

NotificationServer::NotificationServer(QObject *parent) : QAbstractListModel(parent)
{
    m_expiry = new QTimer(this);
    m_expiry->setInterval(500);
    connect(m_expiry, &QTimer::timeout, this, &NotificationServer::expirePopups);
    reloadSettings();
    m_watcher = new QFileSystemWatcher(this);
    auto later = [this] { QTimer::singleShot(150, this, [this] { reloadSettings(); }); };
    connect(m_watcher, &QFileSystemWatcher::fileChanged, this, later);
    connect(m_watcher, &QFileSystemWatcher::directoryChanged, this, later);
    const QString dir = QFileInfo(configPath()).absolutePath();
    QDir().mkpath(dir);
    m_watcher->addPath(dir);
    if (QFileInfo::exists(configPath())) m_watcher->addPath(configPath());
}

QString NotificationServer::configPath()
{
    return QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation) + QStringLiteral("/hagra/notifications.conf");
}

void NotificationServer::reloadSettings()
{
    QSettings s(configPath(), QSettings::IniFormat);
    s.beginGroup(QStringLiteral("notifications"));
    const bool dnd = s.value(QStringLiteral("doNotDisturb"), false).toBool();
    const int timeout = qBound(2, s.value(QStringLiteral("timeoutSec"), 6).toInt(), 60);
    const QString pos = s.value(QStringLiteral("position"), QStringLiteral("top-right")).toString();
    s.endGroup();
    if (dnd == m_dnd && timeout == m_timeoutSec && pos == m_position) return;
    m_dnd = dnd; m_timeoutSec = timeout; m_position = pos;
    emit settingsChanged();
    if (m_watcher && QFileInfo::exists(configPath()) && !m_watcher->files().contains(configPath())) m_watcher->addPath(configPath());
}

void NotificationServer::setDoNotDisturb(bool v)
{
    if (v == m_dnd) return;
    QDir().mkpath(QFileInfo(configPath()).absolutePath());
    QSettings s(configPath(), QSettings::IniFormat);
    s.setValue(QStringLiteral("notifications/doNotDisturb"), v);
    s.sync();
    reloadSettings();
}

bool NotificationServer::registerOnBus()
{
    QDBusConnection bus = QDBusConnection::sessionBus();
    if (!bus.isConnected()) { qCWarning(lcNotify) << "no session bus; notification server disabled"; return false; }
    new NotificationsAdaptor(this);
    if (!bus.registerObject(QStringLiteral("/org/freedesktop/Notifications"), this)) { qCWarning(lcNotify) << "cannot register object:" << bus.lastError().message(); return false; }
    if (!bus.registerService(QStringLiteral("org.freedesktop.Notifications"))) {
        qCWarning(lcNotify) << "org.freedesktop.Notifications already owned by another server:" << bus.lastError().message();
        return false;
    }
    m_registered = true;
    emit registeredChanged();
    qCInfo(lcNotify) << "notification server registered on the session bus";
    return true;
}

int NotificationServer::rowCount(const QModelIndex &parent) const { return parent.isValid() ? 0 : m_items.size(); }

QVariant NotificationServer::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_items.size()) return {};
    const Notification &n = m_items.at(index.row());
    switch (role) {
    case IdRole: return n.id;
    case AppNameRole: return n.appName;
    case AppIconRole: return n.appIcon;
    case SummaryRole: case Qt::DisplayRole: return n.summary;
    case BodyRole: return n.body;
    case ActionsRole: {
        QVariantList l;
        for (int i = 0; i < n.actionKeys.size(); ++i) l << QVariantMap{ { QStringLiteral("key"), n.actionKeys[i] }, { QStringLiteral("text"), n.actionLabels.value(i) } };
        return l;
    }
    case UrgencyRole: return n.urgency;
    case TimeRole: return n.time;
    case TimeTextRole: return n.time.toString(QStringLiteral("AP h:mm"));
    default: return {};
    }
}

QHash<int, QByteArray> NotificationServer::roleNames() const
{
    return { { IdRole, "nid" }, { AppNameRole, "appName" }, { AppIconRole, "appIcon" }, { SummaryRole, "summary" }, { BodyRole, "body" },
             { ActionsRole, "actions" }, { UrgencyRole, "urgency" }, { TimeRole, "time" }, { TimeTextRole, "timeText" } };
}

int NotificationServer::indexOf(uint id) const
{
    for (int i = 0; i < m_items.size(); ++i) if (m_items[i].id == id) return i;
    return -1;
}

uint NotificationServer::notify(const QString &appName, uint replacesId, const QString &appIcon, const QString &summary, const QString &body,
                                const QStringList &actions, const QVariantMap &hints, int expireTimeout)
{
    Notification n;
    n.appName = appName; n.appIcon = appIcon; n.summary = summary; n.body = body; n.time = QDateTime::currentDateTime();
    for (int i = 0; i + 1 < actions.size(); i += 2) { n.actionKeys << actions[i]; n.actionLabels << actions[i + 1]; }
    if (hints.contains(QStringLiteral("urgency"))) n.urgency = qBound(0, hints.value(QStringLiteral("urgency")).toInt(), 2);
    const int timeoutMs = expireTimeout > 0 ? expireTimeout : (expireTimeout == 0 ? 0 : m_timeoutSec * 1000);
    n.expireAtMs = (n.urgency == 2 || timeoutMs == 0) ? 0 : QDateTime::currentMSecsSinceEpoch() + timeoutMs;
    n.popup = !(m_dnd && n.urgency < 2);
    const int existing = replacesId ? indexOf(replacesId) : -1;
    if (existing >= 0) {
        n.id = replacesId;
        m_items[existing] = n;
        emit dataChanged(index(existing), index(existing));
    } else {
        n.id = m_nextId++;
        beginInsertRows({}, 0, 0);
        m_items.prepend(n);
        endInsertRows();
        while (m_items.size() > 200) { beginRemoveRows({}, m_items.size() - 1, m_items.size() - 1); m_items.removeLast(); endRemoveRows(); }
        ++m_unread;
    }
    if (!m_expiry->isActive()) m_expiry->start();
    emit countChanged();
    emit popupsChanged();
    emit posted(n.id);
    qCInfo(lcNotify) << "notification" << n.id << appName << summary << "urgency" << n.urgency << (n.popup ? "popup" : "silent");
    return n.id;
}

void NotificationServer::closeNotification(uint id, uint reason)
{
    const int i = indexOf(id);
    if (i < 0) return;
    beginRemoveRows({}, i, i);
    m_items.removeAt(i);
    endRemoveRows();
    emit countChanged();
    emit popupsChanged();
    emit notificationClosed(id, reason);
}

void NotificationServer::dismissPopup(uint id)
{
    const int i = indexOf(id);
    if (i < 0 || !m_items[i].popup) return;
    m_items[i].popup = false;
    emit popupsChanged();
}

void NotificationServer::invokeAction(uint id, const QString &key)
{
    if (indexOf(id) < 0) return;
    emit actionInvoked(id, key);
    closeNotification(id, 2);
}

void NotificationServer::remove(uint id) { closeNotification(id, 2); }

void NotificationServer::clearAll()
{
    if (m_items.isEmpty()) return;
    beginResetModel();
    const QList<Notification> old = m_items;
    m_items.clear();
    endResetModel();
    m_unread = 0;
    emit countChanged();
    emit popupsChanged();
    for (const Notification &n : old) emit notificationClosed(n.id, 2);
}

void NotificationServer::markRead()
{
    if (m_unread == 0) return;
    m_unread = 0;
    emit countChanged();
}

QVariantList NotificationServer::popups() const
{
    QVariantList l;
    for (const Notification &n : m_items) {
        if (!n.popup) continue;
        QVariantList actions;
        for (int i = 0; i < n.actionKeys.size(); ++i) actions << QVariantMap{ { QStringLiteral("key"), n.actionKeys[i] }, { QStringLiteral("text"), n.actionLabels.value(i) } };
        l << QVariantMap{ { QStringLiteral("nid"), n.id }, { QStringLiteral("appName"), n.appName }, { QStringLiteral("summary"), n.summary }, { QStringLiteral("body"), n.body },
                          { QStringLiteral("urgency"), n.urgency }, { QStringLiteral("actions"), actions } };
        if (l.size() >= 3) break;
    }
    return l;
}

void NotificationServer::expirePopups()
{
    const qint64 now = QDateTime::currentMSecsSinceEpoch();
    bool changed = false, any = false;
    for (Notification &n : m_items) {
        if (!n.popup) continue;
        if (n.expireAtMs && n.expireAtMs <= now) { n.popup = false; changed = true; emit notificationClosed(n.id, 1); }
        else any = true;
    }
    if (changed) emit popupsChanged();
    if (!any) m_expiry->stop();
}

// ---- 어댑터 ----
NotificationsAdaptor::NotificationsAdaptor(NotificationServer *server) : QDBusAbstractAdaptor(server), m_server(server)
{
    connect(server, &NotificationServer::notificationClosed, this, &NotificationsAdaptor::NotificationClosed);
    connect(server, &NotificationServer::actionInvoked, this, &NotificationsAdaptor::ActionInvoked);
}

uint NotificationsAdaptor::Notify(const QString &app_name, uint replaces_id, const QString &app_icon, const QString &summary, const QString &body,
                                  const QStringList &actions, const QVariantMap &hints, int expire_timeout)
{
    return m_server->notify(app_name, replaces_id, app_icon, summary, body, actions, hints, expire_timeout);
}

void NotificationsAdaptor::CloseNotification(uint id) { m_server->closeNotification(id, 3); }

QStringList NotificationsAdaptor::GetCapabilities()
{
    return { QStringLiteral("body"), QStringLiteral("actions"), QStringLiteral("persistence"), QStringLiteral("icon-static") };
}

QString NotificationsAdaptor::GetServerInformation(QString &vendor, QString &version, QString &spec_version)
{
    vendor = QStringLiteral("HAGRA");
    version = QStringLiteral(HAGRA_VERSION);
    spec_version = QStringLiteral("1.2");
    return QStringLiteral("hagra-shell");
}
