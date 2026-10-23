// MIN Shell — 애플리케이션 실행 메뉴 (패널 위 왼쪽, overlay layer, 키보드 독점)
import QtQuick
import MinLayerShell 1.0
import MinUI 1.0
import MinShell 1.0

LayerWindow {
    id: launcher
    scope: "minos-launcher"
    layer: LayerWindow.Overlay
    anchors: LayerWindow.AnchorLeft | LayerWindow.AnchorBottom
    marginBottom: Theme.panelHeight
    keyboardInteractivity: LayerWindow.KeyboardExclusive
    width: 360
    height: 440
    color: Theme.surface
    visible: false

    function toggle() { visible = !visible }
    function activateCurrent() {
        if (list.currentIndex >= 0 && Apps.launch(list.currentIndex))
            launcher.visible = false
    }

    onVisibleChanged: {
        if (visible) {
            Apps.filter = ""
            search.text = ""
            list.currentIndex = 0
            search.forceActiveFocus()
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.width: Theme.borderWidth
        border.color: Theme.borderStrong

        Item {
            id: content
            anchors.fill: parent
            anchors.margins: Theme.borderWidth
            focus: true
            Keys.onEscapePressed: launcher.visible = false
            Keys.onUpPressed: list.currentIndex = Math.max(0, list.currentIndex - 1)
            Keys.onDownPressed: list.currentIndex = Math.min(list.count - 1, list.currentIndex + 1)
            Keys.onPressed: (ev) => {
                if (ev.key === Qt.Key_PageUp) { list.currentIndex = Math.max(0, list.currentIndex - 10); ev.accepted = true }
                else if (ev.key === Qt.Key_PageDown) { list.currentIndex = Math.min(list.count - 1, list.currentIndex + 10); ev.accepted = true }
            }

            Column {
                anchors.fill: parent
                spacing: 0

                // 헤더: 검색
                Item {
                    width: parent.width
                    height: Theme.controlHeight + Theme.paddingLarge * 2
                    MTextField {
                        id: search
                        anchors.fill: parent
                        anchors.margins: Theme.paddingLarge
                        placeholder: "Search applications"
                        onTextChanged: { Apps.filter = text; list.currentIndex = 0 }
                        onAccepted: launcher.activateCurrent()
                    }
                }
                MSeparator { width: parent.width }

                // 결과 목록
                ListView {
                    id: list
                    width: parent.width
                    height: parent.height - y - footer.height - 1
                    clip: true
                    model: Apps
                    currentIndex: 0
                    highlightFollowsCurrentItem: true
                    highlightMoveDuration: 0
                    keyNavigationEnabled: false
                    delegate: MListRow {
                        required property int index
                        required property string name
                        required property string comment
                        text: name
                        detail: comment
                        selected: ListView.isCurrentItem
                        onClicked: { list.currentIndex = index; launcher.activateCurrent() }
                    }
                    MLabel {
                        anchors.centerIn: parent
                        visible: list.count === 0
                        muted: true
                        text: Apps.totalCount === 0 ? "No applications found" : "No match"
                    }
                }
                MSeparator { width: parent.width }

                // 고정 항목
                Row {
                    id: footer
                    width: parent.width
                    height: Theme.controlHeight + Theme.paddingLarge * 2
                    padding: Theme.paddingLarge
                    spacing: Theme.padding
                    MButton {
                        text: "Terminal"
                        onClicked: { if (Apps.launchCommand(Apps.terminalProgram())) launcher.visible = false }
                    }
                    MButton { text: "Files"; enabled: false }
                    MButton { text: "Settings"; enabled: false }
                    Item { width: footer.width - footer.padding * 2 - footer.spacing * 3 - footer.children[0].width - footer.children[1].width - footer.children[2].width - powerBtn.width; height: 1 }
                    MButton {
                        id: powerBtn
                        text: "Power…"
                        onClicked: { launcher.visible = false; Shell.dispatch("power") }
                    }
                }
            }
        }
    }
}
