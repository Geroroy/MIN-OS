import QtQuick
import MinUI 1.0

// 창 프레임 모형 — 미리보기 전용. 실제 창 장식은 labwc(SSD, session/labwc/themerc-override)가 그리며 QML 은 관여하지 않는다.
// 토큰 변경이 창 장식에 어떻게 보일지 갤러리에서 가늠하기 위한 그림이다.
Rectangle {
    id: frame
    property string title: "창 제목"
    property bool active: true
    default property alias content: inner.data
    implicitWidth: 320; implicitHeight: 200
    color: Theme.bg
    border.width: Theme.windowBorderWidth
    border.color: active ? Theme.windowActiveBorder : Theme.windowInactiveBorder
    radius: Theme.windowCornerRadius
    Rectangle {
        id: titleBar
        x: Theme.windowBorderWidth; y: Theme.windowBorderWidth; width: parent.width - Theme.windowBorderWidth * 2; height: Theme.titleBarHeight
        color: frame.active ? Theme.windowActiveTitleBg : Theme.windowInactiveTitleBg
        Text { anchors.left: parent.left; anchors.leftMargin: Theme.paddingLarge; anchors.verticalCenter: parent.verticalCenter
               text: frame.title; color: frame.active ? Theme.windowActiveTitleText : Theme.windowInactiveTitleText
               font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeTitle; font.bold: frame.active; renderType: Text.NativeRendering
               width: parent.width - 120; elide: Text.ElideRight }
        Row { anchors.right: parent.right; anchors.rightMargin: Theme.padding; anchors.verticalCenter: parent.verticalCenter; spacing: Theme.padding
            Repeater { model: ["–", "□", "×"]; delegate: Text { required property string modelData; text: modelData; width: 16; horizontalAlignment: Text.AlignHCenter
                       color: frame.active ? Theme.windowActiveTitleText : Theme.windowInactiveTitleText; font.pixelSize: Theme.fontSize; renderType: Text.NativeRendering } } }
    }
    MOrnamentBand { x: Theme.windowBorderWidth; y: titleBar.y + titleBar.height; width: parent.width - Theme.windowBorderWidth * 2 }
    Item { id: inner; x: Theme.windowBorderWidth; y: titleBar.y + titleBar.height + Theme.ornamentBandHeight; width: parent.width - Theme.windowBorderWidth * 2; height: parent.height - y - Theme.windowBorderWidth }
}
