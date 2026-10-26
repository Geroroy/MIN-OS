// 하그라 설정 — 창: 연화 띠 · 왼쪽 목차(검색 + 페이지) · 오른쪽 페이지. 창 장식은 labwc(SSD).
// 페이지 이름은 명령줄 --page, 셸 IPC(hagra-shell --settings NAME), 단일 인스턴스 소켓("page:NAME")으로 바뀐다.
import QtQuick
import HagraUI 1.0
import HagraTheme 1.0
import HagraSettings 1.0

Window {
    id: win
    title: "설정 — " + Theme.brandName
    width: 960; height: 640
    minimumWidth: 640; minimumHeight: 440
    color: Theme.surface
    visible: true

    readonly property int inset: Theme.ornamentFrameWidth
    readonly property var pages: [
        { id: "appearance",    title: "모양과 테마",  icon: "lotus",         detail: "테마 · 밝게/어둡게 · 포인트 색 · 커서", src: "pages/AppearancePage.qml", keys: "테마 theme 밝기 dark light 포인트 accent 커서 cursor" },
        { id: "wallpaper",     title: "배경",        icon: "image",         detail: "바탕 화면 이미지", src: "pages/WallpaperPage.qml", keys: "배경 wallpaper 이미지" },
        { id: "display",       title: "디스플레이",   icon: "display",       detail: "해상도 · 배율 · 배치", src: "pages/DisplayPage.qml", keys: "해상도 resolution 배율 scale hidpi 모니터 monitor" },
        { id: "sound",         title: "소리",        icon: "speaker",       detail: "볼륨 · 출력 장치", src: "pages/SoundPage.qml", keys: "볼륨 volume 음소거 mute 오디오 audio" },
        { id: "input",         title: "키보드와 마우스", icon: "keyboard",   detail: "배치 · 한/영 전환 · 반복 · 포인터", src: "pages/InputPage.qml", keys: "키보드 keyboard 마우스 mouse 터치패드 touchpad 배치 layout 한영" },
        { id: "locale",        title: "언어와 지역",  icon: "language",      detail: "표시 언어 · 시간 형식 · 한글 입력기", src: "pages/LocalePage.qml", keys: "언어 language 로케일 locale 시간 time 입력기 ime fcitx 한글" },
        { id: "network",       title: "네트워크",     icon: "network",       detail: "연결 상태 · Wi-Fi", src: "pages/NetworkPage.qml", keys: "네트워크 network wifi 와이파이 유선 ethernet ip" },
        { id: "notifications", title: "알림",        icon: "bell",          detail: "방해 금지 · 알림 서버", src: "pages/NotificationsPage.qml", keys: "알림 notification 방해 dnd" },
        { id: "power",         title: "전원",        icon: "battery",       detail: "배터리 · 절전 · 종료", src: "pages/PowerPage.qml", keys: "전원 power 배터리 battery 절전 suspend 종료" },
        { id: "accessibility", title: "접근성",      icon: "accessibility", detail: "글자 크기 · 포커스 표시 · 커서 크기", src: "pages/AccessibilityPage.qml", keys: "접근성 accessibility 글자 크기 font size 포커스 focus 대비 contrast" },
        { id: "about",         title: "정보",        icon: "info",          detail: "하그라 버전 · 하드웨어 · 로그", src: "pages/AboutPage.qml", keys: "정보 about 버전 version 로그 log 하드웨어" },
    ]
    property string currentId: "appearance"
    property string filter: ""
    readonly property var visiblePages: {
        var f = filter.trim().toLowerCase()
        if (!f.length) return pages
        var out = []
        for (var i = 0; i < pages.length; ++i) { var p = pages[i]
            if ((p.title + " " + p.detail + " " + p.keys).toLowerCase().indexOf(f) >= 0) out.push(p) }
        return out
    }
    function pageIndex(id) { for (var i = 0; i < pages.length; ++i) if (pages[i].id === id) return i; return -1 }
    function openPage(id) {
        if (pageIndex(id) < 0) { console.warn("unknown settings page:", id); id = "appearance" }
        currentId = id
        var p = pages[pageIndex(id)]
        loader.source = Qt.resolvedUrl(p.src)
    }
    function handleCommand(line) {   // 단일 인스턴스 소켓: "raise" | "page:NAME"
        if (line.indexOf("page:") === 0) openPage(line.substring(5))
        win.show(); win.raise(); win.requestActivate()
    }
    Component.onCompleted: openPage(initialPage && initialPage.length ? initialPage : "appearance")

    Column {
        anchors.fill: parent; anchors.margins: win.inset; spacing: 0
        MOrnamentBand { width: parent.width }
        MSeparator { width: parent.width }
        Row { width: parent.width; height: parent.height - y
            // 목차
            Rectangle { id: side; width: 232; height: parent.height; color: Theme.sidebar
                readonly property bool dark: Theme.isDark(Theme.sidebar)
                Column { anchors.fill: parent; anchors.topMargin: Theme.padding; spacing: Theme.padding
                    MSearchField { id: pageSearch; x: Theme.padding; width: parent.width - Theme.padding * 2; placeholder: "설정 검색"
                                   onTextChanged: win.filter = text; Accessible.name: "설정 검색" }
                    ListView {
                        id: nav
                        x: Theme.padding; width: parent.width - Theme.padding * 2; height: parent.height - y - Theme.padding
                        clip: true; model: win.visiblePages; keyNavigationEnabled: true
                        currentIndex: { for (var i = 0; i < win.visiblePages.length; ++i) if (win.visiblePages[i].id === win.currentId) return i; return -1 }
                        activeFocusOnTab: true
                        Keys.onReturnPressed: if (currentIndex >= 0) win.openPage(win.visiblePages[currentIndex].id)
                        Keys.onSpacePressed: if (currentIndex >= 0) win.openPage(win.visiblePages[currentIndex].id)
                        onCurrentIndexChanged: if (activeFocus && currentIndex >= 0 && win.visiblePages[currentIndex].id !== win.currentId) win.openPage(win.visiblePages[currentIndex].id)
                        delegate: MListRow {
                            required property var modelData
                            required property int index
                            text: modelData.title; icon: modelData.icon; onDark: side.dark
                            selected: modelData.id === win.currentId
                            focusVisible: nav.activeFocus && nav.currentIndex === index
                            implicitHeight: Theme.rowHeight + 2
                            onClicked: win.openPage(modelData.id)
                            Accessible.name: modelData.title + ". " + modelData.detail
                        }
                        MLabel { anchors.centerIn: parent; visible: nav.count === 0; text: "일치하는 설정이 없습니다"; muted: true; font.pixelSize: Theme.fontSizeSmall }
                    }
                }
                Image { anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; height: 56
                        source: Theme.asset("lattice-tile"); fillMode: Image.Tile; sourceSize: Qt.size(48, 48); opacity: 0.35; smooth: true }
                MSeparator { vertical: true; anchors.right: parent.right; color: side.dark ? Theme.borderStrong : Theme.border }
            }
            // 페이지
            Loader { id: loader; width: parent.width - side.width; height: parent.height; asynchronous: false
                     onStatusChanged: if (status === Loader.Error) console.warn("settings page failed to load:", source) }
        }
    }
    MOrnamentFrame { anchors.fill: parent; active: win.active; z: 20 }
}
