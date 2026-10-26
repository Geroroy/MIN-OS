import QtQuick
// Application-owned ornament overlay, NOT a labwc title bar implementation.
// Parent content must reserve inset; this Item has no input handlers.
Item {
    id: frame
    property real inset: 6
    property bool active: true
    property real cornerSize: 24
    opacity: active ? 1 : 0.65
    Rectangle { anchors.fill: parent; color: "transparent"; border.width: 2; border.color: "#4F756D"; radius: 2 }
    Rectangle { anchors.fill: parent; anchors.margins: 3; color: "transparent"; border.width: 1; border.color: "#E89B89" }
    Repeater {
        model: 4
        Image {
            required property int index
            x: index % 2 ? frame.width - width : 0
            y: index < 2 ? 0 : frame.height - height
            width: frame.cornerSize; height: frame.cornerSize
            source: "../assets/corner-rosette.svg"
            sourceSize.width: Math.ceil(width * 2)
            sourceSize.height: Math.ceil(height * 2)
        }
    }
}
