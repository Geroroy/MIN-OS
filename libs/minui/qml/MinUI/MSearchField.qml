import QtQuick
import MinUI 1.0

// 검색창: 입력란 + 검색 아이콘 + 지우기 버튼. Esc 로 비움.
MTextField {
    id: search
    placeholder: "검색"
    input.anchors.leftMargin: Theme.iconSize + Theme.padding * 2
    input.anchors.rightMargin: clear.visible ? clear.width + Theme.padding * 2 : Theme.padding + 2
    input.Keys.onEscapePressed: (ev) => { if (text.length) { text = ""; ev.accepted = true } }
    MIcon { name: "search"; size: Theme.iconSize; anchors.left: parent.left; anchors.leftMargin: Theme.padding; anchors.verticalCenter: parent.verticalCenter
            color: search.enabled ? Theme.textMuted : Theme.textDisabled }
    MButton {
        id: clear
        visible: search.text.length > 0
        flat: true; text: "×"; hPad: 4
        anchors.right: parent.right; anchors.rightMargin: 2; anchors.verticalCenter: parent.verticalCenter
        height: parent.height - 4
        onClicked: { search.text = ""; search.forceActiveFocus() }
    }
}
