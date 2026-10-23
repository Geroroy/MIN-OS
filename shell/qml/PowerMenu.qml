// MIN Shell — 전원 메뉴 (패널 위 오른쪽)
import QtQuick
import MinLayerShell 1.0
import MinUI 1.0
import MinShell 1.0

LayerWindow {
    id: menu
    scope: "minos-power"
    layer: LayerWindow.Overlay
    anchors: LayerWindow.AnchorRight | LayerWindow.AnchorBottom
    marginBottom: Theme.panelHeight
    keyboardInteractivity: LayerWindow.KeyboardExclusive
    width: 200
    height: column.implicitHeight + Theme.borderWidth * 2
    color: Theme.surface
    visible: false

    function toggle() { visible = !visible }

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.width: Theme.borderWidth
        border.color: Theme.borderStrong

        Column {
            id: column
            anchors.fill: parent
            anchors.margins: Theme.borderWidth
            focus: true
            Keys.onEscapePressed: menu.visible = false

            Repeater {
                model: [
                    { label: "Shut down", action: "poweroff", danger: true },
                    { label: "Reboot",    action: "reboot",   danger: false },
                    { label: "Log out",   action: "logout",   danger: false },
                    { label: "Cancel",    action: "cancel",   danger: false },
                ]
                delegate: MListRow {
                    required property var modelData
                    width: column.width
                    implicitHeight: Theme.rowHeight + Theme.paddingLarge
                    text: modelData.label
                    onClicked: {
                        menu.visible = false
                        switch (modelData.action) {
                        case "poweroff": Power.powerOff(); break
                        case "reboot":   Power.reboot(); break
                        case "logout":   Power.logout(); break
                        }
                    }
                }
            }
        }
    }
    Component.onCompleted: menu.visibleChanged.connect(function() { if (menu.visible) column.forceActiveFocus() })
}
