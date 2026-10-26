import QtQuick
import HagraUI 1.0

// 툴팁. 부모 항목 위에 마우스를 600ms 머무르면 창 내용 최상단(Window.contentItem)에 표시한다.
// 제약: 창 밖으로 나갈 수 없다 (별도 xdg_popup 창은 후속 과제).
Item {
    id: tip
    property string text: ""
    property int delay: 600
    property Item target: parent
    visible: false
    Accessible.ignored: true
    HoverHandler { id: hover; parent: tip.target }
    Timer { id: timer; interval: tip.delay; onTriggered: tip.show() }
    onTargetChanged: hover.parent = target
    Connections { target: hover; function onHoveredChanged() { if (hover.hovered) timer.start(); else { timer.stop(); tip.hide() } } }
    property Item bubble: null
    function show() {
        if (!tip.target || tip.text.length === 0) return
        const root = tip.target.Window.contentItem
        if (!root) return
        if (!bubble) bubble = bubbleComponent.createObject(root)
        const p = tip.target.mapToItem(root, 0, tip.target.height + 4)
        bubble.text = tip.text
        bubble.x = Math.max(0, Math.min(root.width - bubble.width, p.x))
        bubble.y = p.y + bubble.height > root.height ? p.y - tip.target.height - 8 - bubble.height : p.y
        bubble.visible = true
    }
    function hide() { if (bubble) bubble.visible = false }
    Component {
        id: bubbleComponent
        Rectangle {
            property alias text: label.text
            z: 10000; visible: false
            width: label.implicitWidth + Theme.paddingLarge * 2; height: label.implicitHeight + Theme.padding * 2
            color: Theme.surface; border.width: Theme.borderWidth; border.color: Theme.borderStrong
            Text { id: label; anchors.centerIn: parent; width: Math.min(implicitWidth, Theme.tooltipMaxWidth); wrapMode: Text.Wrap
                   color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSmall; renderType: Text.NativeRendering }
        }
    }
}
