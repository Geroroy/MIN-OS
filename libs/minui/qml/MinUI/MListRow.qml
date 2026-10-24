import QtQuick
import MinUI 1.0

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
    signal clicked(var mouseEvent)
    signal doubleClicked()
    signal rightClicked(real x, real y)

    width: parent ? parent.width : implicitWidth
    implicitHeight: Theme.rowHeight
    radius: Theme.radius
    color: !enabled ? "transparent" : selected ? Theme.selection : (mouse.containsMouse ? Theme.surfaceRaised : "transparent")

    Rectangle { // 선택 막대 (색 이외 단서)
        visible: row.selected
        anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
        width: Theme.selectionMarkerWidth; color: Theme.accentText; opacity: 0.9
    }
    Rectangle { // 포커스 링 (안쪽 1px)
        visible: row.focusVisible
        anchors.fill: parent
        color: "transparent"; border.width: Theme.focusRingWidth; border.color: row.selected ? Theme.selectionText : Theme.focusRing
    }
    Row {
        anchors.fill: parent
        anchors.leftMargin: row.leftPadding
        anchors.rightMargin: Theme.paddingLarge
        spacing: Theme.paddingLarge
        MIcon { visible: row.icon.length > 0; name: row.icon; anchors.verticalCenter: parent.verticalCenter
                color: row.selected ? Theme.selectionText : (row.enabled ? Theme.textMuted : Theme.textDisabled) }
        Text {
            id: main
            height: parent.height
            text: row.text
            color: !row.enabled ? Theme.textDisabled : row.selected ? Theme.selectionText : Theme.text
            font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize
            verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight; renderType: Text.NativeRendering
            width: Math.min(implicitWidth, row.width - row.leftPadding - Theme.paddingLarge - (row.icon.length ? Theme.iconSize + Theme.paddingLarge : 0))
        }
        Text {
            height: parent.height
            visible: row.detail.length > 0
            text: row.detail
            color: !row.enabled ? Theme.textDisabled : row.selected ? Theme.selectionText : Theme.textMuted
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
