import QtQuick
import HagraUI 1.0

// 슬라이더. 값: from..to, stepSize 로 양자화. ←/→(step), PageUp/Down(10 step), Home/End. 포커스 = 손잡이 바깥 링. moved(value) 는 사용자 조작에서만.
Item {
    id: slider
    property real from: 0
    property real to: 100
    property real value: 0
    property real stepSize: 1
    property bool live: true           // 끌면서 moved 를 낼지 (false: 놓을 때만)
    property string valueText: ""      // 오른쪽 표시 (예: "45%"). 비우면 숨김
    signal moved(real value)

    implicitWidth: 240
    implicitHeight: Theme.controlHeight
    activeFocusOnTab: enabled
    Accessible.role: Accessible.Slider
    Accessible.name: valueText.length ? valueText : String(value)

    readonly property real span: Math.max(0.000001, to - from)
    readonly property int labelW: valueText.length ? Math.max(40, label.implicitWidth + Theme.padding) : 0
    readonly property int trackW: width - labelW - handle.width
    function quantize(v) { var q = Math.round((v - from) / stepSize) * stepSize + from; return Math.max(from, Math.min(to, q)) }
    function setFromX(px) { var v = from + (px - handle.width / 2) / trackW * span; var q = quantize(v); if (q !== value) { value = q; if (live) moved(q) } }
    function step(n) { var q = quantize(value + n * stepSize); if (q !== value) { value = q; moved(q) } }
    Keys.onLeftPressed: step(-1)
    Keys.onRightPressed: step(1)
    Keys.onPressed: (ev) => {
        if (ev.key === Qt.Key_PageUp) { step(10); ev.accepted = true }
        else if (ev.key === Qt.Key_PageDown) { step(-10); ev.accepted = true }
        else if (ev.key === Qt.Key_Home) { value = from; moved(value); ev.accepted = true }
        else if (ev.key === Qt.Key_End) { value = to; moved(value); ev.accepted = true }
    }

    Rectangle { // 트랙
        id: track
        x: handle.width / 2; anchors.verticalCenter: parent.verticalCenter
        width: slider.trackW; height: 6; radius: 3
        color: slider.enabled ? Theme.surfaceRaised : "transparent"; border.width: 1; border.color: slider.enabled ? Theme.border : Theme.textDisabled
        Rectangle { // 채움
            height: parent.height; radius: 3
            width: Math.max(0, Math.min(parent.width, (slider.value - slider.from) / slider.span * parent.width))
            color: slider.enabled ? Theme.accent : Theme.textDisabled
        }
    }
    Rectangle { // 손잡이
        id: handle
        width: 20; height: 20; radius: 10
        anchors.verticalCenter: parent.verticalCenter
        x: (slider.value - slider.from) / slider.span * slider.trackW
        color: !slider.enabled ? Theme.surfaceRaised : (mouse.pressed ? Theme.selection : (mouse.containsMouse ? Theme.surfaceRaised : Theme.surface))
        border.width: 2; border.color: slider.enabled ? Theme.accent : Theme.textDisabled
        Rectangle { visible: slider.activeFocus; anchors.fill: parent; anchors.margins: -(Theme.focusRingWidth + 1); radius: width / 2
                    color: "transparent"; border.width: Theme.focusRingWidth; border.color: Theme.focusRing }
    }
    MouseArea {
        id: mouse
        anchors.left: parent.left; anchors.right: label.left; anchors.top: parent.top; anchors.bottom: parent.bottom
        hoverEnabled: true; enabled: slider.enabled
        onPressed: (e) => { slider.forceActiveFocus(); slider.setFromX(e.x) }
        onPositionChanged: (e) => { if (pressed) slider.setFromX(e.x) }
        onReleased: { if (!slider.live) slider.moved(slider.value) }
    }
    MLabel { id: label; visible: slider.valueText.length > 0; text: slider.valueText; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
             width: slider.labelW; horizontalAlignment: Text.AlignRight; font.pixelSize: Theme.fontSizeSmall; muted: !slider.enabled }
}
