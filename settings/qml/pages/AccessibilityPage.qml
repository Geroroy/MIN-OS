// 설정 → 접근성: 글자 배율(모든 HagraUI 앱에 즉시), 포커스 표시 강조, 커서 크기, 지원 범위 안내.
import QtQuick
import HagraUI 1.0
import HagraTheme 1.0
import HagraSettings 1.0
import ".."

SPage {
    id: page
    title: "접근성"
    subtitle: "하그라 셸·설정·HagraUI 앱에 즉시 적용됩니다. 외부 앱은 각자의 설정을 따릅니다."
    ConfFile { id: acc; name: "accessibility" }
    ConfFile { id: cursorConf; name: "cursor" }
    readonly property int rev: acc.revision

    SSection { title: "보기"; divider: false }
    SRow { label: "글자 크기"; description: "기본 15px 기준 배율. 현재 " + Math.round(ThemeManager.textScale * 100) + "%."
        MSlider { from: 1.0; to: 1.6; stepSize: 0.1; value: parseFloat(acc.get("text/scale", 1.0)); valueText: Math.round(parseFloat(acc.get("text/scale", 1.0)) * 100) + "%"; live: false; width: 280
                  onMoved: (x) => acc.set("text/scale", Math.round(x * 10) / 10) } }
    SRow { label: "포커스 표시 강조"; description: "키보드 포커스 링과 선택 막대를 더 굵게 (2px → 3px)."
        MCheckBox { checked: String(acc.get("focus/thick", false)) === "true"; text: checked ? "켜짐" : "꺼짐"; onToggled: (c) => acc.set("focus/thick", c) } }
    SRow { label: "움직임 줄이기"; description: "하그라는 전환 애니메이션을 쓰지 않습니다 (motionDuration 0). 별도 설정이 필요 없습니다."
        MLabel { text: "항상 최소"; muted: true } }
    SRow { label: "커서 크기"; description: "다음 로그인부터 적용됩니다."
        SChoice { current: String(cursorConf.get("size", 24)) + "​".repeat(cursorConf.revision % 2)
                  options: [ { id: "24", label: "24" }, { id: "32", label: "32" }, { id: "48", label: "48" } ]
                  onSelected: (id) => cursorConf.set("size", parseInt(id)) } }
    SSection { title: "미리보기" }
    Rectangle { width: parent.width; height: prev.height + Theme.paddingLarge * 2; color: Theme.surfaceRaised; radius: Theme.radius; border.width: 1; border.color: Theme.border
        Column { id: prev; x: Theme.paddingLarge; y: Theme.paddingLarge; spacing: Theme.padding; width: parent.width - Theme.paddingLarge * 2
            MLabel { text: "한글 가나다라 · Latin AaBbCc 0123 — 제목 크기"; font.pixelSize: Theme.fontSizeTitle; font.bold: true }
            MLabel { text: "본문: 다람쥐 헌 쳇바퀴에 타고파. The quick brown fox jumps over the lazy dog."; wrap: true; width: parent.width }
            Row { spacing: Theme.padding
                MButton { text: "버튼" }
                MTextField { width: 160; text: "입력란" }
                MCheckBox { text: "확인"; checked: true }
            }
        }
    }
    SSection { title: "지원 범위" }
    SNote { text: "키보드: 모든 하그라 UI 는 Tab/Shift+Tab, 방향키, Space/Enter, Esc 로 조작할 수 있고 포커스 링이 보입니다. 화면 읽기: HagraUI 부품에 접근성 역할·이름이 있으나 이 이미지에는 AT-SPI 화면 읽기 프로그램(orca)이 포함되어 있지 않습니다. 고정 키·느린 키: labwc 는 아직 지원하지 않습니다." }
    SNote { kind: "info"; text: "글자 크기와 포커스 강조는 " + ThemeManager.accessibilityConfigPath + " 에 저장되며 테마 관리자가 감시해 실행 중인 하그라 앱에 바로 반영합니다." }
}
