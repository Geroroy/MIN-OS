// SPDX-License-Identifier: GPL-3.0-or-later
#include "proc.h"
#include <QFileInfo>
#include <QProcess>
#include <QStandardPaths>

bool Proc::has(const QString &program) { return !path(program).isEmpty(); }

QString Proc::path(const QString &program)
{
    if (program.isEmpty()) return {};
    if (program.contains(QLatin1Char('/'))) return QFileInfo(program).isExecutable() ? program : QString();
    return QStandardPaths::findExecutable(program);
}

ProcResult Proc::run(const QString &program, const QStringList &args, int timeoutMs)
{
    ProcResult r;
    const QString exe = path(program);
    if (exe.isEmpty()) { r.err = QStringLiteral("not installed: ") + program; return r; }
    QProcess p;
    p.setProgram(exe);
    p.setArguments(args);
    p.start();
    if (!p.waitForStarted(timeoutMs)) { r.err = p.errorString(); return r; }
    r.started = true;
    if (!p.waitForFinished(timeoutMs)) { p.kill(); p.waitForFinished(500); r.err = QStringLiteral("timeout"); r.code = -2; return r; }
    r.code = p.exitStatus() == QProcess::NormalExit ? p.exitCode() : -1;
    r.out = QString::fromUtf8(p.readAllStandardOutput());
    r.err = QString::fromUtf8(p.readAllStandardError());
    return r;
}

bool Proc::detach(const QString &program, const QStringList &args)
{
    const QString exe = path(program);
    return !exe.isEmpty() && QProcess::startDetached(exe, args);
}

QVariantMap Proc::exec(const QString &program, const QStringList &args, int timeoutMs) const
{
    const ProcResult r = run(program, args, timeoutMs);
    return { { QStringLiteral("started"), r.started }, { QStringLiteral("code"), r.code }, { QStringLiteral("out"), r.out },
             { QStringLiteral("err"), r.err }, { QStringLiteral("ok"), r.ok() } };
}

bool Proc::reconfigureLabwc()
{
    if (qEnvironmentVariableIsEmpty("WAYLAND_DISPLAY")) return false;
    if (qEnvironmentVariableIsSet("LABWC_PID") && has(QStringLiteral("labwc")))
        return detach(QStringLiteral("labwc"), { QStringLiteral("--reconfigure") });
    return run(QStringLiteral("pkill"), { QStringLiteral("-HUP"), QStringLiteral("-x"), QStringLiteral("labwc") }, 2000).ok();
}
