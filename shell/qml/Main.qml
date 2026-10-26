// 하그라 셸 — 루트. 화면마다 패널을 두고(Instantiator), 실행 메뉴·전원 메뉴·알림·달력·소리·창 메뉴 팝업을 소유하며 IPC 명령을 연결한다.
// 패널 위치(panel.conf [panel] position=bottom|top)에 따라 모든 팝업이 같은 가장자리에 붙는다.
import QtQuick
import HagraLayerShell 1.0
import HagraShell 1.0

Item {
    id: root
    ConfFile { id: panelConf; name: "panel" }
    readonly property bool panelAtTop: panelConf.revision >= 0 && String(panelConf.get("panel/position", "bottom")) === "top"
    readonly property bool clockSeconds: panelConf.revision >= 0 && String(panelConf.get("panel/clockSeconds", false)) === "true"
    property var primaryPanel: null

    function closeAll(except) {
        if (except !== launcher) launcher.visible = false
        if (except !== powerMenu) powerMenu.visible = false
        if (except !== center) center.visible = false
        if (except !== calendar) calendar.visible = false
        if (except !== audio) audio.visible = false
        if (except !== taskMenu) taskMenu.visible = false
    }
    function moveTo(popup, screen) { if (screen && !popup.visible && popup.targetOutput !== screen.name) popup.targetOutput = screen.name }

    Instantiator {
        model: Qt.application.screens
        delegate: Panel {
            required property var modelData
            targetOutput: modelData.name
            atTop: root.panelAtTop
            clockSeconds: root.clockSeconds
            launcherOpen: launcher.visible
            powerOpen: powerMenu.visible
            notificationsOpen: center.visible
            calendarOpen: calendar.visible
            audioOpen: audio.visible
            onLauncherRequested: { root.moveTo(launcher, modelData); launcher.toggle() }
            onPowerRequested: { root.moveTo(powerMenu, modelData); powerMenu.toggle() }
            onNotificationsRequested: { root.moveTo(center, modelData); center.toggle() }
            onCalendarRequested: { root.moveTo(calendar, modelData); calendar.toggle() }
            onAudioRequested: { root.moveTo(audio, modelData); audio.toggle() }
            onTaskMenuRequested: (row, x) => { root.moveTo(taskMenu, modelData); root.closeAll(taskMenu); taskMenu.openFor(row, x) }
            Component.onCompleted: if (!root.primaryPanel) root.primaryPanel = this
        }
    }
    Launcher { id: launcher; panelAtTop: root.panelAtTop; onVisibleChanged: if (visible) root.closeAll(launcher) }
    PowerMenu { id: powerMenu; panelAtTop: root.panelAtTop; onVisibleChanged: if (visible) root.closeAll(powerMenu) }
    NotificationCenter { id: center; panelAtTop: root.panelAtTop; onVisibleChanged: if (visible) root.closeAll(center) }
    CalendarPopup { id: calendar; panelAtTop: root.panelAtTop; onVisibleChanged: if (visible) root.closeAll(calendar) }
    AudioPopup { id: audio; panelAtTop: root.panelAtTop; onVisibleChanged: if (visible) root.closeAll(audio) }
    TaskMenu { id: taskMenu; panelAtTop: root.panelAtTop }
    NotificationPopups { id: popups }
    AppearanceWindow { id: appearance }

    Connections {
        target: Shell
        function onToggleLauncher() { launcher.toggle() }
        function onShowLauncher() { launcher.visible = true }
        function onHideLauncher() { launcher.visible = false }
        function onTogglePowerMenu() { powerMenu.toggle() }
        function onToggleNotifications() { center.toggle() }
        function onToggleCalendar() { calendar.toggle() }
        function onToggleAudio() { audio.toggle() }
        function onShowAppearance() { appearance.show(); appearance.raise(); appearance.requestActivate() }
    }
}
