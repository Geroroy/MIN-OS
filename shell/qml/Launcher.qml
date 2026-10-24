// 하그라 셸 — 응용 프로그램 실행 메뉴 (패널 위 왼쪽, overlay layer, 키보드 독점)
// 밝은 표면 + 2px 청록 경계 + 상단 연화 띠. 문양은 입력 문자열 위에 놓이지 않는다 (DESIGN_SPEC "메뉴와 입력칸").
import QtQuick
import MinLayerShell 1.0
import MinUI 1.0
import MinShell 1.0

LayerWindow {
    id: launcher
    scope: "minos-launcher"
    layer: LayerWindow.Overlay
    anchors: LayerWindow.AnchorLeft | LayerWindow.AnchorBottom
    marginBottom: 0   // 패널의 exclusive zone 이 이미 공간을 비우므로 추가 여백 없음 (예전 값은 패널 높이를 두 번 더했다)
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
        border.width: Theme.windowBorderWidth
        border.color: Theme.borderStrong
        z: 10
    }

    Item {
        id: content
        anchors.fill: parent
        anchors.margins: Theme.windowBorderWidth
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

            MOrnamentBand { width: parent.width }
            MSeparator { width: parent.width }

            // 헤더: 검색
            Item {
                width: parent.width
                height: Theme.controlHeight + Theme.paddingLarge * 2
                MSearchField {
                    id: search
                    anchors.fill: parent
                    anchors.margins: Theme.paddingLarge
                    placeholder: "응용 프로그램 검색"
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
                    icon: "apps"
                    selected: ListView.isCurrentItem
                    onClicked: { list.currentIndex = index; launcher.activateCurrent() }
                }
                MLabel {
                    anchors.centerIn: parent
                    visible: list.count === 0
                    muted: true
                    text: Apps.totalCount === 0 ? "설치된 응용 프로그램이 없습니다" : "일치하는 항목이 없습니다"
                }
            }
            MSeparator { width: parent.width }

            // 고정 항목
            Item {
                id: footer
                width: parent.width
                height: Theme.controlHeight + Theme.paddingLarge * 2
                Row {
                    anchors.left: parent.left; anchors.leftMargin: Theme.paddingLarge
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.padding
                    MButton {
                        text: "터미널"; icon: "terminal"
                        onClicked: { if (Apps.launchCommand(Apps.terminalProgram())) launcher.visible = false }
                    }
                    MButton { text: "파일"; icon: "folder"; enabled: false; MToolTip { text: "파일 관리자는 M3 에서 구현 예정" } }
                    MButton { text: "설정"; icon: "settings"; enabled: false; MToolTip { text: "설정은 M2 에서 구현 예정" } }
                }
                MButton {
                    id: powerBtn
                    icon: "power"; text: "전원"
                    anchors.right: parent.right; anchors.rightMargin: Theme.paddingLarge
                    anchors.verticalCenter: parent.verticalCenter
                    onClicked: { launcher.visible = false; Shell.dispatch("power") }
                }
            }
        }
    }
}
