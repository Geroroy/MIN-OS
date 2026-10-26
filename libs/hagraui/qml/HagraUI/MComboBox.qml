import QtQuick
import HagraUI 1.0

// 선택 목록 (드롭다운). model: 문자열 배열. 목록은 MMenu 로 창 안에 표시된다.
MButton {
    id: combo
    property var model: []
    property int currentIndex: 0
    property bool error: false
    readonly property string currentText: model && model.length > currentIndex && currentIndex >= 0 ? String(model[currentIndex]) : ""
    signal activated(int index)
    text: currentText + "   ▾"
    hPad: Theme.paddingLarge
    implicitWidth: Math.max(120, contentWidth)
    onClicked: list.open(combo, 0, combo.height + 2)
    Keys.onDownPressed: list.open(combo, 0, combo.height + 2)
    MMenu {
        id: list
        minWidth: combo.width
        items: (combo.model || []).map((m, i) => ({ text: String(m), checked: i === combo.currentIndex }))
        onTriggered: (i) => { combo.currentIndex = i; combo.activated(i) }
    }
    Binding { target: combo; property: "error"; value: combo.error }
}
