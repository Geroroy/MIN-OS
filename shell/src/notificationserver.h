// 하그라 셸 — 알림 서버 (org.freedesktop.Notifications, 세션 D-Bus) + 알림 목록 모델.
//   팝업은 QML(NotificationPopups.qml)이 popups 속성으로 그리고, 알림 센터는 전체 모델을 보여 준다.
//   설정: ~/.config/hagra/notifications.conf [notifications] doNotDisturb= timeoutSec= position=  (hagra-settings 가 쓴다; 변경 감시)
// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once
#include <QAbstractListModel>
#include <QDBusAbstractAdaptor>
#include <QDateTime>
#include <QStringList>
#include <QVariantMap>

class QFileSystemWatcher;
class QTimer;

struct Notification {
    uint id = 0;
    QString appName, appIcon, summary, body;
    QStringList actionKeys, actionLabels;
    int urgency = 1;          // 0 low · 1 normal · 2 critical
    QDateTime time;
    qint64 expireAtMs = 0;    // 0 = 팝업 만료 없음(critical)
    bool popup = true;        // 팝업에 아직 떠 있는지
};

class NotificationServer : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int count READ count NOTIFY countChanged)
    Q_PROPERTY(int unread READ unread NOTIFY countChanged)
    Q_PROPERTY(bool registered READ isRegistered NOTIFY registeredChanged)
    Q_PROPERTY(bool doNotDisturb READ doNotDisturb WRITE setDoNotDisturb NOTIFY settingsChanged)
    Q_PROPERTY(int timeoutSec READ timeoutSec NOTIFY settingsChanged)
    Q_PROPERTY(QString position READ position NOTIFY settingsChanged)
    Q_PROPERTY(QVariantList popups READ popups NOTIFY popupsChanged)
public:
    enum Roles { IdRole = Qt::UserRole + 1, AppNameRole, AppIconRole, SummaryRole, BodyRole, ActionsRole, UrgencyRole, TimeRole, TimeTextRole };
    explicit NotificationServer(QObject *parent = nullptr);
    static QString configPath();

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;
    int count() const { return m_items.size(); }
    int unread() const { return m_unread; }
    bool isRegistered() const { return m_registered; }
    bool doNotDisturb() const { return m_dnd; }
    void setDoNotDisturb(bool v);
    int timeoutSec() const { return m_timeoutSec; }
    QString position() const { return m_position; }
    QVariantList popups() const;

    bool registerOnBus();
    // D-Bus 메서드 (어댑터가 호출)
    uint notify(const QString &appName, uint replacesId, const QString &appIcon, const QString &summary, const QString &body,
                const QStringList &actions, const QVariantMap &hints, int expireTimeout);
    void closeNotification(uint id, uint reason = 3);

    Q_INVOKABLE void dismissPopup(uint id);          // 팝업만 내림 (센터에 남음)
    Q_INVOKABLE void invokeAction(uint id, const QString &key);
    Q_INVOKABLE void remove(uint id);                 // 센터에서 제거 (닫힘 신호 reason 2)
    Q_INVOKABLE void clearAll();
    Q_INVOKABLE void markRead();
    Q_INVOKABLE void reloadSettings();

Q_SIGNALS:
    void countChanged();
    void registeredChanged();
    void settingsChanged();
    void popupsChanged();
    void notificationClosed(uint id, uint reason);
    void actionInvoked(uint id, const QString &key);
    void posted(uint id);

private:
    void expirePopups();
    int indexOf(uint id) const;
    QList<Notification> m_items;
    uint m_nextId = 1;
    int m_unread = 0;
    bool m_registered = false;
    bool m_dnd = false;
    int m_timeoutSec = 6;
    QString m_position = QStringLiteral("top-right");
    QTimer *m_expiry = nullptr;
    QFileSystemWatcher *m_watcher = nullptr;
};

class NotificationsAdaptor : public QDBusAbstractAdaptor
{
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.freedesktop.Notifications")
public:
    explicit NotificationsAdaptor(NotificationServer *server);
public Q_SLOTS:
    uint Notify(const QString &app_name, uint replaces_id, const QString &app_icon, const QString &summary, const QString &body,
                const QStringList &actions, const QVariantMap &hints, int expire_timeout);
    void CloseNotification(uint id);
    QStringList GetCapabilities();
    QString GetServerInformation(QString &vendor, QString &version, QString &spec_version);
Q_SIGNALS:
    void NotificationClosed(uint id, uint reason);
    void ActionInvoked(uint id, const QString &action_key);
private:
    NotificationServer *m_server;
};
