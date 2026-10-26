// hagra-settings — 정보: /etc/hagra-release, os-release, 커널, CPU, 메모리, 디스크, Qt/labwc 버전, 세션 로그 위치.
// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once
#include <QObject>
#include <QVariantMap>

class SystemInfo : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantMap info READ info NOTIFY refreshed)
public:
    explicit SystemInfo(QObject *parent = nullptr);
    QVariantMap info() const { return m_info; }
    Q_INVOKABLE void refresh();
    Q_INVOKABLE QString sessionLogPath() const;
    Q_INVOKABLE QString shellLogPath() const;
    Q_INVOKABLE QString readTail(const QString &path, int lines = 60) const;
    /// 설치된 커서 테마 이름 (<data>/icons/<name>/cursors 가 있는 것)
    Q_INVOKABLE QStringList cursorThemes() const;
    static QVariantMap readKeyValueFile(const QString &path);   // KEY="value" 형식
    static QString humanSize(qint64 bytes);
Q_SIGNALS:
    void refreshed();
private:
    QVariantMap m_info;
};
