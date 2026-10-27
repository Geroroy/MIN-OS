// 콘텐츠 위·아래의 알림 막대 (권한 요청 · 내려받기 · 페이지 오류). 왼쪽 3px 막대 색 = 종류. 버튼은 actions 로 넘긴다.
import QtQuick
import HagraUI 1.0

Rectangle {
    id: bar
    property string icon: "info"
    property string text: ""
    property string kind: "info"          // "info" | "warn"
    property var actions: []              // [{ text, id, highlighted }]
    property real progress: -1            // 0..1 이면 진행 막대, −1 이면 없음
    signal triggered(string id)
    signal dismissed()

    height: Theme.controlHeight + Theme.padding * 2
    color: Theme.surfaceRaised
    Accessible.role: Accessible.AlertMessage
    Accessible.name: text
    MSeparator { anchors.top: parent.top }
    MSeparator { anchors.bottom: parent.bottom }
    Rectangle { width: Theme.selectionMarkerWidth; height: parent.height; color: bar.kind === "warn" ? Theme.warning : Theme.accent }
    Row {
        id: left
        x: Theme.paddingLarge; anchors.verticalCenter: parent.verticalCenter; spacing: Theme.padding
        width: parent.width - x - right.width - Theme.paddingLarge * 2
        MIcon { name: bar.icon; size: 20; anchors.verticalCenter: parent.verticalCenter; light: Theme.isDark(Theme.surfaceRaised) }
        Column { width: parent.width - 20 - Theme.padding; anchors.verticalCenter: parent.verticalCenter; spacing: 4
            MLabel { text: bar.text; width: parent.width; font.pixelSize: Theme.fontSizeSmall }
            MProgressBar { visible: bar.progress >= 0; width: Math.min(parent.width, 320); height: 6; value: Math.max(0, bar.progress) }
        }
    }
    Row {
        id: right
        anchors.right: parent.right; anchors.rightMargin: Theme.padding; anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.padding
        Repeater {
            model: bar.actions
            MButton { required property var modelData; text: modelData.text; defaultButton: modelData.highlighted === true
                      onClicked: bar.triggered(modelData.id) }
        }
        MButton { flat: true; text: "×"; hPad: 8; onDark: Theme.isDark(Theme.surfaceRaised); Accessible.name: qsTr("닫기"); onClicked: bar.dismissed() }
    }
}
