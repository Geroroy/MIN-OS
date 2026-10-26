// 하그라 셸 — 작업 표시줄 (layer-shell, exclusive zone). 화면마다 하나 (Main.qml 의 Instantiator), 위치는 panel.conf (bottom|top).
// 높이 = Theme.panelHeight(52) = 장식 띠 8(compact MOrnamentBand) + 경계 1 + 콘텐츠 43 (컨트롤 36 을 세로 중앙에).
// 띠는 화면 안쪽 가장자리(아래 패널이면 위, 위 패널이면 아래)에 놓이고 입력을 받지 않는다.
// 구성: 시작 · 창 목록 · 표시기(네트워크·소리·배터리·알림) · 시계 · 전원. 표시기는 백엔드가 없으면 숨긴다 (거짓 버튼 없음).
import QtQuick
import QtQuick.Layouts
import HagraLayerShell 1.0
import HagraUI 1.0
import HagraShell 1.0

LayerWindow {
    id: panel
    property bool launcherOpen: false
    property bool powerOpen: false
    property bool notificationsOpen: false
    property bool calendarOpen: false
    property bool audioOpen: false
    property bool atTop: false
    property bool clockSeconds: false
    signal launcherRequested()
    signal powerRequested()
    signal notificationsRequested()
    signal calendarRequested()
    signal audioRequested()
    signal taskMenuRequested(int row, real x)

    readonly property int bandHeight: Theme.panelBandHeight
    readonly property int contentY: atTop ? 0 : bandHeight + Theme.borderWidth
    readonly property int contentHeight: height - bandHeight - Theme.borderWidth

    scope: "hagra-panel"
    layer: LayerWindow.Bottom
    anchors: LayerWindow.AnchorLeft | LayerWindow.AnchorRight | (atTop ? LayerWindow.AnchorTop : LayerWindow.AnchorBottom)
    exclusiveZone: Theme.panelHeight
    keyboardInteractivity: LayerWindow.KeyboardNone
    width: Screen.width > 0 ? Screen.width : 1280   // 좌우 앵커이므로 컴포지터 configure 가 최종 폭을 정한다
    height: Theme.panelHeight
    color: Theme.panel
    visible: true
    readonly property bool dark: Theme.isDark(Theme.panel)

    // 장식 띠 + 경계선 (아래 패널: 위쪽 가장자리 / 위 패널: 아래쪽 가장자리)
    MOrnamentBand { compact: true; anchors.left: parent.left; anchors.right: parent.right; y: panel.atTop ? panel.height - panel.bandHeight : 0 }
    Rectangle { y: panel.atTop ? panel.height - panel.bandHeight - Theme.borderWidth : panel.bandHeight; width: parent.width; height: Theme.borderWidth; color: panel.dark ? Theme.ochre : Theme.borderStrong }

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
            Accessible.name: qsTr("실행 메뉴")
            MToolTip { text: qsTr("실행 메뉴 (") + Theme.brandName + ") — Super+Space" }
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
                onMenuRequested: (lx) => panel.taskMenuRequested(index, x + lx + tasks.x + Theme.padding - tasks.contentX)
            }
        }

        MSeparator { vertical: true; Layout.preferredHeight: Theme.controlHeight; Layout.alignment: Qt.AlignVCenter; color: panel.dark ? Theme.panelMuted : Theme.border }

        // 표시기: 네트워크 · 소리 · 배터리 · 알림 (백엔드 없는 것은 숨김)
        Row {
            id: indicators
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: Theme.padding
            Layout.rightMargin: Theme.padding
            spacing: 2
            MButton {
                flat: true; onDark: panel.dark; hPad: 6
                icon: Status.networkKind === "wifi" ? "network" : Status.networkKind === "ethernet" ? "ethernet" : "network-off"
                height: Theme.controlHeight; anchors.verticalCenter: parent.verticalCenter
                onClicked: Shell.dispatch("settings:network")
                Accessible.name: Status.online ? qsTr("네트워크 연결됨") : qsTr("네트워크 끊김")
                MToolTip { text: Status.online ? (Status.networkKind === "wifi" ? qsTr("Wi-Fi ") + (Status.wifiSignal >= 0 ? Status.wifiSignal + "% · " : "") : qsTr("유선 ")) + Status.networkIface + (Status.networkAddress.length ? " · " + Status.networkAddress : "")
                                               : qsTr("네트워크 연결 없음 — 클릭하면 네트워크 설정") }
            }
            MButton {
                visible: Status.audioAvailable
                flat: true; onDark: panel.dark; hPad: 6
                icon: Status.muted ? "speaker-muted" : "speaker"
                highlighted: panel.audioOpen
                height: Theme.controlHeight; anchors.verticalCenter: parent.verticalCenter
                onClicked: panel.audioRequested()
                Accessible.name: qsTr("소리 ") + (Status.muted ? qsTr("음소거") : Status.volume + "%")
                MToolTip { text: Status.muted ? qsTr("음소거") : qsTr("볼륨 ") + Status.volume + "%" }
            }
            MButton {
                visible: Status.batteryPresent
                flat: true; onDark: panel.dark; hPad: 6
                icon: Status.charging ? "battery-charging" : "battery"
                text: Status.batteryPercent >= 0 ? Status.batteryPercent + "%" : ""
                height: Theme.controlHeight; anchors.verticalCenter: parent.verticalCenter
                onClicked: Shell.dispatch("settings:power")
                Accessible.name: qsTr("배터리 ") + Status.batteryPercent + "%" + (Status.charging ? qsTr(" 충전 중") : "")
                MToolTip { text: qsTr("배터리 ") + Status.batteryPercent + "%" + (Status.charging ? qsTr(" · 충전 중") : qsTr(" · 배터리 사용 중")) }
            }
            MButton {
                id: bellButton
                flat: true; onDark: panel.dark; hPad: 6
                icon: Notifications.doNotDisturb ? "bell-off" : "bell"
                highlighted: panel.notificationsOpen
                height: Theme.controlHeight; anchors.verticalCenter: parent.verticalCenter
                onClicked: panel.notificationsRequested()
                Accessible.name: qsTr("알림 ") + Notifications.unread
                MToolTip { text: (Notifications.unread > 0 ? qsTr("새 알림 %1개").arg(Notifications.unread) : qsTr("알림")) + (Notifications.doNotDisturb ? qsTr(" · 방해 금지") : "") + " — Super+N" }
                Rectangle { // 읽지 않은 수 배지
                    visible: Notifications.unread > 0
                    anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 2
                    width: Math.max(16, badge.implicitWidth + 6); height: 16; radius: 8; color: Theme.danger
                    MLabel { id: badge; anchors.centerIn: parent; text: Notifications.unread > 99 ? "99+" : Notifications.unread; color: "#FFFFFF"; font.pixelSize: 10; font.bold: true; lineHeight: 1.0 }
                }
            }
        }
        MSeparator { vertical: true; Layout.preferredHeight: Theme.controlHeight; Layout.alignment: Qt.AlignVCenter; color: panel.dark ? Theme.panelMuted : Theme.border }

        // 시계: 로케일 형식 (번역 파일이 언어별 형식을 준다). 초 표시는 panel.conf. 클릭 = 달력.
        MButton {
            id: clock
            flat: true; onDark: panel.dark; hPad: Theme.paddingLarge
            highlighted: panel.calendarOpen
            Layout.preferredHeight: Theme.controlHeight
            Layout.alignment: Qt.AlignVCenter
            readonly property var loc: Qt.locale()
            function refresh() {
                var now = new Date()
                text = panel.clockSeconds ? now.toLocaleString(loc, qsTr("yyyy년 M월 d일 (ddd) AP h:mm:ss"))
                                          : now.toLocaleString(loc, qsTr("M월 d일 (ddd) AP h:mm"))
            }
            Component.onCompleted: refresh()
            // 초를 보이지 않을 때는 분이 바뀌는 순간에만 깨어난다 (유휴 CPU)
            Timer { id: clockTimer; interval: 1000; running: true; repeat: true
                    onTriggered: { clock.refresh(); if (!panel.clockSeconds) interval = Math.max(250, (60 - new Date().getSeconds()) * 1000); else interval = 1000 } }
            onClicked: panel.calendarRequested()
            Accessible.name: qsTr("시계 ") + text
            MToolTip { text: new Date().toLocaleDateString(clock.loc, Locale.LongFormat) }
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
            Accessible.name: qsTr("전원")
            MToolTip { text: qsTr("전원") + " — Super+Esc" }
        }
    }
    onClockSecondsChanged: { clockTimer.interval = 1000; clock.refresh() }
}
