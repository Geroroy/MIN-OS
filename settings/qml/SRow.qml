// 설정 행: 왼쪽 라벨·설명, 오른쪽 조작 부품(control). 좁으면 세로로 쌓인다.
import QtQuick
import HagraUI 1.0

Item {
    id: row
    property string label: ""
    property string description: ""
    default property alias control: slot.data
    readonly property bool stacked: width < 520
    width: parent ? parent.width : 400
    implicitHeight: stacked ? text.height + slot.childrenRect.height + Theme.padding : Math.max(text.height, slot.childrenRect.height)
    height: implicitHeight
    Column { id: text; width: row.stacked ? row.width : Math.min(row.width * 0.55, row.width - slot.childrenRect.width - Theme.paddingLarge); spacing: 2
        MLabel { text: row.label; width: parent.width; wrap: true }
        MLabel { visible: row.description.length > 0; text: row.description; muted: true; font.pixelSize: Theme.fontSizeSmall; width: parent.width; wrap: true }
    }
    Item { id: slot; anchors.right: parent.right; y: row.stacked ? text.height + Theme.padding : 0
           width: childrenRect.width; height: childrenRect.height }
}
