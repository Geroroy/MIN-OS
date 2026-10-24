// 대표 장면 1: "하그라 바탕화면에서 파일 관리자를 열고, 문서 폴더의 파일을 선택하는 장면" — 디자인 검증용 화면.
// ※ 예제 데이터만 표시하는 미리보기이며 실제 파일 작업은 하지 않는다. 실제 파일 관리자는 M3(files/).
// 실행: minui-preview design/scenes/FilesScene.qml [--state menu|dialog]   캡처: tests/design/capture-scene.sh
import QtQuick
import MinUI 1.0

Window {
    id: win
    title: "문서 — 하그라 파일"
    width: 880; height: 560
    color: Theme.bg
    visible: true

    readonly property var files: [
        { name: "2026년 3분기 보고서 (최종) v2.pdf", type: "PDF 문서", date: "2026-10-23 14:02", size: "1.2 MB", icon: "file", folder: false },
        { name: "회의록_10월23일_김민수.docx", type: "문서", date: "2026-10-23 11:40", size: "84 KB", icon: "file", folder: false },
        { name: "예산안", type: "폴더", date: "2026-10-21 09:15", size: "—", icon: "folder", folder: true },
        { name: "사진 정리 — 제주 2026", type: "폴더", date: "2026-10-18 20:31", size: "—", icon: "folder", folder: true },
        { name: "매우 긴 파일 이름을 가진 문서 — 길이가 긴 텍스트가 열 너비를 넘을 때 말줄임이 어떻게 보이는지 확인하기 위한 예제 파일.txt", type: "텍스트", date: "2026-10-17 08:00", size: "3 KB", icon: "file", folder: false },
        { name: "Invoice_2026-10_HAGRA.xlsx", type: "스프레드시트", date: "2026-10-15 17:22", size: "41 KB", icon: "file", folder: false },
        { name: "계약서 초안 (검토용).hwpx", type: "한글 문서", date: "2026-10-12 13:05", size: "220 KB", icon: "file", folder: false },
        { name: "notes.md", type: "Markdown", date: "2026-10-10 22:48", size: "2 KB", icon: "file", folder: false },
        { name: "발표자료_하그라_소개.key", type: "프레젠테이션", date: "2026-10-08 10:30", size: "18.4 MB", icon: "file", folder: false },
        { name: "백업 2026-09", type: "폴더", date: "2026-09-30 23:59", size: "—", icon: "folder", folder: true }
    ]
    property int selectedIndex: 1
    property int focusIndex: 1
    // 열 너비 (논리 px). 이름 열은 나머지 공간.
    readonly property int colType: 120
    readonly property int colDate: 140
    readonly property int colSize: 80
    readonly property int rowInset: Theme.paddingLarge * 2 + Theme.iconSize + Theme.paddingLarge * 4

    Component.onCompleted: list.forceActiveFocus()
    // 레이아웃(Column/Row 배치)이 끝난 뒤에 열어야 위치가 맞는다 → 짧은 타이머
    Timer { interval: 300; running: previewState === "menu" || previewState === "dialog"; repeat: false
            onTriggered: { if (previewState === "menu") contextMenu.open(list, 220, 24 * 1 + 14); else confirm.show() } }

    Column {
        anchors.fill: parent
        // ---- 도구 막대: 뒤로/앞으로, 경로, 검색 ----
        Rectangle { width: parent.width; height: Theme.controlHeight + Theme.paddingLarge * 2; color: Theme.surface
            Row { anchors.fill: parent; anchors.margins: Theme.paddingLarge; spacing: Theme.padding
                MButton { text: "‹"; hPad: 8; MToolTip { text: "뒤로 (Alt+←)" } }
                MButton { text: "›"; hPad: 8; enabled: false }
                MButton { text: "↑"; hPad: 8 }
                Item { width: Theme.padding; height: 1 }
                Row { id: crumbs; spacing: 0; anchors.verticalCenter: parent.verticalCenter
                    Repeater { model: ["홈", "문서"]; delegate: Row { required property int index; required property string modelData; spacing: 0
                        MButton { flat: true; text: modelData; highlighted: index === 1; hPad: 6 }
                        MLabel { visible: index < 1; text: "›"; muted: true; anchors.verticalCenter: parent.verticalCenter; leftPadding: 2; rightPadding: 2 } } }
                }
                Item { width: parent.width - crumbs.width - 3 * (24 + Theme.padding) - Theme.padding - search.width - Theme.padding * 2; height: 1 }
                MSearchField { id: search; width: 200; placeholder: "문서에서 검색" }
            }
        }
        MSeparator { width: parent.width }

        Row { width: parent.width; height: win.height - y - status.height
            // ---- 탐색 영역 ----
            Rectangle { id: side; width: 180; height: parent.height; color: Theme.surface
                Column { width: parent.width; y: Theme.paddingLarge
                    MLabel { text: "즐겨찾기"; muted: true; font.pixelSize: Theme.fontSizeSmall; leftPadding: Theme.paddingLarge; height: Theme.rowHeight }
                    MListRow { text: "홈"; icon: "home"; leftPadding: Theme.paddingLarge }
                    MListRow { text: "문서"; icon: "folder"; selected: true; leftPadding: Theme.paddingLarge }
                    MListRow { text: "다운로드"; icon: "download"; leftPadding: Theme.paddingLarge }
                    MListRow { text: "사진"; icon: "image"; leftPadding: Theme.paddingLarge }
                    MListRow { text: "휴지통"; icon: "trash"; leftPadding: Theme.paddingLarge }
                    Item { width: 1; height: Theme.paddingLarge }
                    MLabel { text: "장치"; muted: true; font.pixelSize: Theme.fontSizeSmall; leftPadding: Theme.paddingLarge; height: Theme.rowHeight }
                    MListRow { text: "하그라 (시스템)"; icon: "drive"; leftPadding: Theme.paddingLarge }
                    MListRow { text: "USB 드라이브 (32 GB)"; icon: "usb"; leftPadding: Theme.paddingLarge }
                }
                MSeparator { vertical: true; anchors.right: parent.right }
            }
            // ---- 파일 목록 ----
            Item { width: parent.width - side.width; height: parent.height
                Rectangle { id: header; width: parent.width; height: Theme.rowHeight + 4; color: Theme.surface
                    Row { anchors.fill: parent; anchors.leftMargin: Theme.paddingLarge + Theme.iconSize + Theme.paddingLarge; anchors.rightMargin: Theme.paddingLarge + Theme.scrollBarWidth; spacing: Theme.paddingLarge
                        MLabel { text: "이름 ▴"; width: parent.width - win.colType - win.colDate - win.colSize - Theme.paddingLarge * 3; muted: true; font.pixelSize: Theme.fontSizeSmall; height: parent.height }
                        MLabel { text: "종류"; width: win.colType; muted: true; font.pixelSize: Theme.fontSizeSmall; height: parent.height }
                        MLabel { text: "수정한 날짜"; width: win.colDate; muted: true; font.pixelSize: Theme.fontSizeSmall; height: parent.height }
                        MLabel { text: "크기"; width: win.colSize; muted: true; font.pixelSize: Theme.fontSizeSmall; height: parent.height; horizontalAlignment: Text.AlignRight }
                    }
                    MSeparator { anchors.bottom: parent.bottom }
                }
                ListView {
                    id: list
                    anchors.top: header.bottom; anchors.bottom: parent.bottom; width: parent.width - Theme.scrollBarWidth
                    model: win.files
                    clip: true
                    currentIndex: win.focusIndex
                    highlightMoveDuration: Theme.motionDuration
                    keyNavigationEnabled: true
                    Keys.onSpacePressed: win.selectedIndex = currentIndex
                    Keys.onReturnPressed: win.selectedIndex = currentIndex
                    Keys.onDeletePressed: confirm.show()
                    Keys.onMenuPressed: contextMenu.open(list, 180, (currentIndex + 1) * 24)
                    onCurrentIndexChanged: win.focusIndex = currentIndex
                    delegate: Rectangle {
                        required property int index
                        required property var modelData
                        width: list.width; height: 24
                        readonly property bool sel: index === win.selectedIndex
                        readonly property bool foc: index === list.currentIndex && list.activeFocus
                        color: sel ? Theme.selection : (hov.containsMouse ? Theme.surfaceRaised : "transparent")
                        Rectangle { visible: sel; width: Theme.selectionMarkerWidth; height: parent.height; color: Theme.accentText; opacity: 0.9 }
                        Rectangle { visible: foc; anchors.fill: parent; color: "transparent"; border.width: Theme.focusRingWidth; border.color: sel ? Theme.selectionText : Theme.focusRing }
                        Row { anchors.fill: parent; anchors.leftMargin: Theme.paddingLarge; anchors.rightMargin: Theme.paddingLarge; spacing: Theme.paddingLarge
                            MIcon { name: modelData.icon; anchors.verticalCenter: parent.verticalCenter; color: sel ? Theme.selectionText : Theme.textMuted }
                            MLabel { text: modelData.name; width: parent.width - Theme.iconSize - win.colType - win.colDate - win.colSize - Theme.paddingLarge * 4; height: parent.height; font.bold: sel
                                     color: sel ? Theme.selectionText : Theme.text }
                            MLabel { text: modelData.type; width: win.colType; height: parent.height; color: sel ? Theme.selectionText : Theme.textMuted }
                            MLabel { text: modelData.date; width: win.colDate; height: parent.height; color: sel ? Theme.selectionText : Theme.textMuted }
                            MLabel { text: modelData.size; width: win.colSize; height: parent.height; horizontalAlignment: Text.AlignRight; color: sel ? Theme.selectionText : Theme.textMuted }
                        }
                        MouseArea { id: hov; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: (e) => { list.currentIndex = index; win.selectedIndex = index; list.forceActiveFocus()
                                                if (e.button === Qt.RightButton) contextMenu.open(list, e.x, y + e.y) } }
                    }
                }
                MScrollBar { flickable: list; anchors.right: parent.right; anchors.top: header.bottom; anchors.bottom: parent.bottom }
            }
        }
        // ---- 상태 표시줄 ----
        Rectangle { id: status; width: parent.width; height: Theme.rowHeight + 2; color: Theme.surface
            MSeparator { anchors.top: parent.top }
            MLabel { anchors.left: parent.left; anchors.leftMargin: Theme.paddingLarge; anchors.verticalCenter: parent.verticalCenter
                     text: win.files.length + "개 항목 · 1개 선택 (" + win.files[win.selectedIndex].size + ") · 문서 폴더 — 예제 데이터, 실제 파일 아님"; muted: true; font.pixelSize: Theme.fontSizeSmall }
        }
    }

    MMenu { id: contextMenu; items: [
        { text: "열기", shortcut: "Enter" }, { text: "다른 앱으로 열기…" }, { separator: true },
        { text: "복사", shortcut: "Ctrl+C" }, { text: "잘라내기", shortcut: "Ctrl+X" }, { text: "붙여넣기", shortcut: "Ctrl+V", enabled: false },
        { text: "이름 바꾸기", shortcut: "F2" }, { separator: true }, { text: "휴지통으로 이동", shortcut: "Delete" }, { text: "속성", shortcut: "Alt+Enter" } ]
        onTriggered: (i, item) => { if (item.text === "휴지통으로 이동") confirm.show() } }

    MDialogWindow { id: confirm; dialogTitle: "휴지통으로 이동"; transientParent: win
        message: "‘" + win.files[win.selectedIndex].name + "’ 을(를) 휴지통으로 이동할까요?\n나중에 복원할 수 있습니다."
        buttons: [ { text: "취소", role: "reject" }, { text: "이동", role: "accept", isDefault: true } ] }
}
