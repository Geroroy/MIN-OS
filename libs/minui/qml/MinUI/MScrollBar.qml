import QtQuick
import MinUI 1.0

// 세로 스크롤바. flickable 에 연결한다. 내용이 작으면 숨김.
Rectangle {
    id: bar
    property Flickable flickable: null
    readonly property real ratio: flickable && flickable.contentHeight > 0 ? flickable.height / flickable.contentHeight : 1
    visible: flickable && ratio < 1
    width: Theme.scrollBarWidth
    color: Theme.surfaceRaised
    border.width: 0
    Rectangle { anchors.left: parent.left; width: Theme.borderWidth; height: parent.height; color: Theme.border }
    Rectangle {
        id: thumb
        x: 2; width: parent.width - 4
        height: Math.max(20, bar.height * bar.ratio)
        y: flickable ? (flickable.contentY / Math.max(1, flickable.contentHeight - flickable.height)) * (bar.height - height) : 0
        color: drag.pressed ? Theme.accent : (drag.containsMouse ? Theme.textMuted : Theme.borderStrong)
        MouseArea {
            id: drag
            anchors.fill: parent; hoverEnabled: true
            property real startY; property real startContentY
            onPressed: (e) => { startY = e.y + thumb.y; startContentY = flickable.contentY }
            onPositionChanged: (e) => { if (pressed) {
                const dy = (e.y + thumb.y) - startY
                flickable.contentY = Math.max(0, Math.min(flickable.contentHeight - flickable.height, startContentY + dy * (flickable.contentHeight / bar.height))) } }
        }
    }
    MouseArea { // 트랙 클릭: 페이지 이동
        anchors.fill: parent; z: -1
        onClicked: (e) => { if (!flickable) return; const page = flickable.height * 0.9
            flickable.contentY = Math.max(0, Math.min(flickable.contentHeight - flickable.height, flickable.contentY + (e.y < thumb.y ? -page : page))) }
    }
}
