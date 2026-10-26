// 분절 선택 (2~4 개 중 하나). 현재 = 선택 배경 + 굵게 + 하단 막대. ←/→ 로 이동.
import QtQuick
import HagraUI 1.0

Row {
    id: choice
    property var options: []        // [{ id, label, icon? }]
    property string current: ""
    signal selected(string id)
    spacing: Theme.padding
    activeFocusOnTab: enabled
    Accessible.role: Accessible.RadioButton
    Keys.onLeftPressed: { var i = idx(); if (i > 0) selected(options[i - 1].id) }
    Keys.onRightPressed: { var i = idx(); if (i >= 0 && i < options.length - 1) selected(options[i + 1].id) }
    function idx() { for (var i = 0; i < options.length; ++i) if (options[i].id === current) return i; return -1 }
    Repeater {
        model: choice.options
        delegate: MButton {
            required property var modelData
            text: modelData.label; icon: modelData.icon || ""
            highlighted: modelData.id === choice.current
            enabled: choice.enabled && modelData.enabled !== false
            activeFocusOnTab: false
            onClicked: { choice.forceActiveFocus(); choice.selected(modelData.id) }
            Accessible.name: text + (highlighted ? " (선택됨)" : "")
        }
    }
    Rectangle { visible: choice.activeFocus; anchors.fill: parent; anchors.margins: -(Theme.focusRingWidth + 2); color: "transparent"; z: 5
                border.width: Theme.focusRingWidth; border.color: Theme.focusRing; radius: Theme.radius }
}
