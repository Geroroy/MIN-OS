// 새 탭의 시작 페이지: 검색/주소 입력 + 자주 가는 곳(Browser.shortcuts, 주소 표시줄의 ★ 로 추가). 웹 페이지가 아니라 QML 이라 오프라인에서도 바로 뜬다.
import QtQuick
import HagraUI 1.0
import HagraBrowser 1.0

Rectangle {
    id: page
    signal navigate(string text)
    color: Theme.bg
    readonly property bool dark: Theme.isDark(Theme.bg)
    function focusSearch() { search.forceActiveFocus() }

    Image { anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; height: 72
            source: Theme.asset("lattice-tile"); fillMode: Image.Tile; sourceSize: Qt.size(48, 48); opacity: 0.25; smooth: true }

    Column {
        id: col
        width: Math.min(parent.width - Theme.paddingLarge * 4, 720)
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.max(Theme.paddingLarge, (parent.height - height) * 0.36)
        spacing: Theme.paddingLarge

        Row {
            anchors.horizontalCenter: parent.horizontalCenter; spacing: Theme.padding
            Image { source: Theme.asset("lotus"); width: 40; height: 40; sourceSize: Qt.size(80, 80); anchors.verticalCenter: parent.verticalCenter; smooth: true }
            MLabel { text: Theme.brandName; font.pixelSize: 32; font.bold: true; anchors.verticalCenter: parent.verticalCenter
                     Accessible.name: qsTr("하그라 브라우저") }
        }
        MSearchField {
            id: search
            width: parent.width; height: Theme.controlHeight + 8
            placeholder: qsTr("%1에서 검색하거나 주소 입력").arg(page.engineName())
            Accessible.name: qsTr("검색 또는 주소")
            onAccepted: if (text.trim().length) { page.navigate(text); text = "" }
        }
        MLabel { visible: grid.count === 0; width: parent.width; wrap: true; horizontalAlignment: Text.AlignHCenter; muted: true
                 font.pixelSize: Theme.fontSizeSmall; text: qsTr("주소 표시줄의 ★ 단추로 자주 가는 곳을 여기에 추가합니다.") }
        Flow {
            width: parent.width; spacing: Theme.padding
            Repeater {
                id: grid
                model: Browser.shortcuts
                delegate: Rectangle {
                    id: tile
                    required property var modelData
                    width: (col.width - Theme.padding * 4) / 5; height: 96
                    radius: Theme.radius
                    color: tileMouse.containsMouse || activeFocus ? Theme.surfaceRaised : Theme.surface
                    border.width: activeFocus ? Theme.focusRingWidth : Theme.borderWidth
                    border.color: activeFocus ? Theme.focusRing : Theme.border
                    activeFocusOnTab: true
                    Accessible.role: Accessible.Link
                    Accessible.name: modelData.title
                    Keys.onReturnPressed: page.navigate(modelData.url)
                    Keys.onSpacePressed: page.navigate(modelData.url)
                    Keys.onDeletePressed: Browser.removeShortcut(modelData.url)
                    MouseArea { id: tileMouse; anchors.fill: parent; hoverEnabled: true; onClicked: page.navigate(tile.modelData.url) }
                    Rectangle { // 머리글자 (사이트 아이콘은 방문 전에는 없다)
                        width: 40; height: 40; radius: Theme.radius; y: Theme.paddingLarge
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: Theme.selection; border.width: 1; border.color: Theme.borderStrong
                        Text { anchors.centerIn: parent; text: tile.modelData.title.length ? tile.modelData.title.charAt(0).toUpperCase() : "?"
                               color: Theme.selectionText; font.bold: true; font.pixelSize: 20; font.family: Theme.fontFamily; renderType: Text.NativeRendering }
                    }
                    MLabel { anchors.bottom: parent.bottom; anchors.bottomMargin: Theme.padding; x: Theme.padding; width: parent.width - Theme.padding * 2
                             horizontalAlignment: Text.AlignHCenter; text: tile.modelData.title; font.pixelSize: Theme.fontSizeSmall }
                    MButton { visible: tileMouse.containsMouse || hovered; flat: true; text: "×"; hPad: 6; height: 24
                              anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 2; activeFocusOnTab: false
                              Accessible.name: qsTr("자주 가는 곳에서 빼기"); onClicked: Browser.removeShortcut(tile.modelData.url) }
                }
            }
        }
    }
    function engineName() {
        var list = Browser.searchEngines
        for (var i = 0; i < list.length; ++i) if (list[i].id === Browser.searchEngine) return list[i].name
        return ""
    }
}
