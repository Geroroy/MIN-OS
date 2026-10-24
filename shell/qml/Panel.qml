// MIN Shell — 작업 표시줄 (화면 하단, layer-shell bottom, exclusive zone)
import QtQuick
import QtQuick.Layouts
import MinLayerShell 1.0
import MinUI 1.0
import MinShell 1.0

LayerWindow {
    id: panel
    property bool launcherOpen: false
    signal launcherRequested()
    signal powerRequested()

    scope: "minos-panel"
    layer: LayerWindow.Bottom
    anchors: LayerWindow.AnchorLeft | LayerWindow.AnchorRight | LayerWindow.AnchorBottom
    exclusiveZone: Theme.panelHeight
    keyboardInteractivity: LayerWindow.KeyboardNone
    width: 1280
    height: Theme.panelHeight
    color: Theme.surface
    visible: true

    // 상단 1px 테두리
    Rectangle { anchors.top: parent.top; width: parent.width; height: Theme.borderWidth; color: Theme.border }

    RowLayout {
        anchors.fill: parent
        anchors.topMargin: Theme.borderWidth
        spacing: 0

        // 시작 버튼
        MButton {
            id: startButton
            text: Theme.brandName   // 임시: 브랜드 표기는 디자인 확정 후 결정
            bold: true
            flat: true
            highlighted: panel.launcherOpen
            hPad: 12
            Layout.fillHeight: true
            onClicked: panel.launcherRequested()
        }
        MSeparator { vertical: true; Layout.fillHeight: true }

        // 창 목록
        ListView {
            id: tasks
            Layout.fillWidth: true
            Layout.fillHeight: true
            orientation: ListView.Horizontal
            clip: true
            interactive: false
            model: Toplevels
            delegate: TaskButton {
                onClicked: Toplevels.toggle(index)
                onMiddleClicked: Toplevels.close(index)
            }
        }

        MSeparator { vertical: true; Layout.fillHeight: true }

        // 시계
        MLabel {
            id: clock
            Layout.fillHeight: true
            Layout.leftMargin: Theme.paddingLarge
            Layout.rightMargin: Theme.paddingLarge
            horizontalAlignment: Text.AlignHCenter
            property bool showDate: false
            text: showDate ? Qt.formatDateTime(new Date(), "yyyy-MM-dd ddd HH:mm") : Qt.formatTime(new Date(), "HH:mm")
            Timer {
                interval: 1000; running: true; repeat: true
                onTriggered: clock.text = clock.showDate ? Qt.formatDateTime(new Date(), "yyyy-MM-dd ddd HH:mm")
                                                        : Qt.formatTime(new Date(), "HH:mm")
            }
            MouseArea { anchors.fill: parent; onClicked: clock.showDate = !clock.showDate }
        }
        MSeparator { vertical: true; Layout.fillHeight: true }

        // 전원
        Rectangle {
            id: powerButton
            Layout.fillHeight: true
            implicitWidth: 32
            color: powerMouse.containsMouse ? Theme.surfaceRaised : "transparent"
            PowerIcon { anchors.centerIn: parent }
            MouseArea {
                id: powerMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: panel.powerRequested()
            }
        }
    }
}
