import QtQuick
import HagraUI 1.0

// 1px 구분선. vertical=true 이면 세로.
Rectangle {
    property bool vertical: false
    implicitWidth: vertical ? Theme.borderWidth : parent ? parent.width : 1
    implicitHeight: vertical ? (parent ? parent.height : 1) : Theme.borderWidth
    color: Theme.border
}
