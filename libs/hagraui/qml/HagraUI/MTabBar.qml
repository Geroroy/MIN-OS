import QtQuick
import HagraUI 1.0

// 탭 막대. 현재 탭 = 하단 2px 막대 + 굵은 글씨(색 이외 단서). ←/→ 로 이동.
Item {
    id: bar
    property var tabs: []            // 문자열 배열
    property int currentIndex: 0
    signal activated(int index)
    implicitHeight: Theme.controlHeight + Theme.padding / 2
    implicitWidth: row.implicitWidth
    activeFocusOnTab: enabled
    Accessible.role: Accessible.PageTabList
    Accessible.name: tabs.length ? tabs[Math.max(0, Math.min(tabs.length - 1, currentIndex))] : ""
    Keys.onLeftPressed: if (currentIndex > 0) { currentIndex--; activated(currentIndex) }
    Keys.onRightPressed: if (currentIndex < tabs.length - 1) { currentIndex++; activated(currentIndex) }

    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: Theme.borderWidth; color: Theme.border }
    Row {
        id: row
        anchors.fill: parent
        Repeater {
            model: bar.tabs
            delegate: Rectangle {
                required property int index
                required property string modelData
                readonly property bool current: index === bar.currentIndex
                width: t.implicitWidth + Theme.paddingLarge * 2
                height: bar.height
                color: !bar.enabled ? "transparent" : (m.containsMouse && !current) ? Theme.surfaceRaised : "transparent"
                Rectangle { visible: current; anchors.bottom: parent.bottom; width: parent.width; height: 2; color: Theme.accent }
                Rectangle { visible: bar.activeFocus && current; anchors.fill: parent; anchors.margins: 1; color: "transparent"; border.width: Theme.focusRingWidth; border.color: Theme.focusRing }
                Text { id: t; anchors.centerIn: parent; text: modelData; font.bold: current
                       color: !bar.enabled ? Theme.textDisabled : current ? Theme.text : Theme.textMuted
                       font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize; renderType: Text.NativeRendering }
                MouseArea { id: m; anchors.fill: parent; hoverEnabled: true; enabled: bar.enabled
                            onClicked: { bar.currentIndex = index; bar.activated(index); bar.forceActiveFocus() } }
            }
        }
    }
}
