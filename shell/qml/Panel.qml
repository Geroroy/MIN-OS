// 하그라 셸 — 작업 표시줄 (화면 하단, layer-shell bottom, exclusive zone)
// 높이 = Theme.panelHeight(52) = 장식 띠 8(compact MOrnamentBand) + 경계 1 + 콘텐츠 43 (컨트롤 36 을 세로 중앙에).
// 장식 띠는 입력을 받지 않고 콘텐츠 영역을 침범하지 않는다 (DESIGN_SPEC "하단 패널: 얇은 반복 띠").
import QtQuick
import QtQuick.Layouts
import HagraLayerShell 1.0
import HagraUI 1.0
import HagraShell 1.0

LayerWindow {
    id: panel
    property bool launcherOpen: false
    property bool powerOpen: false
    signal launcherRequested()
    signal powerRequested()

    readonly property int bandHeight: Theme.panelBandHeight
    readonly property int contentY: bandHeight + Theme.borderWidth
    readonly property int contentHeight: height - contentY

    scope: "hagra-panel"
    layer: LayerWindow.Bottom
    anchors: LayerWindow.AnchorLeft | LayerWindow.AnchorRight | LayerWindow.AnchorBottom
    exclusiveZone: Theme.panelHeight
    keyboardInteractivity: LayerWindow.KeyboardNone
    width: Screen.width > 0 ? Screen.width : 1280   // 좌우 앵커이므로 컴포지터 configure 가 최종 폭을 정한다
    height: Theme.panelHeight
    color: Theme.panel
    visible: true
    readonly property bool dark: Theme.isDark(Theme.panel)

    // 상단 장식 띠 (8px 축소형) + 경계선
    MOrnamentBand { compact: true; anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right }
    Rectangle { y: panel.bandHeight; width: parent.width; height: Theme.borderWidth; color: panel.dark ? Theme.ochre : Theme.borderStrong }

    RowLayout {
        y: panel.contentY
        width: parent.width
        height: panel.contentHeight
        spacing: 0

        // 시작 버튼: 연꽃 + 표시 이름
        MButton {
            id: startButton
            text: Theme.brandName
            icon: "lotus"
            bold: true
            flat: true
            onDark: panel.dark
            highlighted: panel.launcherOpen
            hPad: 12
            Layout.preferredHeight: Theme.controlHeight
            Layout.leftMargin: Theme.padding
            Layout.rightMargin: Theme.padding
            Layout.alignment: Qt.AlignVCenter
            onClicked: panel.launcherRequested()
            MToolTip { text: qsTr("실행 메뉴 (") + Theme.brandName + ")" }
        }
        MSeparator { vertical: true; Layout.preferredHeight: Theme.controlHeight; Layout.alignment: Qt.AlignVCenter; color: panel.dark ? Theme.panelMuted : Theme.border }

        // 창 목록
        ListView {
            id: tasks
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: Theme.padding
            orientation: ListView.Horizontal
            spacing: Theme.padding
            clip: true
            interactive: false
            model: Toplevels
            delegate: TaskButton {
                anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                onClicked: Toplevels.toggle(index)
                onCloseRequested: Toplevels.close(index)
            }
        }

        MSeparator { vertical: true; Layout.preferredHeight: Theme.controlHeight; Layout.alignment: Qt.AlignVCenter; color: panel.dark ? Theme.panelMuted : Theme.border }

        // 시계: 날짜·요일·시각은 런타임 로케일 시계에서 읽는다 (고정 문자열 없음)
        MLabel {
            id: clock
            Layout.fillHeight: true
            Layout.leftMargin: Theme.paddingLarge
            Layout.rightMargin: Theme.paddingLarge
            horizontalAlignment: Text.AlignHCenter
            textColor: Theme.panelText
            property bool showFull: false
            readonly property var ko: Qt.locale()   // 시스템 로케일 (LANG); 형식 문자열은 번역 파일에서 언어별로 바뀐다
            function refresh() {
                var now = new Date()
                text = showFull ? now.toLocaleString(ko, qsTr("yyyy년 M월 d일 (ddd) AP h:mm:ss"))
                                : now.toLocaleString(ko, qsTr("M월 d일 (ddd) AP h:mm"))
            }
            Component.onCompleted: refresh()
            onShowFullChanged: refresh()
            Timer { interval: 1000; running: true; repeat: true; onTriggered: clock.refresh() }
            MouseArea { anchors.fill: parent; onClicked: clock.showFull = !clock.showFull }
        }
        MSeparator { vertical: true; Layout.preferredHeight: Theme.controlHeight; Layout.alignment: Qt.AlignVCenter; color: panel.dark ? Theme.panelMuted : Theme.border }

        // 전원
        MButton {
            id: powerButton
            flat: true
            icon: "power"
            onDark: panel.dark
            hPad: Theme.padding
            highlighted: panel.powerOpen
            Layout.preferredHeight: Theme.controlHeight
            Layout.leftMargin: Theme.padding
            Layout.rightMargin: Theme.padding
            Layout.alignment: Qt.AlignVCenter
            onClicked: panel.powerRequested()
            MToolTip { text: qsTr("전원") }
        }
    }
}
