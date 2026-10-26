import QtQuick
import HagraUI 1.0

// 라디오 버튼. 원형 표시는 아이콘 성격의 요소이므로 각진 컨트롤 규칙의 예외로 둔다.
Item {
    id: control
    property var group: null
    property string text: ""
    property bool error: false
    property var value: text
    readonly property bool checked: group ? group.current === control : false
    property alias hovered: mouse.containsMouse

    implicitWidth: mark.width + (label.visible ? Theme.paddingLarge + label.implicitWidth : 0)
    implicitHeight: Theme.controlHeight
    activeFocusOnTab: enabled
    Keys.onSpacePressed: if (enabled && group) group.select(control)

    Rectangle {
        id: mark
        width: 18; height: 18; radius: 9
        anchors.verticalCenter: parent.verticalCenter
        color: !control.enabled ? "transparent" : (mouse.containsMouse ? Theme.surfaceRaised : Theme.surface)
        border.width: Theme.borderWidth
        border.color: !control.enabled ? Theme.border : control.error ? Theme.danger : (control.checked || mouse.pressed) ? Theme.accent : Theme.borderStrong
        Rectangle { visible: control.activeFocus; anchors.fill: parent; anchors.margins: -(Theme.focusRingWidth + 1); radius: width / 2; color: "transparent"; border.width: Theme.focusRingWidth; border.color: Theme.focusRing }
        Rectangle { visible: control.checked; anchors.centerIn: parent; width: 8; height: 8; radius: 4; color: control.enabled ? Theme.accent : Theme.textDisabled }
    }
    Text {
        id: label
        visible: control.text.length > 0
        anchors.left: mark.right; anchors.leftMargin: Theme.paddingLarge; anchors.verticalCenter: parent.verticalCenter
        text: control.text
        color: !control.enabled ? Theme.textDisabled : control.error ? Theme.danger : Theme.text
        font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize; renderType: Text.NativeRendering
    }
    MouseArea { id: mouse; anchors.fill: parent; hoverEnabled: true; enabled: control.enabled
                onClicked: { if (control.group) control.group.select(control); control.forceActiveFocus() } }
}
