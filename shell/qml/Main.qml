// 하그라 셸 — 루트. 패널·실행 메뉴·전원 메뉴 창을 소유하고 IPC 명령을 연결한다.
import QtQuick
import HagraShell 1.0

Item {
    id: root

    Panel {
        id: panel
        launcherOpen: launcher.visible
        onLauncherRequested: launcher.toggle()
        onPowerRequested: powerMenu.toggle()
    }
    Launcher {
        id: launcher
        onVisibleChanged: if (visible) powerMenu.visible = false
    }
    PowerMenu {
        id: powerMenu
        onVisibleChanged: if (visible) launcher.visible = false
    }
    AppearanceWindow { id: appearance }

    Connections {
        target: Shell
        function onToggleLauncher() { launcher.toggle() }
        function onShowLauncher() { launcher.visible = true }
        function onHideLauncher() { launcher.visible = false }
        function onTogglePowerMenu() { powerMenu.toggle() }
        function onShowAppearance() { appearance.show(); appearance.raise(); appearance.requestActivate() }
    }
}
