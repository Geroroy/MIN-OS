// 소리 표시기 클릭 → 볼륨 팝업 (슬라이더 · 음소거 · 설정 열기)
import QtQuick
import HagraLayerShell 1.0
import HagraUI 1.0
import HagraShell 1.0

LayerWindow {
    id: pop
    scope: "hagra-audio"
    layer: LayerWindow.Overlay
    property bool panelAtTop: false
    anchors: LayerWindow.AnchorRight | (panelAtTop ? LayerWindow.AnchorTop : LayerWindow.AnchorBottom)
    keyboardInteractivity: LayerWindow.KeyboardExclusive
    width: 300
    height: col.implicitHeight + Theme.windowBorderWidth * 2
    color: Theme.surface
    visible: false
    function toggle() { visible = !visible }
    Rectangle { anchors.fill: parent; color: "transparent"; border.width: Theme.windowBorderWidth; border.color: Theme.borderStrong; z: 10 }
    Column {
        id: col
        anchors.fill: parent; anchors.margins: Theme.windowBorderWidth
        focus: true
        Keys.onEscapePressed: pop.visible = false
        MOrnamentBand { width: parent.width }
        MSeparator { width: parent.width }
        Column { x: Theme.paddingLarge; width: parent.width - Theme.paddingLarge * 2; spacing: Theme.padding; topPadding: Theme.paddingLarge; bottomPadding: Theme.paddingLarge
            MLabel { text: qsTr("출력 볼륨"); font.bold: true }
            MSlider { id: vol; width: parent.width; from: 0; to: 100; stepSize: 5; value: Status.volume; valueText: Status.volume + "%"; live: false; enabled: !Status.muted
                      onMoved: (v) => Status.setVolume(v); focus: true }
            Item { width: parent.width; height: Theme.controlHeight
                MCheckBox { text: qsTr("음소거"); checked: Status.muted; onToggled: (c) => Status.setMuted(c); anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter }
                MButton { text: qsTr("소리 설정"); icon: "settings"; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; onClicked: { pop.visible = false; Shell.dispatch("settings:sound") } }
            }
        }
    }
    onVisibleChanged: if (visible) { Status.refresh(); vol.forceActiveFocus() }
}
