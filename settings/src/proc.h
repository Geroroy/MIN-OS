// hagra-settings — 외부 명령 실행 도우미 (동기, 제한 시간). 백엔드는 설치된 도구가 있을 때만 그 도구를 쓰고, 없으면 이유를 돌려준다.
// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once
#include <QObject>
#include <QString>
#include <QStringList>
#include <QVariantMap>

struct ProcResult {
    bool started = false;
    int code = -1;
    QString out;
    QString err;
    bool ok() const { return started && code == 0; }
};

class Proc : public QObject
{
    Q_OBJECT
public:
    using QObject::QObject;
    static bool has(const QString &program);
    static QString path(const QString &program);
    static ProcResult run(const QString &program, const QStringList &args = {}, int timeoutMs = 4000);
    static bool detach(const QString &program, const QStringList &args = {});
    /// labwc 설정 재읽기: LABWC_PID 가 있으면 `labwc --reconfigure`, 아니면 SIGHUP (같은 효과)
    static bool reconfigureLabwc();
    /// QML 용: { started, code, out, err, ok }
    Q_INVOKABLE QVariantMap exec(const QString &program, const QStringList &args = {}, int timeoutMs = 4000) const;
    Q_INVOKABLE bool have(const QString &program) const { return has(program); }
    Q_INVOKABLE bool launch(const QString &program, const QStringList &args = {}) const { return detach(program, args); }
};
