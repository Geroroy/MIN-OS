// 실행 메뉴 목록 행: 앱 아이콘(테마 아이콘 또는 머리글자) + 이름 + 설명. 선택 = 선택 배경 + 왼쪽 3px 막대, 키보드 포커스 = 1px 링.
// 머리글(header=true)은 선택되지 않는 구역 제목이다. 오른쪽 클릭 → rightClicked (즐겨찾기 메뉴).
import QtQuick
import HagraUI 1.0

Rectangle {
    id: row
    property string name: ""
    property string comment: ""
    property string iconName: ""       // .desktop Icon= (앱)
    property string symbol: ""         // HagraUI 자산 이름 (시스템 항목)
    property bool selected: false
    property bool focusVisible: false
    property bool header: false
    property bool favorite: false
    signal clicked()
    signal rightClicked(real x, real y)

    width: parent ? parent.width : 400
    height: header ? Theme.rowHeight - 8 : (comment.length ? Theme.rowHeight + 12 : Theme.rowHeight)
    radius: Theme.radius
    color: header ? "transparent" : selected ? Theme.selection : (mouse.containsMouse ? Theme.surfaceRaised : "transparent")
    Accessible.role: header ? Accessible.Heading : Accessible.ListItem
    Accessible.name: header ? name : (name + (comment.length ? ", " + comment : ""))
    Accessible.selected: selected

    Rectangle { visible: row.selected && !row.header; anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
                width: Theme.selectionMarkerWidth; color: Theme.accent }
    Rectangle { visible: row.focusVisible && !row.header; anchors.fill: parent; color: "transparent"; z: 5
                border.width: Theme.focusRingWidth; border.color: Theme.focusRing }

    // 머리글: 작은 글자 + 선
    Row { visible: row.header; anchors.fill: parent; anchors.leftMargin: Theme.paddingLarge; anchors.rightMargin: Theme.paddingLarge; spacing: Theme.padding
        MLabel { text: row.name; muted: true; font.pixelSize: Theme.fontSizeSmall; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
        Rectangle { anchors.verticalCenter: parent.verticalCenter; height: 1; color: Theme.border
                    width: Math.max(0, row.width - Theme.paddingLarge * 2 - Theme.padding - 80) }
    }
    Row { visible: !row.header; anchors.fill: parent; anchors.leftMargin: Theme.paddingLarge; anchors.rightMargin: Theme.paddingLarge; spacing: Theme.paddingLarge
        Item { width: Theme.iconSizeLarge; height: Theme.iconSizeLarge; anchors.verticalCenter: parent.verticalCenter
            AppIcon { visible: row.symbol.length === 0; anchors.fill: parent; iconName: row.iconName; label: row.name; size: Theme.iconSizeLarge }
            MIcon { visible: row.symbol.length > 0; anchors.centerIn: parent; name: row.symbol; size: Theme.iconSize
                    color: row.selected ? Theme.selectionText : Theme.textMuted }
        }
        Column { anchors.verticalCenter: parent.verticalCenter; spacing: 3
            width: row.width - Theme.paddingLarge * 3 - Theme.iconSizeLarge - (row.favorite ? 20 : 0)
            MLabel { text: row.name; width: parent.width; elide: Text.ElideRight; font.bold: row.selected; lineHeight: 1.0
                     color: row.selected ? Theme.selectionText : Theme.text }
            MLabel { visible: row.comment.length > 0; text: row.comment; width: parent.width; elide: Text.ElideRight; lineHeight: 1.0
                     font.pixelSize: Theme.fontSizeSmall; color: row.selected ? Theme.selectionText : Theme.textMuted }
        }
    }
    MLabel { // 즐겨찾기 표시 (색 이외 단서: 글자 기호)
        visible: row.favorite && !row.header
        anchors.right: parent.right; anchors.rightMargin: Theme.paddingLarge; anchors.verticalCenter: parent.verticalCenter
        text: "★"; font.pixelSize: Theme.fontSizeSmall; color: row.selected ? Theme.selectionText : Theme.ochre
        Accessible.ignored: true
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: !row.header
        enabled: !row.header
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: (ev) => { if (ev.button === Qt.RightButton) row.rightClicked(ev.x, ev.y); else row.clicked() }
    }
}
