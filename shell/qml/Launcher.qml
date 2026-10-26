// 하그라 셸 — 응용 프로그램 실행 메뉴 (패널 위 왼쪽, overlay layer, 키보드 독점)
// 구조: 연화 띠 · 검색 · 탭(앱 / 즐겨찾기 / 시스템) · 목록 · 바닥(설정 · 개수 · 전원).
// 검색은 현지화 이름·영문 이름·설명·초성(ㅌㅁ → 터미널)을 찾고, 입력 중에는 탭과 무관하게 결과를 보인다.
// 모든 항목은 실제 동작과 연결된다 (설정 앱이 없는 개발 호스트에서는 셸 내장 모양 창으로 대체).
import QtQuick
import HagraLayerShell 1.0
import HagraUI 1.0
import HagraShell 1.0

LayerWindow {
    id: launcher
    scope: "hagra-launcher"
    layer: LayerWindow.Overlay
    property bool panelAtTop: false
    anchors: LayerWindow.AnchorLeft | (panelAtTop ? LayerWindow.AnchorTop : LayerWindow.AnchorBottom)
    marginBottom: 0   // 패널의 exclusive zone 이 이미 공간을 비우므로 추가 여백 없음
    keyboardInteractivity: LayerWindow.KeyboardExclusive
    width: 440
    height: Math.max(420, Math.min(560, (Screen.height > 0 ? Screen.height : 720) - Theme.panelHeight - 8))
    color: Theme.surface
    visible: false

    property int tab: 0                                   // 0 앱 · 1 즐겨찾기 · 2 시스템
    readonly property bool searching: search.text.length > 0
    readonly property var tabNames: [qsTr("앱"), qsTr("즐겨찾기"), qsTr("시스템")]
    readonly property string fileManagerId: Apps.firstInCategory("FileManager")

    function toggle() { visible = !visible }
    function openSettings(page) { launcher.visible = false; Shell.dispatch(page && page.length ? "settings:" + page : "settings") }
    function launchId(id) { if (Apps.launchById(id)) launcher.visible = false }
    function runAction(a) {
        if (!a) return
        if (a.appId) { launchId(a.appId); return }
        switch (a.action) {
        case "terminal": if (Apps.launchCommand(Apps.terminalProgram())) launcher.visible = false; break
        case "power": launcher.visible = false; Shell.dispatch("power"); break
        case "settings": openSettings(""); break
        default: if (a.action && a.action.indexOf("settings:") === 0) openSettings(a.action.substring(9))
        }
    }
    function currentList() { return searching || tab === 0 ? appList : (tab === 1 ? favList : sysList) }
    function activateCurrent() {
        var l = currentList()
        if (l === appList) { if (appList.currentIndex >= 0 && Apps.launch(appList.currentIndex)) launcher.visible = false }
        else if (l.currentIndex >= 0 && l.currentIndex < l.model.length) runAction(l.model[l.currentIndex])
    }
    function move(delta) {
        var l = currentList()
        var n = l.count
        if (n <= 0) return
        var i = l.currentIndex
        for (var step = 0; step < n; ++step) {
            i = Math.max(0, Math.min(n - 1, i + delta))
            if (l === appList || !l.model[i].header) break
            if (i === 0 || i === n - 1) { if (delta < 0 && l.model[i].header) { i = l.currentIndex; break } }
        }
        l.currentIndex = i
    }
    function setTab(i) { tab = Math.max(0, Math.min(2, i)); if (!searching) { search.text = "" } }
    // 즐겨찾기 탭 모델: [머리글 즐겨찾기, 항목…, 머리글 최근 실행, 항목…] — 항목은 Apps.entry 로 이름·아이콘을 가져온다
    function buildFavModel() {
        var m = []
        var favs = LauncherState.favorites, rec = LauncherState.recent
        m.push({ header: true, name: qsTr("즐겨찾기") })
        var nf = 0
        for (var i = 0; i < favs.length; ++i) { var e = Apps.entry(favs[i]); if (e.appId) { e.favorite = true; m.push(e); ++nf } }
        if (nf === 0) m.push({ header: true, empty: true, name: "", hint: qsTr("즐겨찾기가 비어 있습니다 — 앱 목록에서 오른쪽 클릭 → 즐겨찾기에 추가") })
        m.push({ header: true, name: qsTr("최근 실행") })
        var nr = 0
        for (var j = 0; j < rec.length; ++j) { var r = Apps.entry(rec[j]); if (r.appId) { r.favorite = LauncherState.isFavorite(r.appId); m.push(r); ++nr } }
        if (nr === 0) m.push({ header: true, empty: true, name: "", hint: qsTr("최근 실행한 앱이 없습니다") })
        return m
    }
    function firstSelectable(l) { for (var i = 0; i < l.model.length; ++i) if (!l.model[i].header) return i; return -1 }

    onVisibleChanged: {
        if (visible) {
            Apps.filter = ""
            search.text = ""
            tab = 0
            appList.currentIndex = 0
            favList.model = buildFavModel(); favList.currentIndex = firstSelectable(favList)
            sysList.currentIndex = 0
            search.forceActiveFocus()
        } else { ctxMenu.close() }
    }
    Connections { target: LauncherState
        function onFavoritesChanged() { if (launcher.visible) { favList.model = launcher.buildFavModel(); favList.currentIndex = launcher.firstSelectable(favList) } }
        function onRecentChanged() { if (launcher.visible) { favList.model = launcher.buildFavModel(); favList.currentIndex = launcher.firstSelectable(favList) } }
    }

    Rectangle { anchors.fill: parent; color: "transparent"; border.width: Theme.windowBorderWidth; border.color: Theme.borderStrong; z: 10 }

    Item {
        id: content
        anchors.fill: parent
        anchors.margins: Theme.windowBorderWidth
        focus: true
        Keys.onEscapePressed: { if (ctxMenu.opened) ctxMenu.close(); else if (search.text.length) search.text = ""; else launcher.visible = false }
        Keys.onUpPressed: launcher.move(-1)
        Keys.onDownPressed: launcher.move(1)
        Keys.onPressed: (ev) => {
            if (ev.key === Qt.Key_PageUp) { launcher.move(-10); ev.accepted = true }
            else if (ev.key === Qt.Key_PageDown) { launcher.move(10); ev.accepted = true }
            else if (ev.key === Qt.Key_Tab && (ev.modifiers & Qt.ControlModifier)) { launcher.setTab((launcher.tab + (ev.modifiers & Qt.ShiftModifier ? 2 : 1)) % 3); ev.accepted = true }
            else if (ev.key === Qt.Key_Backtab && (ev.modifiers & Qt.ControlModifier)) { launcher.setTab((launcher.tab + 2) % 3); ev.accepted = true }
            else if ((ev.key === Qt.Key_Left || ev.key === Qt.Key_Right) && (ev.modifiers & Qt.ControlModifier)) { launcher.setTab((launcher.tab + (ev.key === Qt.Key_Right ? 1 : 2)) % 3); ev.accepted = true }
            else if (ev.key === Qt.Key_F2 && launcher.currentList() === appList && appList.currentIndex >= 0) { LauncherState.toggleFavorite(Apps.entry(appList.currentItem.appId).appId); ev.accepted = true }
        }

        Column {
            anchors.fill: parent
            spacing: 0

            MOrnamentBand { width: parent.width }
            MSeparator { width: parent.width }

            // 검색
            Item {
                width: parent.width
                height: Theme.controlHeight + Theme.paddingLarge * 2
                MSearchField {
                    id: search
                    anchors.fill: parent
                    anchors.margins: Theme.paddingLarge
                    placeholder: qsTr("앱 검색 — 이름·설명·초성(ㅌㅁ)")
                    Accessible.name: qsTr("응용 프로그램 검색")
                    onTextChanged: { Apps.filter = text; appList.currentIndex = 0; if (text.length) launcher.tab = 0 }
                    onAccepted: launcher.activateCurrent()
                }
            }
            MSeparator { width: parent.width }

            // 탭: 앱 · 즐겨찾기 · 시스템
            Item {
                width: parent.width; height: tabs.implicitHeight
                MTabBar {
                    id: tabs
                    x: Theme.paddingLarge - Theme.padding
                    width: parent.width - x
                    tabs: launcher.tabNames
                    currentIndex: launcher.tab
                    onActivated: (i) => launcher.setTab(i)
                    Accessible.name: qsTr("실행 메뉴 구역")
                }
            }

            // 목록 영역
            Item {
                id: lists
                width: parent.width
                height: parent.height - y - footer.height - 1

                // 앱 (전체 또는 검색 결과)
                ListView {
                    id: appList
                    anchors.fill: parent
                    visible: launcher.searching || launcher.tab === 0
                    clip: true
                    model: Apps
                    currentIndex: 0
                    highlightFollowsCurrentItem: true
                    highlightMoveDuration: 0
                    keyNavigationEnabled: false
                    boundsBehavior: Flickable.StopAtBounds
                    delegate: LauncherRow {
                        required property int index
                        required name
                        required comment
                        required property string icon
                        required property string appId
                        iconName: icon
                        favorite: LauncherState.favorites.indexOf(appId) >= 0
                        selected: ListView.isCurrentItem
                        focusVisible: ListView.isCurrentItem && content.activeFocus === false && search.activeFocus
                        onClicked: { appList.currentIndex = index; launcher.activateCurrent() }
                        onRightClicked: (x, y) => { appList.currentIndex = index; ctxMenu.target = appId; ctxMenu.open(this, x, y) }
                    }
                    MScrollBar { flickable: appList; anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom }
                    Column { // 빈 상태
                        anchors.centerIn: parent; width: parent.width - Theme.paddingLarge * 4; spacing: Theme.padding
                        visible: appList.count === 0
                        MIcon { name: Apps.totalCount === 0 ? "error" : "search"; size: Theme.iconSizeLarge; anchors.horizontalCenter: parent.horizontalCenter; color: Theme.textMuted }
                        MLabel { width: parent.width; horizontalAlignment: Text.AlignHCenter; font.bold: true; wrap: true
                                 text: Apps.totalCount === 0 ? qsTr("설치된 응용 프로그램이 없습니다") : "'" + search.text + qsTr("' 과 일치하는 앱이 없습니다") }
                        MLabel { width: parent.width; horizontalAlignment: Text.AlignHCenter; muted: true; wrap: true; font.pixelSize: Theme.fontSizeSmall
                                 text: Apps.totalCount === 0 ? qsTr("applications/ 디렉터리에 .desktop 항목이 없습니다. 앱을 설치하면 여기에 나타납니다.")
                                                             : qsTr("다른 검색어를 써 보세요. 영문 이름이나 초성(예: ㅌㅁ)으로도 찾을 수 있습니다.") }
                    }
                }

                // 즐겨찾기 + 최근 실행
                ListView {
                    id: favList
                    anchors.fill: parent
                    visible: !launcher.searching && launcher.tab === 1
                    clip: true
                    model: []
                    currentIndex: -1
                    highlightMoveDuration: 0
                    keyNavigationEnabled: false
                    boundsBehavior: Flickable.StopAtBounds
                    delegate: Item {
                        required property int index
                        required property var modelData
                        width: favList.width
                        height: modelData.empty ? hint.implicitHeight + Theme.paddingLarge : r.height
                        LauncherRow {
                            id: r; visible: !modelData.empty
                            name: modelData.name || ""; comment: modelData.comment || ""; iconName: modelData.icon || ""
                            header: modelData.header === true; favorite: modelData.favorite === true
                            selected: !header && favList.currentIndex === index
                            onClicked: { favList.currentIndex = index; launcher.runAction(modelData) }
                            onRightClicked: (x, y) => { favList.currentIndex = index; ctxMenu.target = modelData.appId; ctxMenu.open(this, x, y) }
                        }
                        MLabel { id: hint; visible: modelData.empty === true; x: Theme.paddingLarge; y: Theme.padding; width: parent.width - Theme.paddingLarge * 2
                                 text: modelData.hint || ""; muted: true; wrap: true; font.pixelSize: Theme.fontSizeSmall }
                    }
                    MScrollBar { flickable: favList; anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom }
                }

                // 시스템: 설정·모양과 테마·배경·디스플레이·터미널·파일·정보·전원
                ListView {
                    id: sysList
                    anchors.fill: parent
                    visible: !launcher.searching && launcher.tab === 2
                    clip: true
                    currentIndex: 0
                    highlightMoveDuration: 0
                    keyNavigationEnabled: false
                    boundsBehavior: Flickable.StopAtBounds
                    model: {
                        var m = [
                            { name: qsTr("설정"), comment: qsTr("모든 설정 (hagra-settings)"), symbol: "settings", action: "settings" },
                            { name: qsTr("모양과 테마"), comment: qsTr("테마 · 포인트 색 · 글자 크기 · 커서"), symbol: "lotus", action: "settings:appearance" },
                            { name: qsTr("배경 바꾸기"), comment: qsTr("바탕 화면 배경 이미지"), symbol: "image", action: "settings:wallpaper" },
                            { name: qsTr("디스플레이 설정"), comment: qsTr("해상도 · 배율 · 화면 배치"), symbol: "window", action: "settings:display" },
                            { name: qsTr("터미널"), comment: Apps.terminalProgram(), symbol: "terminal", action: "terminal" },
                        ]
                        if (launcher.fileManagerId.length) { var fm = Apps.entry(launcher.fileManagerId); m.push({ name: fm.name, comment: fm.comment, symbol: "folder", appId: fm.appId }) }
                        m.push({ name: qsTr("시스템 정보"), comment: qsTr("하그라 버전 · 하드웨어 · 로그"), symbol: "drive", action: "settings:about" })
                        m.push({ name: qsTr("전원"), comment: qsTr("종료 · 다시 시작 · 로그아웃"), symbol: "power", action: "power" })
                        return m
                    }
                    delegate: LauncherRow {
                        required property int index
                        required property var modelData
                        name: modelData.name; comment: modelData.comment || ""; symbol: modelData.symbol || ""
                        selected: sysList.currentIndex === index
                        onClicked: { sysList.currentIndex = index; launcher.runAction(modelData) }
                    }
                }
            }
            MSeparator { width: parent.width }

            // 바닥: 설정 · 개수 · 전원
            Item {
                id: footer
                width: parent.width
                height: Theme.controlHeight + Theme.paddingLarge * 2
                MButton {
                    id: settingsBtn
                    text: qsTr("설정"); icon: "settings"
                    anchors.left: parent.left; anchors.leftMargin: Theme.paddingLarge
                    anchors.verticalCenter: parent.verticalCenter
                    Accessible.name: qsTr("설정 열기")
                    onClicked: launcher.openSettings("")
                    MToolTip { text: qsTr("설정 — 모양과 테마, 디스플레이, 소리, 입력, 정보") }
                }
                MLabel {
                    anchors.centerIn: parent; muted: true; font.pixelSize: Theme.fontSizeSmall
                    text: launcher.searching ? Apps.count + " / " + Apps.totalCount + qsTr("개") : (launcher.tab === 0 ? qsTr("앱 ") + Apps.totalCount + qsTr("개") : "")
                    Accessible.ignored: true
                }
                MButton {
                    id: powerBtn
                    icon: "power"; text: qsTr("전원")
                    anchors.right: parent.right; anchors.rightMargin: Theme.paddingLarge
                    anchors.verticalCenter: parent.verticalCenter
                    Accessible.name: qsTr("전원 메뉴")
                    onClicked: { launcher.visible = false; Shell.dispatch("power") }
                }
            }
        }

        // 항목 메뉴: 실행 · 즐겨찾기 추가/제거
        MMenu {
            id: ctxMenu
            property string target: ""
            items: [ { text: qsTr("실행") }, { text: LauncherState.isFavorite(target) ? qsTr("즐겨찾기에서 제거") : qsTr("즐겨찾기에 추가"), shortcut: "F2" } ]
            onTriggered: (i) => { if (i === 0) launcher.launchId(target); else LauncherState.toggleFavorite(target) }
            onClosed: search.forceActiveFocus()
        }
    }
}
