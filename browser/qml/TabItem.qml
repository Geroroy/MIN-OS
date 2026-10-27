// 탭 막대의 탭 하나: 사이트 아이콘 · 제목 · 닫기. 현재 탭 = 면 색 + 위쪽 2px 막대 + 굵은 글씨(색 이외 단서). 가운데 클릭으로 닫는다.
import QtQuick
import HagraUI 1.0

Rectangle {
    id: tab
    property var view: null
    property bool current: false
    signal activated()
    signal closeRequested()

    color: current ? Theme.surface : mouse.containsMouse ? Theme.surfaceRaised : "transparent"
    Accessible.role: Accessible.PageTab
    Accessible.name: view ? view.displayTitle : ""
    Accessible.selected: current

    Rectangle { visible: tab.current; width: parent.width; height: 2; color: Theme.accent }
    MSeparator { vertical: true; anchors.right: parent.right; height: parent.height - Theme.padding; anchors.verticalCenter: parent.verticalCenter; visible: !tab.current }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: function(ev) { if (ev.button === Qt.MiddleButton) tab.closeRequested(); else tab.activated() }
    }
    Image {
        id: favicon
        x: Theme.padding; anchors.verticalCenter: parent.verticalCenter
        width: 16; height: 16; sourceSize: Qt.size(32, 32)
        source: tab.view && !tab.view.showStart && tab.view.icon ? tab.view.icon : ""
        visible: status === Image.Ready
        smooth: true
    }
    readonly property bool dark: Theme.isDark(current ? Theme.surface : Theme.bg)
    MIcon { visible: !favicon.visible; x: Theme.padding; anchors.verticalCenter: parent.verticalCenter; size: 16; light: tab.dark
            name: tab.view && tab.view.showStart ? "home" : "globe" }
    MLabel {
        anchors.left: favicon.right; anchors.leftMargin: Theme.padding
        anchors.right: close.left; anchors.rightMargin: 2
        anchors.verticalCenter: parent.verticalCenter
        text: tab.view ? tab.view.displayTitle : ""
        font.pixelSize: Theme.fontSizeSmall; font.bold: tab.current
        muted: !tab.current
    }
    MButton {
        id: close
        flat: true; text: "×"; hPad: 6; onDark: tab.dark
        height: parent.height - Theme.padding; anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right; anchors.rightMargin: 4
        visible: tab.current || mouse.containsMouse || hovered || tab.width > 140
        activeFocusOnTab: false
        Accessible.name: qsTr("탭 닫기")
        onClicked: tab.closeRequested()
    }
    MBusyBar { visible: tab.view && tab.view.loading; anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom }
}
