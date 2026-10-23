// SPDX-License-Identifier: GPL-3.0-or-later
#include "power.h"

#include <QDBusConnection>
#include <QDBusInterface>
#include <QDBusReply>
#include <QLoggingCategory>
#include <QProcess>
#include <QStandardPaths>

Q_LOGGING_CATEGORY(lcPower, "minos.power")

Power::Power(QObject *parent) : QObject(parent) {}

bool Power::callLogind(const QString &method)
{
    QDBusInterface logind(QStringLiteral("org.freedesktop.login1"), QStringLiteral("/org/freedesktop/login1"),
                          QStringLiteral("org.freedesktop.login1.Manager"), QDBusConnection::systemBus());
    if (!logind.isValid()) {
        qCWarning(lcPower) << "logind not reachable:" << QDBusConnection::systemBus().lastError().message();
        return false;
    }
    QDBusReply<void> reply = logind.call(method, true /* interactive: polkit 인증 허용 */);
    if (!reply.isValid()) {
        qCWarning(lcPower) << method << "failed:" << reply.error().message();
        return false;
    }
    qCInfo(lcPower) << method << "requested via logind";
    return true;
}

static void fallbackSystemctl(const QString &verb)
{
    qCInfo(lcPower) << "falling back to systemctl" << verb;
    QProcess::startDetached(QStringLiteral("systemctl"), { verb });
}

void Power::powerOff()
{
    if (!callLogind(QStringLiteral("PowerOff"))) {
        fallbackSystemctl(QStringLiteral("poweroff"));
        emit failed(QStringLiteral("poweroff"), QStringLiteral("logind unavailable; used systemctl"));
    }
}

void Power::reboot()
{
    if (!callLogind(QStringLiteral("Reboot"))) {
        fallbackSystemctl(QStringLiteral("reboot"));
        emit failed(QStringLiteral("reboot"), QStringLiteral("logind unavailable; used systemctl"));
    }
}

void Power::suspend()
{
    if (!callLogind(QStringLiteral("Suspend")))
        emit failed(QStringLiteral("suspend"), QStringLiteral("logind unavailable"));
}

void Power::logout()
{
    // labwc --exit 은 실행 중인 labwc 인스턴스에 종료를 요청한다. 세션 스크립트가 끝나면 greetd가 정리한다.
    if (!QStandardPaths::findExecutable(QStringLiteral("labwc")).isEmpty()) {
        QProcess::startDetached(QStringLiteral("labwc"), { QStringLiteral("--exit") });
        return;
    }
    const QString session = qEnvironmentVariable("XDG_SESSION_ID");
    if (!session.isEmpty())
        QProcess::startDetached(QStringLiteral("loginctl"), { QStringLiteral("terminate-session"), session });
    else
        emit failed(QStringLiteral("logout"), QStringLiteral("no compositor or session id"));
}
