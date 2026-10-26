// 구역 제목 (+ 선택적 연화 구분선)
import QtQuick
import HagraUI 1.0

Column {
    property string title: ""
    property bool divider: true
    width: parent ? parent.width : 400
    spacing: Theme.padding
    MOrnamentDivider { visible: divider; width: parent.width; height: 16 }
    MLabel { text: title; font.bold: true; font.pixelSize: Theme.fontSizeTitle; Accessible.role: Accessible.Heading }
}
