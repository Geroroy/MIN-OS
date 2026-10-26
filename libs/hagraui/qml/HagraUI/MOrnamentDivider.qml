import QtQuick
import HagraUI 1.0

// 가운데 연꽃 포인트가 있는 얇은 구분 장식 (상태 표시줄·사이드바용). 장식 전용.
Item {
    id: div
    implicitHeight: 16
    implicitWidth: 120
    Rectangle { anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.right: mark.left; anchors.rightMargin: 6; height: 1; color: Theme.border }
    Rectangle { anchors.verticalCenter: parent.verticalCenter; anchors.right: parent.right; anchors.left: mark.right; anchors.leftMargin: 6; height: 1; color: Theme.border }
    Image { id: mark; anchors.centerIn: parent; width: 16; height: 16; source: Theme.asset("lotus"); sourceSize: Qt.size(32, 32); smooth: true }
}
