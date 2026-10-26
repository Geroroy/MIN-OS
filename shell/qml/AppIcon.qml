// 앱 아이콘: image://appicon/<Icon=> (아이콘 테마·pixmaps) → 실패하면 HagraUI 자리 표시자(머리글자). 크기는 size.
import QtQuick
import HagraUI 1.0

Item {
    id: icon
    property string iconName: ""     // .desktop 의 Icon=
    property string fallback: "apps" // 모듈 자산 이름 (HagraUI)
    property string label: ""        // 자리 표시자 머리글자용 (앱 이름)
    property int size: Theme.iconSize
    width: size; height: size
    readonly property bool themed: img.status === Image.Ready
    Image {
        id: img
        anchors.fill: parent
        source: icon.iconName.length ? "image://appicon/" + icon.iconName : ""
        sourceSize: Qt.size(icon.size * 2, icon.size * 2)
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        smooth: true; cache: true
        visible: status === Image.Ready
    }
    Rectangle { // 자리 표시자: 분백 바탕 + 청록 1px + 머리글자 (아이콘 테마에 없는 앱도 서로 구분된다)
        visible: !icon.themed
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.surfaceRaised; border.width: 1; border.color: Theme.borderStrong
        Text { anchors.centerIn: parent; text: icon.label.length ? icon.label.charAt(0).toUpperCase() : "?"
               color: Theme.accent; font.bold: true; font.pixelSize: Math.max(9, icon.size * 0.5); font.family: Theme.fontFamily; renderType: Text.NativeRendering }
    }
}
