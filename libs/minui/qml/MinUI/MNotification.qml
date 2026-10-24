import QtQuick
import MinUI 1.0

// 알림 카드 (셸이 소유하는 UI; 여기서는 시각 부품만). 앱 이름·제목·본문·동작 버튼·닫기.
Rectangle {
    id: card
    property string appName: ""
    property string title: ""
    property string body: ""
    property var actions: []        // [{text}]
    property bool urgent: false
    signal actionClicked(int index)
    signal closed()
    implicitWidth: 320
    implicitHeight: col.implicitHeight + Theme.paddingLarge * 2
    color: Theme.surface
    border.width: Theme.borderWidth; border.color: urgent ? Theme.warning : Theme.borderStrong
    Rectangle { visible: card.urgent; anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom; width: Theme.selectionMarkerWidth; color: Theme.warning }
    Column {
        id: col
        anchors.fill: parent; anchors.margins: Theme.paddingLarge
        spacing: Theme.padding
        Item { width: parent.width; height: Theme.rowHeight
            MLabel { text: card.appName; muted: true; font.pixelSize: Theme.fontSizeSmall; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter }
            MButton { flat: true; text: "×"; hPad: 4; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; height: Theme.rowHeight; onClicked: card.closed() } }
        MLabel { text: card.title; font.bold: true; width: parent.width; visible: text.length > 0 }
        MLabel { text: card.body; wrap: true; width: parent.width; visible: text.length > 0 }
        Row { spacing: Theme.padding; visible: card.actions.length > 0
            Repeater { model: card.actions; delegate: MButton { required property int index; required property var modelData; text: modelData.text; onClicked: card.actionClicked(index) } } }
    }
}
