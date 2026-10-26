// 대표 장면 1: "하그라 바탕화면에서 파일 관리자를 열고, 문서 폴더의 파일을 선택하는 장면" — 디자인 검증용 화면.
// ※ 예제 데이터만 표시하는 미리보기이며 실제 파일 작업은 하지 않는다 (복사·삭제·마운트 없음). 실제 파일 관리자는 M3(files/).
//    기준 시안: design/hagra-dancheong-v1/reference/hagra-dancheong-concept.png (파일 창).
//    창 제목줄·외곽 경계는 labwc(SSD)가 그리고, 그 안쪽의 연화 띠·모서리 결구·창살은 앱 내부 장식(MOrnamentBand/Frame)이다.
// 실행: minui-preview design/scenes/FilesScene.qml [--state menu|dialog]   캡처: tests/design/capture-scene.sh
import QtQuick
import MinUI 1.0

Window {
    id: win
    title: "파일 — 문서"
    width: 880; height: 560
    minimumWidth: 480; minimumHeight: 320
    color: Theme.surface
    visible: true

    // 예제 데이터 (실제 파일 아님). 날짜는 예제 값이며 런타임 시계를 흉내 내지 않는다.
    readonly property var items: [
        { name: "글쓰기",        kind: "folder", icon: "folder-writing",     type: "폴더",      date: "2026년 10월 24일 오전 10:24", size: "—" },
        { name: "번역",          kind: "folder", icon: "folder-translation", type: "폴더",      date: "2026년 10월 22일 오후 3:10",  size: "—" },
        { name: "자료",          kind: "folder", icon: "folder-reference",   type: "폴더",      date: "2026년 10월 21일 오전 9:15",  size: "—" },
        { name: "프로젝트",      kind: "folder", icon: "folder-project",     type: "폴더",      date: "2026년 10월 18일 오후 8:31",  size: "—" },
        { name: "번역 노트.txt", kind: "file",   icon: "document", badge: "TXT", type: "텍스트",  date: "2026년 10월 17일 오전 8:00",  size: "3 KB" },
        { name: "학업 계획.pdf", kind: "file",   icon: "document", badge: "PDF", type: "PDF 문서", date: "2026년 10월 24일 오전 10:24", size: "1.2 MB" },
        { name: "답사 사진.jpg", kind: "file",   icon: "document", badge: "JPG", type: "이미지",   date: "2026년 10월 15일 오후 5:22",  size: "4.8 MB" },
        { name: "매우 긴 파일 이름을 가진 문서 — 말줄임 확인용 Example_Report_2026_Q3_final_v2.hwpx", kind: "file", icon: "document", badge: "HWPX", type: "한글 문서", date: "2026년 10월 12일 오후 1:05", size: "220 KB" }
    ]
    property int selectedIndex: 5
    readonly property int inset: Theme.ornamentFrameWidth

    Component.onCompleted: { grid.forceActiveFocus(); grid.positionViewAtBeginning() }
    // 레이아웃이 끝난 뒤 열어야 위치가 맞는다 → 짧은 타이머
    Timer { interval: 300; running: previewState === "menu" || previewState === "dialog"; repeat: false
            onTriggered: { if (previewState === "menu") { var it = grid.currentItem; var p = it.mapToItem(grid, it.width / 2, it.height / 2); contextMenu.open(grid, p.x, p.y) } else confirm.show() } }

    Column {
        id: content
        anchors.fill: parent
        anchors.margins: win.inset
        spacing: 0

        // ---- 제목 아래 연화 띠 (앱 내부 장식; 클릭 영역 없음) ----
        MOrnamentBand { width: parent.width }
        MSeparator { width: parent.width }

        // ---- 도구 막대 ----
        Rectangle { id: toolbar; width: parent.width; height: Theme.controlHeight + Theme.padding * 2; color: Theme.surfaceRaised
            Row { anchors.left: parent.left; anchors.leftMargin: Theme.padding; anchors.verticalCenter: parent.verticalCenter; spacing: Theme.padding
                MButton { flat: true; icon: "back"; hPad: 6; MToolTip { text: "뒤로 (Alt+←) — 예제" } }
                MButton { flat: true; icon: "forward"; hPad: 6; enabled: false; MToolTip { text: "앞으로 — 예제" } }
                MButton { flat: true; icon: "home"; hPad: 6; MToolTip { text: "홈 — 예제" } }
                MSeparator { vertical: true; height: Theme.controlHeight - Theme.padding; anchors.verticalCenter: parent.verticalCenter }
                Row { id: crumbs; spacing: 0; anchors.verticalCenter: parent.verticalCenter
                    Repeater { model: ["홈", "문서"]; delegate: Row { required property int index; required property string modelData; spacing: 0
                        MButton { flat: true; text: modelData; bold: index === 1; hPad: 6 }
                        MLabel { visible: index < 1; text: "/"; muted: true; anchors.verticalCenter: parent.verticalCenter; leftPadding: 4; rightPadding: 4 } } }
                }
            }
            Row { anchors.right: parent.right; anchors.rightMargin: Theme.padding; anchors.verticalCenter: parent.verticalCenter; spacing: Theme.padding
                MSearchField { id: search; width: Math.min(240, toolbar.width - crumbs.width - 300); placeholder: "검색" }
                MSeparator { vertical: true; height: Theme.controlHeight - Theme.padding; anchors.verticalCenter: parent.verticalCenter }
                MButton { flat: true; icon: "view-grid"; hPad: 6; highlighted: true; MToolTip { text: "아이콘 보기 (현재)" } }
                MButton { flat: true; icon: "view-list"; hPad: 6; enabled: false; MToolTip { text: "목록 보기 — 예제에서는 사용할 수 없음" } }
            }
            MSeparator { anchors.bottom: parent.bottom }
        }

        // ---- 본문: 탐색 영역 + 파일 격자 ----
        Row { width: parent.width; height: content.height - y - status.height
            Rectangle { id: side; width: Math.min(180, parent.width / 4); height: parent.height; color: Theme.sidebar
                readonly property bool dark: Theme.isDark(Theme.sidebar)
                Column { id: sideList; width: parent.width; y: Theme.padding
                    Repeater {
                        model: [ { t: "홈", i: "home" }, { t: "문서", i: "file" }, { t: "다운로드", i: "download" }, { t: "사진", i: "image" }, { t: "휴지통", i: "trash" } ]
                        delegate: MListRow { required property var modelData; required property int index
                            text: modelData.t; icon: modelData.i; selected: index === 1; leftPadding: Theme.paddingLarge; onDark: side.dark }
                    }
                }
                // 사이드바 하단: 옅은 창살 + 연꽃 매듭 포인트 (목록 행 뒤에는 두지 않는다)
                Item { anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                       height: Math.max(0, Math.min(96, side.height - sideList.height - Theme.paddingLarge * 3))
                    Image { anchors.fill: parent; source: Theme.asset("lattice-tile"); fillMode: Image.Tile; sourceSize: Qt.size(48, 48); opacity: 0.55; smooth: true }
                    MOrnamentDivider { anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: Theme.paddingLarge; height: 20 }
                }
                MSeparator { vertical: true; anchors.right: parent.right; color: side.dark ? Theme.borderStrong : Theme.border }
            }
            Item { width: parent.width - side.width; height: parent.height
                GridView {
                    id: grid
                    anchors.fill: parent; anchors.margins: Theme.paddingLarge; anchors.rightMargin: Theme.paddingLarge + Theme.scrollBarWidth
                    model: win.items
                    clip: true
                    cellWidth: Math.max(140, Math.floor(width / Math.max(1, Math.floor(width / 190))))
                    cellHeight: Theme.folderIconSize + Theme.paddingLarge * 2 + Theme.fontSize * 2   // 134: 880×560 에서 3행이 스크롤 없이 들어간다
                    currentIndex: win.selectedIndex
                    highlightMoveDuration: Theme.motionDuration
                    keyNavigationEnabled: true
                    activeFocusOnTab: true
                    Keys.onSpacePressed: win.selectedIndex = currentIndex
                    Keys.onReturnPressed: win.selectedIndex = currentIndex
                    Keys.onDeletePressed: confirm.show()
                    Keys.onMenuPressed: { var it = currentItem; var p = it.mapToItem(grid, it.width / 2, it.height / 2); contextMenu.open(grid, p.x, p.y) }
                    delegate: Item {
                        required property int index
                        required property var modelData
                        width: grid.cellWidth; height: grid.cellHeight
                        readonly property bool sel: index === win.selectedIndex
                        readonly property bool foc: index === grid.currentIndex && grid.activeFocus
                        Rectangle { // 선택 바탕 (연살구) — 포커스 링과 별개
                            id: cell
                            anchors.fill: parent; anchors.margins: Theme.padding
                            radius: Theme.radius
                            color: sel ? Theme.selection : (hov.containsMouse ? Theme.surfaceRaised : "transparent")
                            border.width: sel ? 1 : 0; border.color: Theme.ochre
                        }
                        Rectangle { // 키보드 포커스 2px, 장식 경계보다 앞
                            visible: foc; anchors.fill: cell; z: 5; color: "transparent"; radius: Theme.radius
                            border.width: Theme.focusRingWidth; border.color: Theme.focusRing
                        }
                        Column { anchors.fill: cell; anchors.margins: Theme.padding; spacing: Theme.padding
                            Item { width: parent.width; height: Theme.folderIconSize + Theme.padding
                                MIcon { id: ic; name: modelData.icon; size: Theme.folderIconSize; anchors.centerIn: parent }
                                Rectangle { // 문서 유형 배지 (작은 크기에서도 유형 구분)
                                    visible: modelData.kind === "file"
                                    anchors.right: ic.right; anchors.bottom: ic.bottom; anchors.margins: -2
                                    width: badge.implicitWidth + 8; height: badge.implicitHeight + 2; radius: Theme.radius
                                    color: Theme.surface; border.width: 1; border.color: Theme.borderStrong
                                    Text { id: badge; anchors.centerIn: parent; text: modelData.badge || ""; color: Theme.textMuted
                                           font.family: Theme.fontFamily; font.pixelSize: 10; font.bold: true; renderType: Text.NativeRendering }
                                }
                            }
                            MLabel { width: parent.width; horizontalAlignment: Text.AlignHCenter; text: modelData.name; font.bold: sel
                                     color: sel ? Theme.selectionText : Theme.text; elide: Text.ElideMiddle }
                        }
                        MouseArea { id: hov; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: (e) => { grid.currentIndex = index; win.selectedIndex = index; grid.forceActiveFocus()
                                                if (e.button === Qt.RightButton) contextMenu.open(grid, x + e.x, y + e.y) } }
                    }
                }
                MScrollBar { flickable: grid; anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom; anchors.margins: Theme.padding }
            }
        }

        // ---- 상태 표시줄 ----
        Rectangle { id: status; width: parent.width; height: Theme.rowHeight; color: Theme.surfaceRaised
            MSeparator { anchors.top: parent.top }
            Row { anchors.left: parent.left; anchors.leftMargin: Theme.paddingLarge; anchors.verticalCenter: parent.verticalCenter; spacing: Theme.padding
                MLabel { text: win.items.length + "개 항목"; muted: true; font.pixelSize: Theme.fontSizeSmall }
                MSeparator { vertical: true; height: Theme.fontSize; anchors.verticalCenter: parent.verticalCenter }
                MLabel { text: "1개 항목 선택함 (" + win.items[win.selectedIndex].size + ")"; muted: true; font.pixelSize: Theme.fontSizeSmall }
                MSeparator { vertical: true; height: Theme.fontSize; anchors.verticalCenter: parent.verticalCenter }
                MLabel { text: "예제 데이터"; muted: true; font.pixelSize: Theme.fontSizeSmall }
            }
            MOrnamentDivider { anchors.centerIn: parent; width: Math.min(200, parent.width / 4); height: 20; visible: parent.width > 640 }
            MLabel { anchors.right: parent.right; anchors.rightMargin: Theme.paddingLarge; anchors.verticalCenter: parent.verticalCenter
                     text: "수정한 날짜  " + win.items[win.selectedIndex].date; muted: true; font.pixelSize: Theme.fontSizeSmall }
        }
    }

    // 앱 내부 장식 프레임: 겹선 + 네 모서리 결구 (labwc SSD 가 아니다). 콘텐츠는 inset 만큼 안쪽에 있다.
    MOrnamentFrame { anchors.fill: parent; active: win.active; z: 20 }

    MMenu { id: contextMenu; items: [
        { text: "열기", shortcut: "Enter" }, { text: "다른 앱으로 열기…" }, { separator: true },
        { text: "복사", shortcut: "Ctrl+C" }, { text: "잘라내기", shortcut: "Ctrl+X" }, { text: "붙여넣기", shortcut: "Ctrl+V", enabled: false },
        { text: "이름 바꾸기", shortcut: "F2" }, { separator: true }, { text: "휴지통으로 이동", shortcut: "Delete" }, { text: "속성", shortcut: "Alt+Enter" } ]
        onTriggered: (i, item) => { if (item.text === "휴지통으로 이동") confirm.show() } }

    MDialogWindow { id: confirm; dialogTitle: "휴지통으로 이동"; transientParent: win
        message: "‘" + win.items[win.selectedIndex].name + "’ 을(를) 휴지통으로 이동할까요?\n나중에 복원할 수 있습니다. (예제: 실제로 이동하지 않습니다)"
        buttons: [ { text: "취소", role: "reject" }, { text: "이동", role: "accept", isDefault: true } ] }
}
