// 작업 표시줄 창 항목
import QtQuick
import MinUI 1.0

Rectangle {
    id: task
    required property int index
    required property string title
    required property bool activated
    required property bool minimized
    signal clicked()
    signal middleClicked()

    width: 160
    height: parent ? parent.height : Theme.panelHeight
    color: mouse.pressed ? Theme.surfaceRaised : (activated || mouse.containsMouse) ? Theme.surfaceRaised : "transparent"

    Rectangle { // 오른쪽 구분선
        anchors.right: parent.right; width: 1; height: parent.height; color: Theme.border
    }
    Rectangle { // 활성 표시
        visible: task.activated
        anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right
        height: 2; color: Theme.accent
    }
    MLabel {
        anchors.fill: parent
        anchors.leftMargin: Theme.paddingLarge
        anchors.rightMargin: Theme.paddingLarge
        text: task.title
        muted: task.minimized
        font.italic: task.minimized
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: (ev) => { if (ev.button === Qt.MiddleButton) task.middleClicked(); else task.clicked() }
    }
}
