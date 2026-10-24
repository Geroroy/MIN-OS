import QtQuick

// 라디오 버튼 그룹: 하나만 선택되도록 관리한다. MRadioButton { group: someGroup }
QtObject {
    property var current: null
    signal changed(var button)
    function select(btn) { if (current !== btn) { current = btn; changed(btn) } }
}
