// 작업 표시줄 창 항목의 우클릭 메뉴 (패널 밖에 떠야 하므로 별도 layer-shell 창). 항목: 활성화/최소화, 최대화/복원, 닫기.
import QtQuick
import HagraLayerShell 1.0
import HagraUI 1.0
import HagraShell 1.0

LayerWindow {
    id: menu
    scope: "hagra-taskmenu"
    layer: LayerWindow.Overlay
    property bool panelAtTop: false
    anchors: LayerWindow.AnchorLeft | (panelAtTop ? LayerWindow.AnchorTop : LayerWindow.AnchorBottom)
    keyboardInteractivity: LayerWindow.KeyboardExclusive
    width: 220
    height: column.implicitHeight + Theme.windowBorderWidth * 2
    color: Theme.surface
    visible: false
    property int row: -1
    property var info: ({})
    function openFor(r, x) { row = r; info = Toplevels.info(r); marginLeft = Math.max(0, Math.round(x)); visible = true }
    readonly property var entries: [
        { label: info.minimized ? qsTr("복원") : (info.activated ? qsTr("최소화") : qsTr("활성화")), action: "toggle", icon: "window" },
        { label: info.maximized ? qsTr("최대화 해제") : qsTr("최대화"), action: "maximize", icon: "view-grid" },
        { label: qsTr("닫기"), action: "close", icon: "close" },
    ]
    Rectangle { anchors.fill: parent; color: "transparent"; border.width: Theme.windowBorderWidth; border.color: Theme.borderStrong; z: 10 }
    Column {
        id: column
        anchors.fill: parent; anchors.margins: Theme.windowBorderWidth
        focus: true
        property int current: 0
        Keys.onEscapePressed: menu.visible = false
        Keys.onUpPressed: current = Math.max(0, current - 1)
        Keys.onDownPressed: current = Math.min(menu.entries.length - 1, current + 1)
        Keys.onReturnPressed: run(menu.entries[current].action)
        Keys.onEnterPressed: run(menu.entries[current].action)
        Keys.onSpacePressed: run(menu.entries[current].action)
        function run(a) {
            menu.visible = false
            if (a === "toggle") { if (menu.info.minimized || !menu.info.activated) Toplevels.activate(menu.row); else Toplevels.minimize(menu.row) }
            else if (a === "maximize") Toplevels.toggleMaximize(menu.row)
            else if (a === "close") Toplevels.close(menu.row)
        }
        Item { width: 1; height: Theme.padding }
        MLabel { x: Theme.paddingLarge; width: parent.width - Theme.paddingLarge * 2; text: menu.info.title || ""; elide: Text.ElideRight; muted: true; font.pixelSize: Theme.fontSizeSmall; height: Theme.rowHeight - 12 }
        MSeparator { width: parent.width }
        Repeater { model: menu.entries
            delegate: MListRow { required property var modelData; required property int index
                width: column.width; implicitHeight: Theme.rowHeight; text: modelData.label; icon: modelData.icon
                selected: index === column.current; focusVisible: index === column.current && column.activeFocus
                onClicked: column.run(modelData.action) } }
        Item { width: 1; height: Theme.padding }
    }
    onVisibleChanged: if (visible) { column.current = 0; column.forceActiveFocus() }
}
