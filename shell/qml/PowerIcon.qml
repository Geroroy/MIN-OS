// 전원 아이콘: 1.5px 원호 + 세로선 (단색, text 색 상속)
import QtQuick
import MinUI 1.0

Item {
    property color color: Theme.text
    implicitWidth: 14
    implicitHeight: 14
    Rectangle {
        anchors.centerIn: parent
        width: 11; height: 11; radius: 5.5
        color: "transparent"
        border.width: 1.5
        border.color: parent.color
    }
    Rectangle {
        // 원 위쪽을 끊어 전원 기호 모양을 만든다
        x: parent.width / 2 - 2; y: 0
        width: 4; height: 4
        color: Theme.surface
    }
    Rectangle {
        x: parent.width / 2 - 0.75; y: 1
        width: 1.5; height: 6
        color: parent.color
    }
}
