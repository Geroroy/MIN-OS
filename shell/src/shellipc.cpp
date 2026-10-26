// SPDX-License-Identifier: GPL-3.0-or-later
#include "shellipc.h"

#include <QFile>
#include <QLocalServer>
#include <QLocalSocket>
#include <QLoggingCategory>

Q_LOGGING_CATEGORY(lcIpc, "hagra.ipc")

ShellIpc::ShellIpc(QObject *parent) : QObject(parent) {}

ShellIpc::~ShellIpc()
{
    if (m_server) {
        m_server->close();
        QLocalServer::removeServer(socketPath());
    }
}

QString ShellIpc::socketPath()
{
    QString dir = qEnvironmentVariable("XDG_RUNTIME_DIR");
    if (dir.isEmpty())
        dir = QStringLiteral("/tmp");
    const QString display = qEnvironmentVariable("WAYLAND_DISPLAY", QStringLiteral("wayland-0"));
    return dir + QStringLiteral("/hagra-shell-") + display + QStringLiteral(".sock");
}

bool ShellIpc::sendToRunningInstance(const QString &command)
{
    QLocalSocket socket;
    socket.connectToServer(socketPath());
    if (!socket.waitForConnected(300)) {
        if (QFile::exists(socketPath())) {
            qCInfo(lcIpc) << "removing stale socket" << socketPath();
            QLocalServer::removeServer(socketPath());
        }
        return false;
    }
    socket.write(command.toUtf8() + '\n');
    socket.waitForBytesWritten(300);
    socket.disconnectFromServer();
    return true;
}

bool ShellIpc::listen()
{
    m_server = new QLocalServer(this);
    m_server->setSocketOptions(QLocalServer::UserAccessOption);
    QLocalServer::removeServer(socketPath());
    if (!m_server->listen(socketPath())) {
        qCWarning(lcIpc) << "cannot listen on" << socketPath() << m_server->errorString();
        return false;
    }
    connect(m_server, &QLocalServer::newConnection, this, [this] {
        while (QLocalSocket *client = m_server->nextPendingConnection()) {
            connect(client, &QLocalSocket::readyRead, this, [this, client] {
                // dispatch()는 창을 만들며 중첩 이벤트 루프를 돌 수 있다. 그 사이 client가 끊겨 삭제될 수 있으므로
                // 먼저 모든 줄을 읽고, 명령은 이벤트 루프 다음 회차에 처리한다.
                QStringList lines;
                while (client->canReadLine())
                    lines << QString::fromUtf8(client->readLine()).trimmed();
                for (const QString &line : std::as_const(lines))
                    QMetaObject::invokeMethod(this, [this, line] { dispatch(line); }, Qt::QueuedConnection);
            });
            connect(client, &QLocalSocket::disconnected, client, &QObject::deleteLater);
        }
    });
    qCInfo(lcIpc) << "listening on" << socketPath();
    return true;
}

void ShellIpc::dispatch(const QString &command)
{
    qCDebug(lcIpc) << "command" << command;
    if (command == QLatin1String("toggle-launcher")) emit toggleLauncher();
    else if (command == QLatin1String("show-launcher")) emit showLauncher();
    else if (command == QLatin1String("hide-launcher")) emit hideLauncher();
    else if (command == QLatin1String("power")) emit togglePowerMenu();
    else if (command == QLatin1String("appearance")) emit showAppearance();
    else if (command == QLatin1String("quit")) emit quitRequested();
    else if (command == QLatin1String("terminal")) emit launchTerminal();
    else emit unknownCommand(command);
}
