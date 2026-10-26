// 안내 상자. kind: "info" | "warn" | "unavailable" (백엔드 없음 — 거짓 토글 대신 이유를 보여 준다)
import QtQuick
import HagraUI 1.0

Rectangle {
    id: note
    property string kind: "info"
    property string text: ""
    property string title: ""
    width: parent ? parent.width : 400
    height: col.height + Theme.paddingLarge
    radius: Theme.radius
    color: Theme.surfaceRaised
    border.width: Theme.borderWidth
    border.color: kind === "warn" ? Theme.warning : kind === "unavailable" ? Theme.danger : Theme.border
    Accessible.role: Accessible.StaticText
    Accessible.name: (title.length ? title + ". " : "") + text
    Rectangle { width: Theme.selectionMarkerWidth; height: parent.height; color: note.kind === "warn" ? Theme.warning : note.kind === "unavailable" ? Theme.danger : Theme.accent }
    Row { x: Theme.paddingLarge; y: Theme.padding; spacing: Theme.padding; width: parent.width - Theme.paddingLarge * 2
        MIcon { name: note.kind === "unavailable" ? "error" : "info"; size: 20; y: 1 }
        Column { id: col; width: parent.width - 20 - Theme.padding; spacing: 2
            MLabel { visible: note.title.length > 0; text: note.title; font.bold: true; width: parent.width; wrap: true }
            MLabel { text: note.text; wrap: true; width: parent.width; font.pixelSize: Theme.fontSizeSmall }
        }
    }
}
