import QtQuick
import MinUI 1.0

// 앱이 소유하는 장식 프레임 오버레이: 겹선(청록 2px + 산호 1px) + 네 모서리 결구(corner-rosette).
// labwc 창 장식(SSD)이 아니다. 입력 핸들러가 없으며 부모 콘텐츠가 inset 만큼 여백을 둔다.
Item {
    id: frame
    property bool active: true
    property int inset: Theme.ornamentFrameWidth
    property int cornerSize: Theme.cornerSize
    property bool corners: true
    opacity: active ? 1 : 0.65
    Rectangle { anchors.fill: parent; color: "transparent"; border.width: 2; border.color: Theme.borderStrong; radius: Theme.radius }
    Rectangle { anchors.fill: parent; anchors.margins: 3; color: "transparent"; border.width: 1; border.color: Theme.coral }
    Repeater {
        model: frame.corners ? 4 : 0
        Image {
            required property int index
            x: index % 2 ? frame.width - width : 0
            y: index < 2 ? 0 : frame.height - height
            width: frame.cornerSize; height: frame.cornerSize
            source: Theme.asset("corner-rosette")
            sourceSize.width: Math.ceil(width * 2); sourceSize.height: Math.ceil(height * 2)
            smooth: true; cache: true
        }
    }
}
