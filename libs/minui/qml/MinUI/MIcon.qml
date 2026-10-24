import QtQuick
import MinUI 1.0

// 아이콘. 1) 모듈 자산 assets/<name>.svg → 2) 외부 아이콘 디렉터리(Theme.iconBasePath) → 3) 자리 표시자(1px 테두리 + 머리글자).
// Qt 6.4 는 SVG 재착색(ColorOverlay)이 없으므로 자산은 완성된 색으로 제공된다. color 는 자리 표시자에만 쓰인다.
Item {
    id: icon
    property string name: ""
    property int size: Theme.iconSize
    property color color: Theme.text
    property int attempt: 0
    readonly property var candidates: [String(Theme.asset(name)), String(Theme.iconSource(name))]   // url → 문자열 (url.length 는 undefined)
    readonly property bool ready: img.status === Image.Ready
    width: size; height: size
    opacity: enabled ? 1 : 0.45   // 비활성: 단색 재착색 대신 흐림
    onNameChanged: attempt = 0
    Image {
        id: img
        anchors.fill: parent
        source: icon.name.length && icon.attempt < icon.candidates.length && icon.candidates[icon.attempt].length ? icon.candidates[icon.attempt] : ""
        sourceSize: Qt.size(icon.size * 2, icon.size * 2)
        fillMode: Image.PreserveAspectFit
        visible: status === Image.Ready
        smooth: true; cache: true
        onStatusChanged: if (status === Image.Error && icon.attempt < icon.candidates.length) icon.attempt++
    }
    Rectangle { // 자리 표시자
        visible: !icon.ready
        anchors.fill: parent
        color: "transparent"; border.width: 1; border.color: icon.color; radius: Theme.radius
        Text { anchors.centerIn: parent; text: icon.name.length ? icon.name.charAt(0).toUpperCase() : "?"
               color: icon.color; font.pixelSize: Math.max(8, icon.size * 0.55); font.family: Theme.fontFamily; renderType: Text.NativeRendering }
    }
}
