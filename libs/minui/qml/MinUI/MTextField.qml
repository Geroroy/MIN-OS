import QtQuick
import MinUI 1.0

// 한 줄 입력란. 1px 테두리, 포커스 시 accent 테두리.
Rectangle {
    id: control
    property alias text: input.text
    property string placeholder: ""
    property alias input: input
    signal accepted()

    implicitHeight: Theme.controlHeight
    implicitWidth: 160
    radius: Theme.radius
    color: Theme.bg
    border.width: Theme.borderWidth
    border.color: input.activeFocus ? Theme.accent : Theme.borderStrong

    function forceActiveFocus() { input.forceActiveFocus() }

    TextInput {
        id: input
        anchors.fill: parent
        anchors.leftMargin: Theme.padding + 2
        anchors.rightMargin: Theme.padding + 2
        verticalAlignment: TextInput.AlignVCenter
        color: Theme.text
        selectionColor: Theme.accent
        selectedTextColor: Theme.accentText
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        clip: true
        renderType: Text.NativeRendering
        onAccepted: control.accepted()
    }
    Text {
        anchors.fill: input
        verticalAlignment: Text.AlignVCenter
        visible: input.text.length === 0 && !input.inputMethodComposing
        text: control.placeholder
        color: Theme.textMuted
        font: input.font
        renderType: Text.NativeRendering
    }
}
