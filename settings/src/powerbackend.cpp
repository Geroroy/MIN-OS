// SPDX-License-Identifier: GPL-3.0-or-later
#include "powerbackend.h"
#include "proc.h"
#include <QDBusConnection>
#include <QDBusInterface>
#include <QDBusReply>
#include <QDir>
#include <QFile>

PowerBackend::PowerBackend(QObject *parent) : QObject(parent) { refresh(); }

static QString readSys(const QString &p)
{
    QFile f(p);
    return f.open(QIODevice::ReadOnly) ? QString::fromUtf8(f.readAll()).trimmed() : QString();
}

QVariantList PowerBackend::readBatteries(const QString &sysDir)
{
    QVariantList l;
    QDir d(sysDir);
    for (const QString &n : d.entryList(QDir::Dirs | QDir::NoDotAndDotDot, QDir::Name)) {
        const QString base = d.absoluteFilePath(n);
        if (readSys(base + QStringLiteral("/type")) != QLatin1String("Battery")) continue;
        QVariantMap b;
        b[QStringLiteral("name")] = n;
        b[QStringLiteral("status")] = readSys(base + QStringLiteral("/status"));
        const QString cap = readSys(base + QStringLiteral("/capacity"));
        b[QStringLiteral("capacity")] = cap.isEmpty() ? -1 : cap.toInt();
        const double full = readSys(base + QStringLiteral("/energy_full")).toDouble(), design = readSys(base + QStringLiteral("/energy_full_design")).toDouble();
        b[QStringLiteral("health")] = (full > 0 && design > 0) ? qRound(full / design * 100) : -1;
        b[QStringLiteral("model")] = readSys(base + QStringLiteral("/model_name"));
        l << b;
    }
    return l;
}

void PowerBackend::refresh()
{
    QVariantMap m;
    QDBusInterface login1(QStringLiteral("org.freedesktop.login1"), QStringLiteral("/org/freedesktop/login1"), QStringLiteral("org.freedesktop.login1.Manager"), QDBusConnection::systemBus());
    m[QStringLiteral("available")] = login1.isValid();
    for (const char *k : { "CanPowerOff", "CanReboot", "CanSuspend", "CanHibernate" }) {
        QString v = QStringLiteral("na");
        if (login1.isValid()) { QDBusReply<QString> r = login1.call(QLatin1String(k)); if (r.isValid()) v = r.value(); }
        m[QString::fromLatin1(k)] = v;
    }
    m_logind = m;
    m_batteries = readBatteries(QStringLiteral("/sys/class/power_supply"));
    m_onBattery = false;
    QDir d(QStringLiteral("/sys/class/power_supply"));
    bool anyAc = false, acOnline = false;
    for (const QString &n : d.entryList(QDir::Dirs | QDir::NoDotAndDotDot)) {
        const QString t = readSys(d.absoluteFilePath(n) + QStringLiteral("/type"));
        if (t == QLatin1String("Mains") || t == QLatin1String("USB")) { anyAc = true; if (readSys(d.absoluteFilePath(n) + QStringLiteral("/online")) == QLatin1String("1")) acOnline = true; }
    }
    m_onBattery = !m_batteries.isEmpty() && anyAc && !acOnline;
    emit refreshed();
}

bool PowerBackend::idleToolAvailable() const { return Proc::has(QStringLiteral("swayidle")); }

QString PowerBackend::idleReason() const
{
    return idleToolAvailable() ? QString() : QStringLiteral("유휴 시 화면 끄기·자동 절전은 swayidle 이 필요합니다. 이 이미지에는 포함되어 있지 않아 설정을 제공하지 않습니다 (설치: swayidle).");
}

bool PowerBackend::action(const QString &name)
{
    QDBusInterface login1(QStringLiteral("org.freedesktop.login1"), QStringLiteral("/org/freedesktop/login1"), QStringLiteral("org.freedesktop.login1.Manager"), QDBusConnection::systemBus());
    if (!login1.isValid()) { emit failed(QStringLiteral("logind 에 연결할 수 없습니다")); return false; }
    QDBusReply<void> r = login1.call(name, true);
    if (!r.isValid()) { emit failed(r.error().message()); return false; }
    return true;
}
