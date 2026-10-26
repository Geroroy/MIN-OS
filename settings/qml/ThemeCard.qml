// 테마 카드: 미리보기 · 이름 · 설명 · 밝기 · 현재/기본 표시 · 선택 버튼. 설정 → 모양 과 셸 대체 창에서 같은 모양.
import QtQuick
import HagraUI 1.0

Rectangle {
    id: card
    property var theme: ({})
    property bool focusVisible: false
    signal chosen(string id)
    readonly property bool cur: theme.current === true
    width: parent ? parent.width : 500; height: 118
    radius: Theme.radius
    color: cur ? Theme.selection : (hov.containsMouse ? Theme.surfaceRaised : Theme.surface)
    border.width: Theme.borderWidth; border.color: cur ? Theme.accent : Theme.border
    Accessible.role: Accessible.ListItem
    Accessible.name: theme.displayName + (cur ? qsTr(" (현재)") : "") + (theme.isDefault ? qsTr(" (기본)") : "")
    Rectangle { visible: card.cur; width: Theme.selectionMarkerWidth; height: parent.height; color: Theme.accent }
    Rectangle { visible: card.focusVisible; anchors.fill: parent; anchors.margins: -(Theme.focusRingWidth + 1); z: 5; color: "transparent"; radius: Theme.radius
                border.width: Theme.focusRingWidth; border.color: Theme.focusRing }
    Row { anchors.fill: parent; anchors.margins: Theme.padding; anchors.leftMargin: Theme.paddingLarge; spacing: Theme.paddingLarge
        Rectangle { width: 168; height: 96; color: Theme.bg; border.width: 1; border.color: Theme.border; anchors.verticalCenter: parent.verticalCenter
            Image { anchors.fill: parent; anchors.margins: 1; source: card.theme.preview || ""; fillMode: Image.PreserveAspectCrop; sourceSize.width: 336; smooth: true; cache: true; asynchronous: true }
            MLabel { anchors.centerIn: parent; visible: !card.theme.preview; text: qsTr("미리보기 없음"); muted: true; font.pixelSize: Theme.fontSizeSmall }
        }
        Column { id: info; anchors.verticalCenter: parent.verticalCenter; spacing: 3; width: parent.width - 168 - Theme.paddingLarge * 2 - 96
            Row { spacing: Theme.padding
                MLabel { text: card.theme.displayName || ""; font.bold: true; font.pixelSize: Theme.fontSizeTitle; color: card.cur ? Theme.selectionText : Theme.text }
                MLabel { visible: card.theme.isDefault === true; text: qsTr("기본"); muted: true; font.pixelSize: Theme.fontSizeSmall; anchors.verticalCenter: parent.verticalCenter }
                MLabel { text: card.theme.appearance === "dark" ? qsTr("어두움") : qsTr("밝음"); muted: true; font.pixelSize: Theme.fontSizeSmall; anchors.verticalCenter: parent.verticalCenter }
            }
            MLabel { text: card.theme.description || ""; wrap: true; width: info.width; maximumLineCount: 2; elide: Text.ElideRight
                     font.pixelSize: Theme.fontSizeSmall; color: card.cur ? Theme.selectionText : Theme.textMuted }
            MLabel { text: card.theme.id || ""; muted: true; font.pixelSize: 11; font.family: Theme.monoFamily; color: card.cur ? Theme.selectionText : Theme.textMuted }
        }
        Item { width: 96; height: parent.height
            MLabel { anchors.centerIn: parent; visible: card.cur; text: qsTr("✓ 현재"); font.bold: true; color: Theme.selectionText }
            MButton { anchors.centerIn: parent; visible: !card.cur; text: qsTr("선택"); activeFocusOnTab: false; onClicked: card.chosen(card.theme.id) }
        }
    }
    MouseArea { id: hov; anchors.fill: parent; hoverEnabled: true; z: -1; onClicked: card.chosen(card.theme.id) }
}
