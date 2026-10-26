// 작업 표시줄 창 항목: 아이콘 + 제목 + 닫기. 활성 창 = 선택 배경 + 굵은 제목 + 하단 3px 막대 (색 이외 단서), 최소화 = 흐린 기울임.
import QtQuick
import HagraUI 1.0

Rectangle {
    id: task
    required property int index
    required property string title
    required property string appId
    required property bool activated
    required property bool minimized
    signal clicked()
    signal closeRequested()
    signal middleClicked()

    // 앱 식별자 → 아이콘 (앱 자체 아이콘은 M2 이후; 지금은 종류별 기호)
    function iconFor(id) {
        var s = (id || "").toLowerCase()
        if (s.indexOf("foot") >= 0 || s.indexOf("term") >= 0) return "terminal"
        if (s.indexOf("files") >= 0) return "folder"
        if (s.indexOf("settings") >= 0) return "settings"
        if (s.indexOf("hagra") >= 0 || s.indexOf("hagra") >= 0 || s.indexOf("preview") >= 0) return "lotus"
        return "window"
    }

    readonly property bool dark: Theme.isDark(Theme.panel)
    readonly property bool lit: activated || mouse.pressed     // 선택 배경 위 (밝음) → 짙은 전경
    readonly property color fg: lit ? Theme.selectionText : Theme.panelText
    width: Math.min(220, Math.max(140, row.implicitWidth + Theme.padding * 2))
    height: Theme.controlHeight
    radius: Theme.radius
    color: !enabled ? "transparent"
         : mouse.pressed ? Theme.selection
         : activated ? Theme.selection
         : mouse.containsMouse ? (dark ? Qt.rgba(Theme.panelText.r, Theme.panelText.g, Theme.panelText.b, 0.14) : Theme.surfaceRaised)
         : (dark ? "transparent" : Theme.surface)
    border.width: Theme.borderWidth
    border.color: activated ? (dark ? Theme.ochre : Theme.borderStrong) : (dark ? Theme.panelMuted : Theme.border)

    Rectangle { // 활성 표시 막대
        visible: task.activated
        anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right
        anchors.margins: Theme.borderWidth
        height: Theme.selectionMarkerWidth; color: task.dark ? Theme.ochre : Theme.accent
    }
    Row {
        id: row
        anchors.fill: parent
        anchors.leftMargin: Theme.padding
        anchors.rightMargin: Theme.padding
        spacing: Theme.padding
        MIcon { name: task.iconFor(task.appId); size: 20; anchors.verticalCenter: parent.verticalCenter; opacity: task.minimized ? 0.5 : 1; light: task.dark && !task.lit }
        MLabel {
            width: task.width - Theme.padding * 2 - 20 - Theme.padding * 2 - closeBtn.width
            height: parent.height
            text: task.title.length ? task.title : task.appId
            font.bold: task.activated
            textColor: task.fg
            mutedColor: task.lit ? Theme.selectionText : (task.dark ? Theme.panelMuted : Theme.textMuted)
            muted: task.minimized
            font.italic: task.minimized
            elide: Text.ElideRight
        }
        MButton {
            id: closeBtn
            flat: true; icon: "close"; hPad: 2
            onDark: task.dark && !task.lit
            width: 22; height: 22
            anchors.verticalCenter: parent.verticalCenter
            onClicked: task.closeRequested()
            MToolTip { text: "창 닫기" }
        }
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        anchors.rightMargin: closeBtn.width + Theme.padding
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: (ev) => { if (ev.button === Qt.MiddleButton) { task.middleClicked(); task.closeRequested() } else task.clicked() }
    }
    MToolTip { text: task.title }
}
