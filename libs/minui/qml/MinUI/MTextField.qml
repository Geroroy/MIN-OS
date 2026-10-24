import QtQuick
import MinUI 1.0

// 한 줄 입력란. 상태: 기본 · 호버 · 포커스(테두리 accent + 링) · 비활성 · 오류 · 진행 중 · 한글 조합 중(오른쪽 표시)
Rectangle {
    id: control
    property alias text: input.text
    property string placeholder: ""
    property alias input: input
    property bool error: false
    property bool busy: false
    property string errorText: ""
    property alias readOnly: input.readOnly
    property alias echoMode: input.echoMode
    readonly property bool composing: input.inputMethodComposing
    signal accepted()

    implicitHeight: Theme.controlHeight
    implicitWidth: 160
    radius: Theme.radius
    color: enabled ? Theme.bg : "transparent"
    border.width: Theme.borderWidth
    border.color: !enabled ? Theme.border : error ? Theme.danger : input.activeFocus ? Theme.accent : (hover.hovered ? Theme.textMuted : Theme.borderStrong)

    function forceActiveFocus() { input.forceActiveFocus() }
    onActiveFocusChanged: if (activeFocus && !input.activeFocus) input.forceActiveFocus()

    HoverHandler { id: hover; enabled: control.enabled }
    Rectangle { // 포커스 링
        visible: input.activeFocus
        anchors.fill: parent; anchors.margins: -(Theme.focusRingWidth + 1)
        color: "transparent"; border.width: Theme.focusRingWidth; border.color: Theme.focusRing
    }
    TextInput {
        id: input
        anchors.fill: parent
        anchors.leftMargin: Theme.padding + 2
        anchors.rightMargin: (badge.visible ? badge.width + Theme.padding : 0) + Theme.padding + 2
        verticalAlignment: TextInput.AlignVCenter
        enabled: control.enabled
        color: control.enabled ? Theme.text : Theme.textDisabled
        selectionColor: Theme.selection
        selectedTextColor: Theme.selectionText
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
    Text { // 오류 배지 / 조합 중 표시
        id: badge
        anchors.right: parent.right; anchors.rightMargin: Theme.padding
        anchors.verticalCenter: parent.verticalCenter
        visible: control.error || control.composing
        text: control.error ? "!" : "한"
        color: control.error ? Theme.danger : Theme.textMuted
        font.pixelSize: Theme.fontSizeSmall; font.bold: control.error; renderType: Text.NativeRendering
    }
    MBusyBar { visible: control.busy; anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom }
    Text { // 오류 메시지 (입력란 아래)
        visible: control.error && control.errorText.length > 0
        anchors.top: parent.bottom; anchors.topMargin: 2; anchors.left: parent.left
        text: control.errorText; color: Theme.danger; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily; renderType: Text.NativeRendering
    }
}
