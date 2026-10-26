// 하그라 셸 — 단일 인스턴스 IPC (QLocalServer). `hagra-shell --toggle-launcher` 등이 실행 중 인스턴스로 전달된다.
// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once
#include <QObject>
#include <QString>

class QLocalServer;

class ShellIpc : public QObject
{
    Q_OBJECT
public:
    explicit ShellIpc(QObject *parent = nullptr);
    ~ShellIpc() override;

    static QString socketPath();
    /// 실행 중인 인스턴스가 있으면 명령을 보내고 true. 없으면 false (오래된 소켓 파일은 정리).
    static bool sendToRunningInstance(const QString &command);

    bool listen();
    Q_INVOKABLE void dispatch(const QString &command);

Q_SIGNALS:
    void toggleLauncher();
    void showLauncher();
    void hideLauncher();
    void togglePowerMenu();
    void quitRequested();
    void launchTerminal();
    void showAppearance();
    void unknownCommand(const QString &command);

private:
    QLocalServer *m_server = nullptr;
};
