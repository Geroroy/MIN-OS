// 하그라 브라우저 — 창: 연화 띠 · 탭 막대 · 도구 막대(뒤로·앞으로·새로 고침·처음·주소·★·메뉴) · 알림 막대 · 웹 콘텐츠 · 내려받기 막대.
// 창 장식은 labwc(SSD). 단일 인스턴스 소켓 명령: "open:<주소>"(새 탭) | "raise".
import QtQuick
import QtWebEngine
import HagraUI 1.0
import HagraTheme 1.0
import HagraBrowser 1.0

Window {
    id: win
    width: 1120; height: 720
    minimumWidth: 480; minimumHeight: 360
    color: Theme.surface
    visible: true
    title: (current ? current.displayTitle : qsTr("새 탭")) + " — " + qsTr("하그라 브라우저")

    property var tabs: []
    property int currentIndex: -1
    readonly property var current: currentIndex >= 0 && currentIndex < tabs.length ? tabs[currentIndex] : null
    property var closedUrls: []                  // 닫은 탭 다시 열기 (Ctrl+Shift+T)
    property bool pageFullScreen: false          // 웹 페이지가 요청한 전체 화면 (동영상 등): 창 장식·막대를 숨긴다
    property int visibilityBeforeFullScreen: Window.Windowed
    property var permission: null                // { view, origin, feature }
    property var download: null                  // 마지막 내려받기 (WebEngineDownloadRequest)
    property bool downloadDismissed: false
    readonly property int inset: pageFullScreen ? 0 : Theme.ornamentFrameWidth
    readonly property bool chromeDark: Theme.isDark(Theme.surface)
    readonly property var zoomSteps: [0.25, 0.33, 0.5, 0.67, 0.75, 0.8, 0.9, 1.0, 1.1, 1.25, 1.5, 1.75, 2.0, 2.5, 3.0, 4.0, 5.0]

    WebEngineProfile {
        id: webProfile
        storageName: "hagra"
        offTheRecord: !Browser.storageWritable   // 홈을 쓸 수 없으면 메모리 전용으로라도 동작한다
        persistentStoragePath: Browser.storagePath
        cachePath: Browser.cachePath
        httpCacheType: WebEngineProfile.DiskHttpCache
        persistentCookiesPolicy: WebEngineProfile.AllowPersistentCookies
        httpAcceptLanguage: Browser.acceptLanguage
        downloadPath: Browser.downloadDir
        onDownloadFinished: function(request) {
            Browser.log("download finished state " + request.state + " " + request.receivedBytes + " bytes")
            if (request.state === WebEngineDownloadRequest.DownloadCompleted)
                Browser.notify(qsTr("내려받기 완료"), request.downloadFileName)
        }
        onDownloadRequested: function(request) {
            request.accept()
            win.download = request
            win.downloadDismissed = false
            Browser.log("download " + request.downloadDirectory + "/" + request.downloadFileName)
            // 내려받기 주소를 열려고 만든 탭(아무 페이지도 불러온 적 없음)은 빈 탭으로 남기지 않는다
            var v = request.view
            if (v && win.tabs.indexOf(v) >= 0 && !v.everLoaded && !v.showStart)
                Qt.callLater(function() { if (win.tabs.length > 1) win.closeTab(v); else { v.showStart = true; win.syncAddress() } })
        }
        onPresentNotification: function(notification) {
            Browser.notify(notification.title, notification.message)
            notification.show()
        }
    }

    Component { id: tabComponent; BrowserTab { browser: win; profile: webProfile; anchors.fill: parent } }

    // ── 탭 ─────────────────────────────────────────────────────────
    function addTab(url, opts) {
        opts = opts || {}
        var v = tabComponent.createObject(content)
        var list = tabs.slice()
        var at = opts.afterCurrent && currentIndex >= 0 ? currentIndex + 1 : list.length
        list.splice(at, 0, v)
        tabs = list
        if (url && url.length) { v.showStart = false; v.url = url }
        if (!opts.background) selectTab(at)
        else if (currentIndex >= at) currentIndex++
        return v
    }
    function selectTab(i) {
        if (i < 0 || i >= tabs.length) return
        currentIndex = i
        Qt.callLater(function() { if (win.current && !win.current.showStart) win.current.forceActiveFocus(); else address.forceActiveFocus() })
    }
    function closeTab(v) {
        var i = tabs.indexOf(v)
        if (i < 0) return
        if (!v.showStart && v.everLoaded && v.url.toString().length) closedUrls = closedUrls.concat([v.url.toString()]).slice(-20)
        if (permission && permission.view === v) permission = null
        if (pageFullScreen && v === current) setPageFullScreen(v, false)
        var list = tabs.slice()
        list.splice(i, 1)
        var next = currentIndex > i ? currentIndex - 1 : Math.min(currentIndex, list.length - 1)
        tabs = list
        currentIndex = -1
        v.destroy()
        if (!list.length) { win.close(); return }
        selectTab(next)
    }
    function reopenClosedTab() {
        if (!closedUrls.length) return
        var u = closedUrls[closedUrls.length - 1]
        closedUrls = closedUrls.slice(0, -1)
        addTab(u)
    }
    function openNewWindowRequest(opener, request) {
        // 팝업·새 창도 탭으로 연다. 백그라운드 탭 요청(가운데 클릭 등)은 현재 탭을 유지한다.
        var bg = request.destination === WebEngineNewWindowRequest.InNewBackgroundTab
        var v = addTab("", { afterCurrent: true, background: bg })
        v.showStart = false
        request.openIn(v)
    }
    function handleCommand(line) {
        if (line.indexOf("open:") === 0) addTab(line.substring(5))
        else if (!tabs.length) addTab("")
        win.show(); win.raise(); win.requestActivate()
    }

    // ── 탐색 ───────────────────────────────────────────────────────
    function navigate(text) {
        var u = Browser.fixup(text)
        if (!u.length) return
        if (!current) addTab(u)
        else { current.showStart = false; current.url = u; current.forceActiveFocus() }
    }
    function goHome() {
        if (!current) return
        current.stop()
        current.showStart = true
        syncAddress()
        address.forceActiveFocus()
    }
    function goBack() {
        if (!current) return
        if (current.showStart) {
            if (!current.url.toString().length) return
            current.showStart = false
            current.forceActiveFocus()   // 주소 표시줄 포커스를 풀어야 주소가 다시 채워진다
        }
        else current.goBack()
    }
    function syncAddress() {
        if (address.input.activeFocus) return
        address.text = !current || current.showStart ? "" : Browser.displayUrl(current.url)
    }
    onCurrentChanged: { syncAddress(); findBar.visible = false }
    Connections {
        target: win.current
        ignoreUnknownSignals: true
        function onUrlChanged() { win.syncAddress() }
        function onShowStartChanged() { win.syncAddress() }
    }
    function setZoom(dir) {
        if (!current) return
        if (dir === 0) { current.zoomFactor = 1.0; return }
        var z = current.zoomFactor, s = zoomSteps
        if (dir > 0) { for (var i = 0; i < s.length; ++i) if (s[i] > z + 0.001) { current.zoomFactor = s[i]; return } }
        else { for (var j = s.length - 1; j >= 0; --j) if (s[j] < z - 0.001) { current.zoomFactor = s[j]; return } }
    }
    function toggleShortcut() {
        if (!current || current.showStart || !current.url.toString().length) return
        Browser.toggleShortcut(current.title, current.url.toString())
    }

    // ── 전체 화면 · 권한 · 문맥 메뉴 ──────────────────────────────
    function setPageFullScreen(v, on) {
        if (on === pageFullScreen) return
        if (on) { visibilityBeforeFullScreen = win.visibility === Window.FullScreen ? Window.Windowed : win.visibility; pageFullScreen = true; win.showFullScreen() }
        else {
            pageFullScreen = false
            if (visibilityBeforeFullScreen === Window.Maximized) win.showMaximized(); else win.showNormal()
            if (v && v.isFullScreen) v.fullScreenCancelled()
        }
    }
    function askPermission(v, origin, feature) {
        if (permission) answerPermission(false)   // 답하지 않은 이전 요청은 거부로 끝낸다 (페이지가 기다리지 않게)
        permission = { view: v, origin: origin, feature: feature }
    }
    function answerPermission(granted) {
        if (!permission) return
        permission.view.grantFeaturePermission(permission.origin, permission.feature, granted)
        permission = null
    }
    function permissionText(p) {
        if (!p) return ""
        var host = Browser.shortName(p.origin)
        switch (p.feature) {
        case WebEngineView.Geolocation: return qsTr("%1 사이트가 위치 정보를 쓰려고 합니다.").arg(host)
        case WebEngineView.MediaAudioCapture: return qsTr("%1 사이트가 마이크를 쓰려고 합니다.").arg(host)
        case WebEngineView.MediaVideoCapture: return qsTr("%1 사이트가 카메라를 쓰려고 합니다.").arg(host)
        case WebEngineView.MediaAudioVideoCapture: return qsTr("%1 사이트가 카메라와 마이크를 쓰려고 합니다.").arg(host)
        case WebEngineView.DesktopVideoCapture:
        case WebEngineView.DesktopAudioVideoCapture: return qsTr("%1 사이트가 화면을 공유하려고 합니다.").arg(host)
        case WebEngineView.Notifications: return qsTr("%1 사이트가 알림을 보내려고 합니다.").arg(host)
        }
        return qsTr("%1 사이트가 권한을 요청합니다.").arg(host)
    }
    property var contextView: null
    property var contextData: ({})
    function showContextMenu(v, r) {
        contextView = v
        var d = { link: r.linkUrl.toString(), media: r.mediaUrl.toString(), image: r.mediaType === ContextMenuRequest.MediaTypeImage,
                  text: r.selectedText, editable: r.isContentEditable, flags: r.editFlags }
        contextData = d
        var items = []
        if (d.link.length) items.push({ text: qsTr("링크를 새 탭에서 열기"), id: "link-tab" },
                                      { text: qsTr("링크 주소 복사"), id: "link-copy" },
                                      { text: qsTr("링크 저장"), id: "link-save" }, { separator: true })
        if (d.image && d.media.length) items.push({ text: qsTr("이미지를 새 탭에서 열기"), id: "img-tab" },
                                                  { text: qsTr("이미지 복사"), id: "img-copy" },
                                                  { text: qsTr("이미지 주소 복사"), id: "img-url" },
                                                  { text: qsTr("이미지 저장"), id: "img-save" }, { separator: true })
        if (d.editable) items.push({ text: qsTr("실행 취소"), id: "undo", shortcut: "Ctrl+Z", enabled: (d.flags & ContextMenuRequest.CanUndo) !== 0 },
                                   { text: qsTr("잘라내기"), id: "cut", shortcut: "Ctrl+X", enabled: (d.flags & ContextMenuRequest.CanCut) !== 0 })
        if (d.text.length || d.editable) items.push({ text: qsTr("복사"), id: "copy", shortcut: "Ctrl+C", enabled: (d.flags & ContextMenuRequest.CanCopy) !== 0 })
        if (d.editable) items.push({ text: qsTr("붙여넣기"), id: "paste", shortcut: "Ctrl+V", enabled: (d.flags & ContextMenuRequest.CanPaste) !== 0 },
                                   { text: qsTr("모두 선택"), id: "select-all", shortcut: "Ctrl+A" })
        var flat = d.text.replace(/\s+/g, " ").trim()   // 여러 줄 선택도 메뉴 한 줄로
        if (flat.length) items.push({ text: qsTr("“%1” 검색").arg(flat.length > 24 ? flat.substring(0, 24) + "…" : flat), id: "search" })
        if (items.length && !items[items.length - 1].separator) items.push({ separator: true })
        items.push({ text: qsTr("뒤로"), id: "back", shortcut: "Alt+←", enabled: v.canGoBack },
                   { text: qsTr("앞으로"), id: "forward", shortcut: "Alt+→", enabled: v.canGoForward },
                   { text: qsTr("새로 고침"), id: "reload", shortcut: "F5" },
                   { separator: true },
                   { text: qsTr("페이지 저장"), id: "save-page" },
                   { text: qsTr("페이지 소스 보기"), id: "view-source" })
        contextMenu.items = items
        contextMenu.open(v, r.position.x, r.position.y)
    }
    function contextAction(id) {
        var v = contextView, d = contextData
        if (!v) return
        switch (id) {
        case "link-tab": addTab(d.link, { afterCurrent: true, background: true }); break
        case "link-copy": v.triggerWebAction(WebEngineView.CopyLinkToClipboard); break
        case "link-save": v.triggerWebAction(WebEngineView.DownloadLinkToDisk); break
        case "img-tab": addTab(d.media, { afterCurrent: true, background: true }); break
        case "img-copy": v.triggerWebAction(WebEngineView.CopyImageToClipboard); break
        case "img-url": v.triggerWebAction(WebEngineView.CopyImageUrlToClipboard); break
        case "img-save": v.triggerWebAction(WebEngineView.DownloadImageToDisk); break
        case "undo": v.triggerWebAction(WebEngineView.Undo); break
        case "cut": v.triggerWebAction(WebEngineView.Cut); break
        case "copy": v.triggerWebAction(WebEngineView.Copy); break
        case "paste": v.triggerWebAction(WebEngineView.Paste); break
        case "select-all": v.triggerWebAction(WebEngineView.SelectAll); break
        case "search": addTab(Browser.searchUrl(d.text.replace(/\s+/g, " ")), { afterCurrent: true }); break
        case "back": goBack(); break
        case "forward": v.goForward(); break
        case "reload": v.reload(); break
        case "save-page": v.triggerWebAction(WebEngineView.SavePage); break
        case "view-source": addTab("view-source:" + v.url, { afterCurrent: true }); break
        }
    }
    function menuAction(id) {
        if (id.indexOf("engine:") === 0) { Browser.searchEngine = id.substring(7); return }
        switch (id) {
        case "new-tab": addTab(""); break
        case "reopen": reopenClosedTab(); break
        case "find": openFind(); break
        case "zoom-in": setZoom(1); break
        case "zoom-out": setZoom(-1); break
        case "zoom-reset": setZoom(0); break
        case "shortcut": toggleShortcut(); break
        case "downloads": addTab("file://" + encodeURI(Browser.downloadDir)); break
        case "clear-cache": webProfile.clearHttpCache(); break
        }
    }
    function openMainMenu() {
        var page = current && !current.showStart
        var items = [
            { text: qsTr("새 탭"), id: "new-tab", shortcut: "Ctrl+T" },
            { text: qsTr("닫은 탭 다시 열기"), id: "reopen", shortcut: "Ctrl+Shift+T", enabled: closedUrls.length > 0 },
            { separator: true },
            { text: qsTr("페이지에서 찾기"), id: "find", shortcut: "Ctrl+F", enabled: page },
            { text: qsTr("확대"), id: "zoom-in", shortcut: "Ctrl++", enabled: page },
            { text: qsTr("축소"), id: "zoom-out", shortcut: "Ctrl+-", enabled: page },
            { text: qsTr("원래 크기 (지금 %1%)").arg(current ? Math.round(current.zoomFactor * 100) : 100), id: "zoom-reset", shortcut: "Ctrl+0", enabled: page },
            { separator: true },
            { text: page && Browser.hasShortcut(current.url.toString()) ? qsTr("자주 가는 곳에서 빼기") : qsTr("자주 가는 곳에 추가"), id: "shortcut", shortcut: "Ctrl+D", enabled: page },
            { text: qsTr("내려받은 파일"), id: "downloads" },
            { text: qsTr("캐시 비우기"), id: "clear-cache" },
            { separator: true }
        ]
        var engines = Browser.searchEngines
        for (var i = 0; i < engines.length; ++i)
            items.push({ text: qsTr("검색: %1").arg(engines[i].name), id: "engine:" + engines[i].id, checked: engines[i].id === Browser.searchEngine })
        mainMenu.items = items
        mainMenu.open(menuButton, menuButton.width - 240, menuButton.height)
    }

    // ── 찾기 ───────────────────────────────────────────────────────
    function openFind() {
        if (!current || current.showStart) return
        findBar.visible = true
        findField.forceActiveFocus()
        findField.input.selectAll()
        if (findField.text.length) current.findText(findField.text)
    }
    function closeFind() {
        if (!findBar.visible) return
        findBar.visible = false
        if (current) { current.findText(""); current.findMatches = -1; current.forceActiveFocus() }
    }
    function findNext(backward) {
        if (!current || !findField.text.length) return
        if (backward) current.findText(findField.text, WebEngineView.FindBackward); else current.findText(findField.text)
    }

    function humanSize(b) {
        if (b < 0) return "?"
        if (b < 1024) return b + " B"
        if (b < 1024 * 1024) return (b / 1024).toFixed(0) + " KB"
        if (b < 1024 * 1024 * 1024) return (b / 1024 / 1024).toFixed(1) + " MB"
        return (b / 1024 / 1024 / 1024).toFixed(2) + " GB"
    }
    function downloadText(d) {
        if (!d) return ""
        var name = d.downloadFileName
        switch (d.state) {
        case WebEngineDownloadRequest.DownloadCompleted: return qsTr("%1 — 내려받기 완료 (%2)").arg(name).arg(humanSize(d.totalBytes > 0 ? d.totalBytes : d.receivedBytes))
        case WebEngineDownloadRequest.DownloadCancelled: return qsTr("%1 — 취소됨").arg(name)
        case WebEngineDownloadRequest.DownloadInterrupted: return qsTr("%1 — 중단됨: %2").arg(name).arg(d.interruptReasonString)
        }
        return d.totalBytes > 0 ? qsTr("%1 — 내려받는 중 %2 / %3").arg(name).arg(humanSize(d.receivedBytes)).arg(humanSize(d.totalBytes))
                                : qsTr("%1 — 내려받는 중 %2").arg(name).arg(humanSize(d.receivedBytes))
    }

    Component.onCompleted: {
        for (var i = 0; i < initialUrls.length; ++i) addTab(initialUrls[i])
        if (!tabs.length) addTab("")
        selectTab(0)
        Browser.log("window ready, tabs " + tabs.length)
    }

    // ── 단축키 ─────────────────────────────────────────────────────
    Shortcut { sequences: [StandardKey.AddTab]; onActivated: win.addTab("") }
    Shortcut { sequences: ["Ctrl+W", "Ctrl+F4"]; onActivated: if (win.current) win.closeTab(win.current) }
    Shortcut { sequence: "Ctrl+Shift+T"; onActivated: win.reopenClosedTab() }
    Shortcut { sequences: ["Ctrl+Tab", "Ctrl+PgDown"]; onActivated: win.selectTab((win.currentIndex + 1) % win.tabs.length) }
    Shortcut { sequences: ["Ctrl+Shift+Tab", "Ctrl+PgUp"]; onActivated: win.selectTab((win.currentIndex - 1 + win.tabs.length) % win.tabs.length) }
    Shortcut { sequences: ["Ctrl+L", "Alt+D", "F6"]; onActivated: { address.forceActiveFocus(); address.input.selectAll() } }
    Shortcut { sequences: ["F5", "Ctrl+R"]; onActivated: if (win.current && !win.current.showStart) win.current.reload() }
    Shortcut { sequences: ["Shift+F5", "Ctrl+Shift+R"]; onActivated: if (win.current && !win.current.showStart) win.current.reloadAndBypassCache() }
    Shortcut { sequence: "Alt+Left"; onActivated: win.goBack() }
    Shortcut { sequence: "Alt+Right"; onActivated: if (win.current) win.current.goForward() }
    Shortcut { sequence: "Alt+Home"; onActivated: win.goHome() }
    Shortcut { sequences: [StandardKey.Find]; onActivated: win.openFind() }
    Shortcut { sequences: ["Ctrl+G", "F3"]; onActivated: win.findNext(false) }
    Shortcut { sequences: ["Ctrl+Shift+G", "Shift+F3"]; onActivated: win.findNext(true) }
    Shortcut { sequences: ["Ctrl+=", "Ctrl++"]; onActivated: win.setZoom(1) }
    Shortcut { sequence: "Ctrl+-"; onActivated: win.setZoom(-1) }
    Shortcut { sequence: "Ctrl+0"; onActivated: win.setZoom(0) }
    Shortcut { sequence: "Ctrl+D"; onActivated: win.toggleShortcut() }
    Shortcut { sequence: "F11"; onActivated: { if (win.pageFullScreen) win.setPageFullScreen(win.current, false); else if (win.visibility === Window.FullScreen) win.showNormal(); else win.showFullScreen() } }
    Shortcut { // Esc 는 웹 페이지도 쓰므로 (대화 상자 닫기 등) 브라우저가 쓸 때만 가로챈다
        sequence: "Esc"
        enabled: win.pageFullScreen || findBar.visible || address.input.activeFocus
        onActivated: {
            if (win.pageFullScreen) win.setPageFullScreen(win.current, false)
            else if (address.input.activeFocus) {   // 입력 취소: 주소를 되돌리고 페이지로
                if (win.current && !win.current.showStart) win.current.forceActiveFocus(); else address.text = ""
            }
            else win.closeFind()
        }
    }

    // ── 화면 ───────────────────────────────────────────────────────
    Column {
        id: layout
        anchors.fill: parent; anchors.margins: win.inset; spacing: 0

        MOrnamentBand { width: parent.width; compact: true; visible: !win.pageFullScreen }

        // 탭 막대
        Rectangle {
            id: tabStrip
            width: parent.width; height: win.pageFullScreen ? 0 : Theme.controlHeight + 4
            visible: !win.pageFullScreen
            color: Theme.bg
            readonly property real tabWidth: Math.max(112, Math.min(232, (width - newTabButton.width - Theme.padding) / Math.max(1, win.tabs.length)))
            Flickable {
                id: tabFlick
                anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
                width: Math.min(contentWidth, parent.width - newTabButton.width - Theme.padding)
                contentWidth: tabRow.width; clip: true
                boundsBehavior: Flickable.StopAtBounds
                Row {
                    id: tabRow
                    height: parent.height
                    Repeater {
                        model: win.tabs
                        TabItem {
                            required property var modelData
                            required property int index
                            view: modelData
                            current: index === win.currentIndex
                            width: tabStrip.tabWidth; height: tabRow.height
                            onActivated: win.selectTab(index)
                            onCloseRequested: win.closeTab(modelData)
                            onCurrentChanged: if (current) { // 현재 탭이 보이도록 스크롤
                                if (x < tabFlick.contentX) tabFlick.contentX = x
                                else if (x + width > tabFlick.contentX + tabFlick.width) tabFlick.contentX = x + width - tabFlick.width
                            }
                        }
                    }
                }
            }
            MButton {
                id: newTabButton
                anchors.left: tabFlick.right; anchors.leftMargin: 4; anchors.verticalCenter: parent.verticalCenter
                flat: true; text: "+"; hPad: 10; height: Theme.controlHeight - 4; bold: true; onDark: Theme.isDark(Theme.bg)
                Accessible.name: qsTr("새 탭")
                onClicked: win.addTab("")
                MToolTip { text: qsTr("새 탭 (Ctrl+T)") }
            }
        }

        // 도구 막대
        Rectangle {
            id: toolbar
            width: parent.width; height: win.pageFullScreen ? 0 : Theme.controlHeight + Theme.padding * 2
            visible: !win.pageFullScreen
            color: Theme.surface
            Row {
                id: navButtons
                x: Theme.padding; anchors.verticalCenter: parent.verticalCenter; spacing: 2
                MButton { flat: true; icon: "back"; hPad: 6; onDark: win.chromeDark   // 시작 페이지에서 뒤로 = 보던 페이지로 돌아가기
                          enabled: win.current !== null && (win.current.showStart ? win.current.url.toString().length > 0 : win.current.canGoBack)
                          Accessible.name: qsTr("뒤로"); onClicked: win.goBack(); MToolTip { text: qsTr("뒤로 (Alt+←)") } }
                MButton { flat: true; icon: "forward"; hPad: 6; onDark: win.chromeDark; enabled: win.current && win.current.canGoForward
                          Accessible.name: qsTr("앞으로"); onClicked: { win.current.showStart = false; win.current.goForward() } MToolTip { text: qsTr("앞으로 (Alt+→)") } }
                MButton { flat: true; hPad: 6; onDark: win.chromeDark; enabled: win.current && !win.current.showStart
                          icon: win.current && win.current.loading ? "close" : "refresh"
                          Accessible.name: win.current && win.current.loading ? qsTr("멈추기") : qsTr("새로 고침")
                          onClicked: if (win.current.loading) win.current.stop(); else win.current.reload()
                          MToolTip { text: win.current && win.current.loading ? qsTr("멈추기 (Esc)") : qsTr("새로 고침 (F5)") } }
                MButton { flat: true; icon: "home"; hPad: 6; onDark: win.chromeDark; Accessible.name: qsTr("시작 페이지"); onClicked: win.goHome()
                          MToolTip { text: qsTr("시작 페이지 (Alt+Home)") } }
            }
            MTextField {
                id: address
                anchors.left: navButtons.right; anchors.leftMargin: Theme.padding
                anchors.right: menuButton.left; anchors.rightMargin: Theme.padding
                anchors.verticalCenter: parent.verticalCenter
                placeholder: qsTr("검색어 또는 주소 입력")
                Accessible.name: qsTr("주소 표시줄")
                input.anchors.leftMargin: Theme.iconSize + Theme.padding * 2
                input.anchors.rightMargin: star.width + Theme.padding * 2
                readonly property string scheme: win.current && !win.current.showStart ? win.current.url.toString().split(":")[0] : ""
                onAccepted: win.navigate(text)
                MIcon {
                    id: secureIcon
                    anchors.left: parent.left; anchors.leftMargin: Theme.padding; anchors.verticalCenter: parent.verticalCenter
                    light: win.chromeDark
                    name: address.scheme === "https" ? "lock" : address.scheme === "http" ? "info" : address.scheme === "file" ? "file" : "search"
                    MToolTip { text: address.scheme === "https" ? qsTr("암호화된 연결 (HTTPS)")
                                   : address.scheme === "http" ? qsTr("안전하지 않은 연결: 이 사이트와 주고받는 내용이 암호화되지 않습니다")
                                   : "" }
                }
                MButton {
                    id: star
                    anchors.right: parent.right; anchors.rightMargin: 2; anchors.verticalCenter: parent.verticalCenter
                    height: parent.height - 4; flat: true; icon: "star"; hPad: 4; onDark: win.chromeDark
                    visible: win.current && !win.current.showStart
                    highlighted: visible && Browser.shortcuts && Browser.hasShortcut(win.current.url.toString())
                    activeFocusOnTab: false
                    Accessible.name: highlighted ? qsTr("자주 가는 곳에서 빼기") : qsTr("자주 가는 곳에 추가")
                    onClicked: win.toggleShortcut()
                    MToolTip { text: star.Accessible.name + " (Ctrl+D)" }
                }
            }
            Connections {
                target: address.input
                function onActiveFocusChanged() { if (address.input.activeFocus) Qt.callLater(address.input.selectAll); else win.syncAddress() }
            }
            MButton {
                id: menuButton
                anchors.right: parent.right; anchors.rightMargin: Theme.padding; anchors.verticalCenter: parent.verticalCenter
                flat: true; icon: "menu"; hPad: 6; onDark: win.chromeDark
                highlighted: mainMenu.opened
                Accessible.name: qsTr("메뉴")
                onClicked: win.openMainMenu()
            }
            // 불러오기 진행
            Rectangle {
                anchors.bottom: parent.bottom; height: 2
                width: win.current && win.current.loading ? parent.width * Math.max(0.05, win.current.loadProgress / 100) : 0
                color: Theme.accent
            }
        }
        MSeparator { width: parent.width; visible: !win.pageFullScreen }

        InfoBar {
            id: permissionBar
            width: parent.width; visible: win.permission !== null && win.permission.view === win.current
            icon: "lock"; kind: "warn"
            text: win.permissionText(win.permission)
            actions: [{ text: qsTr("차단"), id: "deny" }, { text: qsTr("허용"), id: "allow", highlighted: true }]
            onTriggered: function(id) { win.answerPermission(id === "allow") }
            onDismissed: win.answerPermission(false)
        }
        Rectangle {
            id: findBar
            width: parent.width; height: visible ? Theme.controlHeight + Theme.padding * 2 : 0
            visible: false
            color: Theme.surfaceRaised
            MSeparator { anchors.bottom: parent.bottom }
            Row {
                x: Theme.padding; anchors.verticalCenter: parent.verticalCenter; spacing: Theme.padding
                MSearchField {
                    id: findField; width: 280; placeholder: qsTr("페이지에서 찾기")
                    Accessible.name: qsTr("페이지에서 찾기")
                    onTextChanged: if (win.current) win.current.findText(text)
                    onAccepted: win.findNext(false)
                }
                MButton { text: "↑"; hPad: 10; enabled: findField.text.length > 0; Accessible.name: qsTr("이전 결과"); onClicked: win.findNext(true)
                          MToolTip { text: qsTr("이전 결과 (Shift+F3)") } }
                MButton { text: "↓"; hPad: 10; enabled: findField.text.length > 0; Accessible.name: qsTr("다음 결과"); onClicked: win.findNext(false)
                          MToolTip { text: qsTr("다음 결과 (F3)") } }
                MLabel {
                    anchors.verticalCenter: parent.verticalCenter; font.pixelSize: Theme.fontSizeSmall; muted: true
                    text: !win.current || !findField.text.length || win.current.findMatches < 0 ? ""
                        : win.current.findMatches === 0 ? qsTr("결과 없음")
                        : qsTr("%1 / %2").arg(win.current.findActive).arg(win.current.findMatches)
                }
            }
            MButton { anchors.right: parent.right; anchors.rightMargin: Theme.padding; anchors.verticalCenter: parent.verticalCenter
                      flat: true; text: "×"; hPad: 8; Accessible.name: qsTr("찾기 닫기"); onClicked: win.closeFind() }
        }

        // 웹 콘텐츠 (탭마다 WebEngineView 하나; 현재 탭만 보인다)
        Item {
            id: content
            width: parent.width
            height: parent.height - y - (downloadBar.visible ? downloadBar.height : 0)
            clip: true
            StartPage {
                id: startPage
                anchors.fill: parent
                visible: win.current !== null && win.current.showStart
                onNavigate: function(text) { win.navigate(text) }
            }
            Rectangle { // 렌더러 종료
                anchors.fill: parent
                visible: win.current !== null && win.current.crashed && !win.current.showStart
                color: Theme.bg
                Column {
                    anchors.centerIn: parent; spacing: Theme.paddingLarge; width: Math.min(parent.width - 64, 480)
                    MIcon { name: "error"; size: Theme.iconSizeLarge; anchors.horizontalCenter: parent.horizontalCenter }
                    MLabel { text: qsTr("페이지가 멈췄습니다"); font.pixelSize: Theme.fontSizeTitle; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
                    MLabel { text: qsTr("메모리가 부족하거나 페이지에 문제가 있어 표시를 멈췄습니다. 다시 불러올 수 있습니다."); wrap: true; width: parent.width; horizontalAlignment: Text.AlignHCenter; muted: true }
                    MButton { text: qsTr("다시 불러오기"); icon: "refresh"; defaultButton: true; anchors.horizontalCenter: parent.horizontalCenter
                              onClicked: { win.current.crashed = false; win.current.reload() } }
                }
            }
            Rectangle { // 링크 주소 미리 보기
                visible: win.current !== null && !win.current.showStart && win.current.hoveredUrl.toString().length > 0
                anchors.left: parent.left; anchors.bottom: parent.bottom
                width: Math.min(hoverText.implicitWidth + Theme.padding * 2, parent.width * 0.6); height: hoverText.implicitHeight + 6
                color: Theme.surface; border.width: Theme.borderWidth; border.color: Theme.border
                MLabel { id: hoverText; x: Theme.padding; anchors.verticalCenter: parent.verticalCenter; width: parent.width - Theme.padding * 2
                         text: win.current ? Browser.displayUrl(win.current.hoveredUrl) : ""; font.pixelSize: Theme.fontSizeSmall; elide: Text.ElideMiddle }
            }
        }
        InfoBar {
            id: downloadBar
            width: parent.width
            visible: win.download !== null && !win.downloadDismissed && !win.pageFullScreen
            icon: "download"
            text: win.downloadText(win.download)
            progress: win.download && win.download.state === WebEngineDownloadRequest.DownloadInProgress && win.download.totalBytes > 0
                      ? win.download.receivedBytes / win.download.totalBytes : -1
            actions: win.download && win.download.state === WebEngineDownloadRequest.DownloadInProgress
                     ? [{ text: qsTr("취소"), id: "cancel" }]
                     : [{ text: qsTr("폴더 보기"), id: "folder", highlighted: true }]
            onTriggered: function(id) {
                if (id === "cancel") win.download.cancel()
                else win.addTab("file://" + encodeURI(win.download.downloadDirectory))
            }
            onDismissed: win.downloadDismissed = true
        }
    }

    MMenu { id: contextMenu; minWidth: 220; onTriggered: function(index, item) { win.contextAction(item.id) } }
    MMenu { id: mainMenu; minWidth: 240; onTriggered: function(index, item) { win.menuAction(item.id) } }
    MOrnamentFrame { anchors.fill: parent; active: win.active; z: 20; visible: !win.pageFullScreen }
}
