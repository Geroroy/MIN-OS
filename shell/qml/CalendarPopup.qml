// 시계 클릭 → 달력 팝업 (패널 위 오른쪽): 큰 시각 · 날짜 · 월 달력(오늘 표시, 이전/다음 달)
import QtQuick
import HagraLayerShell 1.0
import HagraUI 1.0

LayerWindow {
    id: cal
    scope: "hagra-calendar"
    layer: LayerWindow.Overlay
    property bool panelAtTop: false
    anchors: LayerWindow.AnchorRight | (panelAtTop ? LayerWindow.AnchorTop : LayerWindow.AnchorBottom)
    keyboardInteractivity: LayerWindow.KeyboardExclusive
    width: 320
    height: col.implicitHeight + Theme.windowBorderWidth * 2
    color: Theme.surface
    visible: false
    function toggle() { visible = !visible }
    readonly property var loc: Qt.locale()
    property date now: new Date()
    property int year: now.getFullYear()
    property int month: now.getMonth()      // 0..11
    function goMonth(d) { var m = month + d; if (m < 0) { m = 11; year-- } else if (m > 11) { m = 0; year++ } month = m }
    function daysModel() {
        var first = new Date(year, month, 1)
        var startDow = (first.getDay() - loc.firstDayOfWeek + 7) % 7
        var days = new Date(year, month + 1, 0).getDate()
        var out = []
        for (var i = 0; i < startDow; ++i) out.push({ day: 0 })
        for (var d = 1; d <= days; ++d) out.push({ day: d, today: d === now.getDate() && month === now.getMonth() && year === now.getFullYear(),
                                                   weekend: ((startDow + d - 1) % 7 + loc.firstDayOfWeek) % 7 === 0 || ((startDow + d - 1) % 7 + loc.firstDayOfWeek) % 7 === 6 })
        return out
    }
    Timer { interval: 1000; running: cal.visible; repeat: true; onTriggered: cal.now = new Date() }
    onVisibleChanged: if (visible) { now = new Date(); year = now.getFullYear(); month = now.getMonth(); col.forceActiveFocus() }

    Rectangle { anchors.fill: parent; color: "transparent"; border.width: Theme.windowBorderWidth; border.color: Theme.borderStrong; z: 10 }
    Column {
        id: col
        anchors.fill: parent; anchors.margins: Theme.windowBorderWidth
        focus: true
        Keys.onEscapePressed: cal.visible = false
        Keys.onLeftPressed: cal.goMonth(-1)
        Keys.onRightPressed: cal.goMonth(1)
        MOrnamentBand { width: parent.width }
        MSeparator { width: parent.width }
        Column { x: Theme.paddingLarge; width: parent.width - Theme.paddingLarge * 2; spacing: 2; topPadding: Theme.paddingLarge
            MLabel { text: cal.now.toLocaleTimeString(cal.loc, qsTr("AP h:mm:ss")); font.pixelSize: Theme.fontSizeTitle + 10; font.bold: true }
            MLabel { text: cal.now.toLocaleDateString(cal.loc, Locale.LongFormat); muted: true }
        }
        Item { width: parent.width; height: Theme.controlHeight + Theme.paddingLarge
            MButton { flat: true; icon: "back"; hPad: 6; anchors.left: parent.left; anchors.leftMargin: Theme.padding; anchors.verticalCenter: parent.verticalCenter; onClicked: cal.goMonth(-1); Accessible.name: qsTr("이전 달") }
            MLabel { anchors.centerIn: parent; text: new Date(cal.year, cal.month, 1).toLocaleDateString(cal.loc, qsTr("yyyy년 M월")); font.bold: true }
            MButton { flat: true; icon: "forward"; hPad: 6; anchors.right: parent.right; anchors.rightMargin: Theme.padding; anchors.verticalCenter: parent.verticalCenter; onClicked: cal.goMonth(1); Accessible.name: qsTr("다음 달") }
        }
        Grid { columns: 7; x: Theme.paddingLarge; width: parent.width - Theme.paddingLarge * 2
            Repeater { model: 7
                delegate: MLabel { required property int index; width: (col.width - Theme.paddingLarge * 2) / 7; horizontalAlignment: Text.AlignHCenter
                    text: cal.loc.dayName((index + cal.loc.firstDayOfWeek) % 7, Locale.ShortFormat); muted: true; font.pixelSize: Theme.fontSizeSmall } }
            Repeater { model: cal.daysModel()
                delegate: Item { required property var modelData; width: (col.width - Theme.paddingLarge * 2) / 7; height: 32
                    Rectangle { visible: modelData.today === true; anchors.centerIn: parent; width: 28; height: 28; radius: 14; color: Theme.accent }
                    MLabel { anchors.centerIn: parent; text: modelData.day > 0 ? modelData.day : ""; font.bold: modelData.today === true
                             color: modelData.today ? Theme.accentText : (modelData.weekend ? Theme.danger : Theme.text) } } }
        }
        Item { width: 1; height: Theme.paddingLarge }
    }
}
