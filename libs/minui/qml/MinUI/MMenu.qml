import QtQuick
import MinUI 1.0

// 팝업 메뉴 (창 안 오버레이). items: [{text, shortcut, enabled, separator, checked}]. ↑↓ Enter Esc, 바깥 클릭으로 닫힘.
// 제약: 창 경계 안에서만 표시된다. labwc 의 루트 메뉴·패널 메뉴는 별도 창(layer-shell)이다.
Item {
    id: menu
    property var items: []
    property int currentIndex: -1
    property int minWidth: 160
    readonly property bool opened: popup !== null && popup.visible
    signal triggered(int index, var item)
    signal closed()
    property Item popup: null

    function open(targetItem, x, y) {
        const root = targetItem.Window.contentItem
        if (!root) return
        if (!popup) popup = popupComponent.createObject(root)
        const p = targetItem.mapToItem(root, x, y)
        popup.x = Math.max(0, Math.min(root.width - popup.width, p.x))
        popup.y = Math.max(0, Math.min(root.height - popup.height, p.y))
        currentIndex = firstEnabled(0, 1)
        popup.visible = true
        popup.forceActiveFocus()
    }
    function close() { if (popup) { popup.visible = false; closed() } }
    function firstEnabled(from, step) {
        for (let i = from; i >= 0 && i < items.length; i += step) if (!items[i].separator && items[i].enabled !== false) return i
        return -1
    }
    function activate(i) { if (i < 0 || items[i].separator || items[i].enabled === false) return; close(); triggered(i, items[i]) }

    Component {
        id: popupComponent
        Item {
            z: 9000; visible: false
            width: box.width; height: box.height
            MouseArea { // 바깥 클릭 → 닫기 (창 전체 덮음)
                parent: menu.popup ? menu.popup.parent : null
                anchors.fill: parent; z: 8999; visible: menu.opened
                acceptedButtons: Qt.AllButtons
                onPressed: menu.close()
            }
            Keys.onEscapePressed: menu.close()
            Keys.onUpPressed: { const i = menu.firstEnabled(menu.currentIndex - 1, -1); if (i >= 0) menu.currentIndex = i }
            Keys.onDownPressed: { const i = menu.firstEnabled(menu.currentIndex + 1, 1); if (i >= 0) menu.currentIndex = i }
            Keys.onReturnPressed: menu.activate(menu.currentIndex)
            Keys.onEnterPressed: menu.activate(menu.currentIndex)
            Rectangle {
                id: box
                property int maxW: 0
                width: Math.max(menu.minWidth, maxW + 2); height: col.implicitHeight + 2
                color: Theme.surface; border.width: Theme.borderWidth; border.color: Theme.borderStrong
                Column {
                    id: col
                    x: 1; y: 1; width: parent.width - 2
                    Repeater {
                        model: menu.items
                        delegate: Item {
                            required property int index
                            required property var modelData
                            readonly property bool isSep: modelData.separator === true
                            readonly property bool isEnabled: modelData.enabled !== false
                            readonly property bool current: index === menu.currentIndex
                            width: col.width; height: isSep ? Theme.padding * 2 + 1 : Theme.rowHeight + 4
                            readonly property int neededWidth: isSep ? 0 : t.implicitWidth + (s.visible ? s.implicitWidth + 24 : 0) + Theme.paddingLarge * 2 + 16
                            onNeededWidthChanged: if (neededWidth > box.maxW) box.maxW = neededWidth
                            Component.onCompleted: if (neededWidth > box.maxW) box.maxW = neededWidth
                            Rectangle { visible: isSep; anchors.centerIn: parent; width: parent.width - Theme.paddingLarge * 2; height: 1; color: Theme.border }
                            Rectangle { visible: !isSep && current && isEnabled; anchors.fill: parent; color: Theme.selection }
                            Text { visible: !isSep && modelData.checked === true; x: Theme.padding; anchors.verticalCenter: parent.verticalCenter; text: "✓"
                                   color: current ? Theme.selectionText : Theme.text; font.pixelSize: Theme.fontSize; renderType: Text.NativeRendering }
                            Text { id: t; visible: !isSep; x: Theme.paddingLarge + 12; anchors.verticalCenter: parent.verticalCenter; text: modelData.text || ""
                                   color: !isEnabled ? Theme.textDisabled : current ? Theme.selectionText : Theme.text
                                   font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize; renderType: Text.NativeRendering }
                            Text { id: s; visible: !isSep && (modelData.shortcut || "").length > 0; anchors.right: parent.right; anchors.rightMargin: Theme.paddingLarge
                                   anchors.verticalCenter: parent.verticalCenter; text: modelData.shortcut || ""
                                   color: !isEnabled ? Theme.textDisabled : current ? Theme.selectionText : Theme.textMuted
                                   font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSmall; renderType: Text.NativeRendering }
                            MouseArea { anchors.fill: parent; hoverEnabled: true; enabled: !isSep && isEnabled
                                        onEntered: menu.currentIndex = index; onClicked: menu.activate(index) }
                        }
                    }
                }
            }
        }
    }
}
