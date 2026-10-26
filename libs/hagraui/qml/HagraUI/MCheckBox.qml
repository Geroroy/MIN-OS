import QtQuick
import HagraUI 1.0

// 체크박스. Space 로 토글. 체크 표시는 글꼴에 의존하지 않도록 선으로 그린다.
Item {
    id: control
    property bool checked: false
    property string text: ""
    property bool error: false
    property alias hovered: mouse.containsMouse
    signal toggled(bool checked)

    implicitWidth: box.width + (label.visible ? Theme.paddingLarge + label.implicitWidth : 0)
    implicitHeight: Theme.controlHeight
    activeFocusOnTab: enabled
    Accessible.role: Accessible.CheckBox
    Accessible.name: text
    Accessible.checkable: true
    Accessible.checked: checked
    Accessible.onToggleAction: if (enabled) { checked = !checked; toggled(checked) }
    Keys.onSpacePressed: if (enabled) { checked = !checked; toggled(checked) }

    Rectangle {
        id: box
        width: 18; height: 18
        anchors.verticalCenter: parent.verticalCenter
        radius: Theme.radius
        color: !control.enabled ? "transparent" : control.checked ? Theme.accent : (mouse.containsMouse ? Theme.surfaceRaised : Theme.surface)
        border.width: Theme.borderWidth
        border.color: !control.enabled ? Theme.border : control.error ? Theme.danger : mouse.pressed ? Theme.accent : (control.checked ? Theme.accent : Theme.borderStrong)
        Rectangle { visible: control.activeFocus; anchors.fill: parent; anchors.margins: -(Theme.focusRingWidth + 1); color: "transparent"; border.width: Theme.focusRingWidth; border.color: Theme.focusRing }
        // 체크 표시: 두 선
        Rectangle { visible: control.checked; x: 4; y: 9; width: 5; height: 2; rotation: 45; transformOrigin: Item.Left; color: control.enabled ? Theme.accentText : Theme.textDisabled }
        Rectangle { visible: control.checked; x: 7.4; y: 12.4; width: 9; height: 2; rotation: -50; transformOrigin: Item.Left; color: control.enabled ? Theme.accentText : Theme.textDisabled }
    }
    Text {
        id: label
        visible: control.text.length > 0
        anchors.left: box.right; anchors.leftMargin: Theme.paddingLarge; anchors.verticalCenter: parent.verticalCenter
        text: control.text
        color: !control.enabled ? Theme.textDisabled : control.error ? Theme.danger : Theme.text
        font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize; renderType: Text.NativeRendering
    }
    MouseArea { id: mouse; anchors.fill: parent; hoverEnabled: true; enabled: control.enabled
                onClicked: { control.checked = !control.checked; control.toggled(control.checked); control.forceActiveFocus() } }
}
