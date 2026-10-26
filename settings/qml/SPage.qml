// 설정 페이지 틀: 제목·설명 + 세로 스크롤 본문. 자식은 `content` 컬럼에 들어간다.
import QtQuick
import HagraUI 1.0

Item {
    id: page
    property string title: ""
    property string subtitle: ""
    default property alias content: body.data
    property alias flickable: flick
    Flickable {
        id: flick
        anchors.fill: parent
        contentHeight: col.height + Theme.paddingLarge * 2
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        Column {
            id: col
            x: Theme.paddingLarge * 1.5; y: Theme.paddingLarge
            width: Math.min(720, flick.width - Theme.paddingLarge * 3 - (bar.visible ? Theme.scrollBarWidth : 0))
            spacing: Theme.paddingLarge
            MLabel { text: page.title; font.pixelSize: Theme.fontSizeTitle + 4; font.bold: true; width: parent.width; wrap: true; Accessible.role: Accessible.Heading }
            MLabel { visible: page.subtitle.length > 0; text: page.subtitle; muted: true; wrap: true; width: parent.width; font.pixelSize: Theme.fontSizeSmall }
            Column { id: body; width: parent.width; spacing: Theme.paddingLarge }
        }
    }
    MScrollBar { id: bar; flickable: flick; anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom }
}
