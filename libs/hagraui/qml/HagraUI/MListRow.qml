import QtQuick
import HagraUI 1.0

// 목록 행. 선택(selected) = selection 배경 + 왼쪽 3px 막대, 키보드 포커스(focusVisible) = 1px 링 (선택과 독립).
Rectangle {
    id: row
    property string text: ""
    property string detail: ""
    property string icon: ""
    property bool selected: false
    property bool focusVisible: false
    property alias hovered: mouse.containsMouse
    property int leftPadding: Theme.paddingLarge
    property bool onDark: false           // 어두운 사이드바 위: 전경 sidebarText, 호버 반투명, 포커스 링 focusRingOnDark
    readonly property color fg: onDark ? Theme.sidebarText : Theme.text
    readonly property color fgMuted: onDark ? Theme.sidebarText : Theme.textMuted
    signal clicked(var mouseEvent)
    signal doubleClicked()
    signal rightClicked(real x, real y)

    width: parent ? parent.width : implicitWidth
    implicitHeight: Theme.rowHeight
    radius: Theme.radius
    color: !enabled ? "transparent" : selected ? Theme.selection
         : mouse.containsMouse ? (onDark ? Qt.rgba(Theme.sidebarText.r, Theme.sidebarText.g, Theme.sidebarText.b, 0.14) : Theme.surfaceRaised) : "transparent"

    Rectangle { // 선택 막대 (색 이외 단서)
        visible: row.selected
        anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
        width: Theme.selectionMarkerWidth; color: row.onDark ? Theme.ochre : Theme.accent   // 어두운 사이드바에서는 accent 가 바탕과 같을 수 있다
    }
    Rectangle { // 포커스 링 (안쪽 1px)
        visible: row.focusVisible
        anchors.fill: parent
        color: "transparent"; border.width: Theme.focusRingWidth; border.color: row.onDark ? Theme.focusRingOnDark : Theme.focusRing; z: 5
    }
    Row {
        anchors.fill: parent
        anchors.leftMargin: row.leftPadding
        anchors.rightMargin: Theme.paddingLarge
        spacing: Theme.paddingLarge
        MIcon { visible: row.icon.length > 0; name: row.icon; anchors.verticalCenter: parent.verticalCenter
                light: row.onDark && !row.selected
                color: row.selected ? Theme.selectionText : (row.enabled ? row.fgMuted : Theme.textDisabled) }
        Text {
            id: main
            height: parent.height
            text: row.text
            color: !row.enabled ? Theme.textDisabled : row.selected ? Theme.selectionText : row.fg
            font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize
            verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight; renderType: Text.NativeRendering
            width: Math.min(implicitWidth, row.width - row.leftPadding - Theme.paddingLarge - (row.icon.length ? Theme.iconSize + Theme.paddingLarge : 0))
        }
        Text {
            height: parent.height
            visible: row.detail.length > 0
            text: row.detail
            color: !row.enabled ? Theme.textDisabled : row.selected ? Theme.selectionText : row.fgMuted
            font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSmall
            verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight; renderType: Text.NativeRendering
            width: Math.max(0, row.width - row.leftPadding - Theme.paddingLarge * 2 - main.width - (row.icon.length ? Theme.iconSize + Theme.paddingLarge : 0))
        }
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: row.enabled
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: (ev) => { if (ev.button === Qt.RightButton) row.rightClicked(ev.x, ev.y); else row.clicked(ev) }
        onDoubleClicked: row.doubleClicked()
    }
}
