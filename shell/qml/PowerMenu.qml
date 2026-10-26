// 하그라 셸 — 전원 메뉴 (패널 위 오른쪽). 밝은 표면 + 2px 청록 경계 + 상단 연화 띠.
import QtQuick
import HagraLayerShell 1.0
import HagraUI 1.0
import HagraShell 1.0

LayerWindow {
    id: menu
    scope: "hagra-power"
    layer: LayerWindow.Overlay
    anchors: LayerWindow.AnchorRight | LayerWindow.AnchorBottom
    marginBottom: 0   // 패널 exclusive zone 위에 바로 붙는다
    keyboardInteractivity: LayerWindow.KeyboardExclusive
    width: 240
    height: column.implicitHeight + Theme.windowBorderWidth * 2
    color: Theme.surface
    visible: false

    function toggle() { visible = !visible }

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.width: Theme.windowBorderWidth
        border.color: Theme.borderStrong
        z: 10
    }

    Column {
        id: column
        anchors.fill: parent
        anchors.margins: Theme.windowBorderWidth
        focus: true
        Keys.onEscapePressed: menu.visible = false
        Keys.onUpPressed: current = Math.max(0, current - 1)
        Keys.onDownPressed: current = Math.min(entries.length - 1, current + 1)
        Keys.onReturnPressed: run(entries[current].action)
        Keys.onEnterPressed: run(entries[current].action)
        Keys.onSpacePressed: run(entries[current].action)
        property int current: 0
        readonly property var entries: [
            { label: "시스템 종료", action: "poweroff", icon: "power" },
            { label: "다시 시작",   action: "reboot",   icon: "up" },
            { label: "로그아웃",    action: "logout",   icon: "back" },
            { label: "취소",        action: "cancel",   icon: "close" },
        ]
        function run(action) {
            menu.visible = false
            switch (action) {
            case "poweroff": Power.powerOff(); break
            case "reboot":   Power.reboot(); break
            case "logout":   Power.logout(); break
            }
        }

        MOrnamentBand { width: parent.width }
        MSeparator { width: parent.width }
        Item { width: 1; height: Theme.padding }
        Repeater {
            model: column.entries
            delegate: MListRow {
                required property var modelData
                required property int index
                width: column.width
                implicitHeight: Theme.rowHeight + Theme.padding
                text: modelData.label
                icon: modelData.icon
                selected: index === column.current
                focusVisible: index === column.current && column.activeFocus
                onClicked: column.run(modelData.action)
            }
        }
        Item { width: 1; height: Theme.padding }
    }
    onVisibleChanged: if (visible) { column.current = 0; column.forceActiveFocus() }
}
