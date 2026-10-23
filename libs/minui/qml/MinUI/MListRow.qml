import QtQuick
import MinUI 1.0

// 목록 행. selected 는 accent 배경, hover 는 surfaceRaised.
Rectangle {
    id: row
    property string text: ""
    property string detail: ""
    property bool selected: false
    property alias hovered: mouse.containsMouse
    signal clicked()
    signal doubleClicked()

    width: parent ? parent.width : implicitWidth
    implicitHeight: Theme.rowHeight
    radius: Theme.radius
    color: selected ? Theme.accent : (mouse.containsMouse ? Theme.surfaceRaised : "transparent")

    Row {
        anchors.fill: parent
        anchors.leftMargin: Theme.paddingLarge
        anchors.rightMargin: Theme.paddingLarge
        spacing: Theme.paddingLarge
        Text {
            height: parent.height
            text: row.text
            color: row.selected ? Theme.accentText : Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            renderType: Text.NativeRendering
            width: Math.min(implicitWidth, row.width - Theme.paddingLarge * 2)
        }
        Text {
            height: parent.height
            visible: row.detail.length > 0
            text: row.detail
            color: row.selected ? Theme.accentText : Theme.textMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            renderType: Text.NativeRendering
            width: Math.max(0, row.width - Theme.paddingLarge * 3 - parent.children[0].width)
        }
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: row.clicked()
        onDoubleClicked: row.doubleClicked()
    }
}
