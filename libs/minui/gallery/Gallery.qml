// MinUI 공통 부품 갤러리 — 같은 실행 환경(labwc + Qt Wayland)에서 부품·상태·혼합 문자열·긴 문자열·키보드 포커스·배율을 확인한다.
// 실행: build/tools/preview/minui-preview libs/minui/gallery/Gallery.qml --state buttons|inputs|selection|lists|feedback|text|frame [--scale 1.5]
// 캡처: tests/design/capture-gallery.sh
import QtQuick
import MinUI 1.0

Window {
    id: win
    readonly property string section: previewState && previewState.length ? previewState : "buttons"
    readonly property string mixed: "보고서_2026년3분기_v2 Final (김민수) 10월23일.pdf"
    readonly property string longText: "하그라는 한국의 미감과 생활에 대한 이해를 바탕으로, 누구나 자기 일을 편안하게 해낼 수 있도록 만드는 운영체제입니다. This sentence mixes Hangul, Latin letters and digits 1234567890 to verify line wrapping, baseline alignment and glyph fallback across fonts at 100 %, 150 % and 200 % scale."
    title: "MinUI 갤러리 — " + section + " · 배율 " + Math.round(previewScale * 100) + "%"
    width: 600; height: 330
    color: Theme.bg
    visible: true

    Column {
        anchors.fill: parent; anchors.margins: Theme.paddingLarge
        spacing: Theme.paddingLarge

        Row { spacing: Theme.paddingLarge
            MLabel { text: "MinUI · " + win.section; font.bold: true; font.pixelSize: Theme.fontSizeTitle }
            MLabel { text: "토큰 " + Theme.tokenSet + " (" + Theme.tokenStatus + ") · 배율 " + Math.round(previewScale * 100) + "% · 논리 600×330"; muted: true; font.pixelSize: Theme.fontSizeSmall; anchors.verticalCenter: parent.verticalCenter }
        }
        MSeparator { width: parent.width }

        // ---- 버튼 ----
        Column { visible: win.section === "buttons"; spacing: Theme.paddingLarge; width: parent.width
            Row { spacing: Theme.paddingLarge
                MButton { text: "기본" }
                MButton { text: "호버 (포인터)"; }
                MButton { text: "선택됨"; highlighted: true }
                MButton { text: "키보드 포커스"; focus: true }
                MButton { text: "비활성"; enabled: false }
                MButton { text: "오류"; error: true }
                MButton { text: "진행 중"; busy: true }
            }
            Row { spacing: Theme.paddingLarge
                MButton { text: "기본 버튼 (Enter)"; defaultButton: true }
                MButton { text: "삭제"; danger: true }
                MButton { text: "평면"; flat: true }
                MButton { text: "아이콘"; icon: "folder" }
                MButton { text: "확인"; bold: true }
            }
            Row { spacing: Theme.paddingLarge
                MButton { text: "매우 긴 라벨: 설정을 저장하고 모든 창을 닫은 뒤 다시 시작" }
                MButton { text: "Longer English label for width check" }
            }
            MLabel { text: "탭(Tab)으로 포커스 이동, Space/Enter 로 실행. 선택 = 하단 막대, 포커스 = 바깥 링."; muted: true; font.pixelSize: Theme.fontSizeSmall }
        }

        // ---- 입력 ----
        Column { visible: win.section === "inputs"; spacing: Theme.paddingLarge; width: parent.width
            Row { spacing: Theme.paddingLarge
                MTextField { placeholder: "기본 (자리 표시 문구)" }
                MTextField { text: win.mixed; width: 220 }
                MTextField { text: "포커스"; focus: win.section === "inputs"; width: 100 }
            }
            Row { spacing: Theme.paddingLarge
                MTextField { text: "비활성"; enabled: false }
                MTextField { text: "잘못된 값"; error: true; errorText: "파일 이름에 ‘/’ 를 쓸 수 없습니다" }
                MTextField { text: "저장 중"; busy: true }
            }
            Row { spacing: Theme.paddingLarge
                MSearchField { width: 200 }
                MSearchField { width: 220; text: "회의록 10월" }
                MTextField { text: "비밀번호"; echoMode: TextInput.Password; width: 120 }
            }
            MLabel { text: "한글 조합 중에는 오른쪽에 ‘한’ 표시가 나타난다 (IME 연결 시). 오류 문구는 입력란 아래에 표시."; muted: true; font.pixelSize: Theme.fontSizeSmall }
        }

        // ---- 선택 ----
        Column { visible: win.section === "selection"; spacing: Theme.paddingLarge; width: parent.width
            MRadioGroup { id: rg }
            Row { spacing: Theme.paddingLarge * 2
                Column { spacing: Theme.padding
                    MCheckBox { text: "기본" }
                    MCheckBox { text: "선택됨"; checked: true }
                    MCheckBox { text: "포커스"; focus: win.section === "selection" }
                    MCheckBox { text: "비활성"; enabled: false; checked: true }
                    MCheckBox { text: "오류 — 약관에 동의해야 합니다"; error: true }
                }
                Column { spacing: Theme.padding
                    MRadioButton { group: rg; text: "라디오 1 (선택)"; Component.onCompleted: rg.select(this) }
                    MRadioButton { group: rg; text: "라디오 2" }
                    MRadioButton { group: rg; text: "라디오 3 긴 설명 텍스트 1234567890" }
                    MRadioButton { group: rg; text: "비활성"; enabled: false }
                }
                Column { spacing: Theme.paddingLarge
                    MComboBox { model: ["이름순", "수정일순", "크기순", "종류순"]; currentIndex: 1 }
                    MComboBox { model: ["비활성"]; enabled: false }
                    MComboBox { model: ["오류"]; error: true }
                }
            }
            MTabBar { tabs: ["일반", "공유", "권한", "Details", "매우 긴 탭 이름 검증"]; currentIndex: 0; width: parent.width }
        }

        // ---- 목록 / 스크롤 / 메뉴 ----
        Row { visible: win.section === "lists"; spacing: Theme.paddingLarge * 2; width: parent.width
            Rectangle { width: 300; height: 200; color: Theme.surface; border.width: 1; border.color: Theme.border
                Flickable { id: fl; anchors.fill: parent; anchors.rightMargin: Theme.scrollBarWidth; contentHeight: lcol.height; clip: true
                    Column { id: lcol; width: fl.width
                        MListRow { text: "기본 행"; detail: "설명" ; icon: "file" }
                        MListRow { text: "호버 행 (포인터)"; icon: "file" }
                        MListRow { text: "선택된 행"; selected: true; detail: "12 KB"; icon: "file" }
                        MListRow { text: "선택 + 키보드 포커스"; selected: true; focusVisible: true; icon: "folder" }
                        MListRow { text: "키보드 포커스만"; focusVisible: true; icon: "folder" }
                        MListRow { text: "비활성 행"; enabled: false; icon: "file" }
                        MListRow { text: win.mixed; detail: "2026-10-23"; icon: "file" }
                        Repeater { model: 8; delegate: MListRow { required property int index; text: "항목 " + (index + 8) + " — item"; detail: (index * 37) + " KB"; icon: "file" } }
                    }
                }
                MScrollBar { flickable: fl; anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom }
            }
            Column { spacing: Theme.paddingLarge
                MButton { id: menuBtn; text: "메뉴 열기 ▾"; onClicked: demoMenu.open(menuBtn, 0, menuBtn.height + 2)
                    Timer { interval: 300; running: win.section === "lists"; onTriggered: demoMenu.open(menuBtn, 0, menuBtn.height + 2) } }
                MMenu { id: demoMenu; items: [
                    { text: "열기", shortcut: "Enter" }, { text: "새 창에서 열기", shortcut: "Ctrl+Enter" }, { separator: true },
                    { text: "이름 바꾸기", shortcut: "F2" }, { text: "복사", shortcut: "Ctrl+C" }, { text: "붙여넣기", shortcut: "Ctrl+V", enabled: false },
                    { separator: true }, { text: "숨긴 파일 표시", checked: true }, { text: "휴지통으로 이동", shortcut: "Delete" } ] }
                MLabel { text: "↑↓ 이동, Enter 실행, Esc 닫기.\n메뉴·툴팁·드롭다운은 창 안에서만 표시된다."; muted: true; font.pixelSize: Theme.fontSizeSmall; wrap: true; width: 240 }
            }
        }

        // ---- 피드백 ----
        Row { visible: win.section === "feedback"; spacing: Theme.paddingLarge * 2; width: parent.width
            Column { spacing: Theme.paddingLarge
                MLabel { text: "진행 표시"; muted: true; font.pixelSize: Theme.fontSizeSmall }
                MProgressBar { value: 0.35; width: 200 }
                MProgressBar { indeterminate: true; width: 200 }
                MProgressBar { value: 0.6; error: true; width: 200 }
                MButton { id: tipBtn; text: "툴팁 (호버)"; MToolTip { text: "툴팁: 600ms 뒤 표시. 긴 문장도 최대 너비에서 줄바꿈된다 — long tooltip text wraps." } }
                MNotification { appName: "하그라 파일"; title: "복사 완료"; body: "‘" + win.mixed + "’ 을(를) 문서 폴더로 복사했습니다."; actions: [{ text: "열기" }, { text: "폴더 보기" }]; width: 300 }
            }
            MDialogContent { width: 260; title: "휴지통으로 이동"; message: "‘" + win.mixed + "’ 파일을 휴지통으로 이동할까요? 나중에 복원할 수 있습니다."
                buttons: [ { text: "취소", role: "reject" }, { text: "이동", role: "accept", isDefault: true } ]
                Rectangle { anchors.fill: parent; z: -1; anchors.margins: -1; color: "transparent"; border.width: 1; border.color: Theme.borderStrong } }
        }

        // ---- 텍스트 ----
        Column { visible: win.section === "text"; spacing: Theme.paddingLarge; width: parent.width
            MLabel { text: "제목 13px · 하그라 HAGRA 1234567890"; font.pixelSize: Theme.fontSizeTitle; font.bold: true }
            MLabel { text: "본문 12px · " + win.mixed }
            MLabel { text: "작은 글씨 11px · 보조 설명 secondary text 0123456789"; muted: true; font.pixelSize: Theme.fontSizeSmall }
            MLabel { text: "고정폭 · " + win.mixed; font.family: Theme.monoFamily }
            MLabel { text: win.longText; wrap: true; width: parent.width }
            MLabel { text: "말줄임: " + win.mixed + " " + win.mixed + " " + win.mixed; width: 300 }
            MLabel { text: "비활성 텍스트 disabled"; enabled: false }
        }

        // ---- 창 프레임 모형 ----
        Row { visible: win.section === "frame"; spacing: Theme.paddingLarge * 2
            MWindowFrameMock { title: "활성 창 — 문서"; active: true; width: 270; height: 170
                MLabel { x: Theme.paddingLarge; y: Theme.paddingLarge; text: "창 장식은 labwc 가 그린다 (모형)"; muted: true; font.pixelSize: Theme.fontSizeSmall } }
            MWindowFrameMock { title: "비활성 창 — 긴 제목 1234567890 abcdefghijklmnop"; active: false; width: 270; height: 170 }
        }
    }
}
