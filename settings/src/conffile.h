// hagra-settings — 사용자 설정 파일(~/.config/hagra/<name>.conf, INI/QSettings) 접근. 다른 프로세스의 변경을 감시해 changed() 를 낸다.
//   QML: ConfFile { name: "accessibility" }  → get("text/scale", 1.0), set("text/scale", 1.2)
// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once
#include <QObject>
#include <QVariant>

class QFileSystemWatcher;

class ConfFile : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString name READ name WRITE setName NOTIFY nameChanged)
    Q_PROPERTY(QString path READ path NOTIFY nameChanged)
    Q_PROPERTY(int revision READ revision NOTIFY changed)   // 바인딩 갱신용: get() 호출을 revision 에 의존시킨다
public:
    explicit ConfFile(QObject *parent = nullptr);
    static QString dirPath();
    static QString pathFor(const QString &name);

    QString name() const { return m_name; }
    void setName(const QString &n);
    QString path() const { return pathFor(m_name); }
    int revision() const { return m_revision; }

    Q_INVOKABLE QVariant get(const QString &key, const QVariant &fallback = QVariant()) const;
    Q_INVOKABLE void set(const QString &key, const QVariant &value);
    Q_INVOKABLE void remove(const QString &key);
    Q_INVOKABLE bool contains(const QString &key) const;
    Q_INVOKABLE QStringList keys(const QString &group = QString()) const;

Q_SIGNALS:
    void nameChanged();
    void changed();

private:
    void watch();
    QString m_name;
    int m_revision = 0;
    QFileSystemWatcher *m_watcher = nullptr;
};
