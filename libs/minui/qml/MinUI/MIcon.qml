import QtQuick
import MinUI 1.0

// 아이콘. design/assets/icons/<name>.svg 가 있으면 표시하고, 없으면 자리 표시자(1px 테두리 + 머리글자)를 그린다.
// SVG 재착색은 Qt 6.4 에서 지원되지 않으므로(ColorOverlay 는 Qt5Compat 필요) 아이콘 자산은 상태별 색으로 미리 제공하거나 단색으로 쓴다.
Item {
    id: icon
    property string name: ""
    property int size: Theme.iconSize
    property color color: Theme.text
    readonly property string source: Theme.iconSource(name)
    width: size; height: size
    Image {
        id: img
        anchors.fill: parent
        source: icon.source
        sourceSize: Qt.size(icon.size, icon.size)
        visible: status === Image.Ready
        smooth: true
    }
    Rectangle { // 자리 표시자
        visible: img.status !== Image.Ready
        anchors.fill: parent
        color: "transparent"; border.width: 1; border.color: icon.color
        Text { anchors.centerIn: parent; text: icon.name.length ? icon.name.charAt(0).toUpperCase() : "?"
               color: icon.color; font.pixelSize: Math.max(8, icon.size * 0.6); font.family: Theme.fontFamily; renderType: Text.NativeRendering }
    }
}
