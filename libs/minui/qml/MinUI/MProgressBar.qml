import QtQuick
import MinUI 1.0

// 진행 표시. value 0..1, indeterminate=true 면 이동 막대. 텍스트 라벨은 호출자가 붙인다.
Rectangle {
    id: bar
    property real value: 0
    property bool indeterminate: false
    property bool error: false
    implicitWidth: 160; implicitHeight: 8
    color: Theme.bg
    border.width: Theme.borderWidth
    border.color: error ? Theme.danger : Theme.borderStrong
    Rectangle {
        visible: !bar.indeterminate
        x: 1; y: 1; height: parent.height - 2
        width: Math.max(0, (parent.width - 2) * Math.min(1, Math.max(0, bar.value)))
        color: bar.error ? Theme.danger : Theme.accent
    }
    MBusyBar { visible: bar.indeterminate; anchors.fill: parent; anchors.margins: 1; height: undefined }
}
