import QtQuick
import MinUI 1.0

// 평면·각진 버튼. flat=true 는 테두리 없음(패널용). highlighted 는 활성 상태(하단 2px accent 선).
Rectangle {
    id: control
    property string text: ""
    property bool flat: false
    property bool highlighted: false
    property bool bold: false
    property bool danger: false
    property alias hovered: mouse.containsMouse
    property alias pressed: mouse.pressed
    property alias horizontalPadding: control.hPad
    property int hPad: Theme.paddingLarge
    signal clicked()

    implicitWidth: label.implicitWidth + hPad * 2
    implicitHeight: Theme.controlHeight
    radius: Theme.radius
    color: !enabled ? "transparent"
         : (mouse.pressed || highlighted || mouse.containsMouse) ? Theme.surfaceRaised
         : (flat ? "transparent" : Theme.surface)
    border.width: flat ? 0 : Theme.borderWidth
    border.color: mouse.pressed ? Theme.accent : (danger ? Theme.danger : Theme.borderStrong)

    activeFocusOnTab: true
    Keys.onReturnPressed: clicked()
    Keys.onEnterPressed: clicked()
    Keys.onSpacePressed: clicked()

    // 활성 표시
    Rectangle {
        visible: control.highlighted
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 2
        color: Theme.accent
    }
    // 포커스 링 (컨트롤 바깥 1px)
    Rectangle {
        visible: control.activeFocus
        anchors.fill: parent
        anchors.margins: -1
        color: "transparent"
        border.width: 1
        border.color: Theme.accent
    }
    Text {
        id: label
        anchors.centerIn: parent
        text: control.text
        color: !control.enabled ? Theme.textDisabled : (control.danger ? Theme.danger : Theme.text)
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        font.bold: control.bold
        renderType: Text.NativeRendering
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: control.enabled
        onClicked: control.clicked()
    }
}
