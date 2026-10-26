// 설정 → 키보드와 마우스: input.conf 에 저장, labwc rc.xml/environment 로 렌더링 후 재구성.
import QtQuick
import HagraUI 1.0
import HagraSettings 1.0
import ".."

SPage {
    id: page
    title: qsTr("키보드와 마우스")
    subtitle: Input.sessionApplySupported ? qsTr("포인터·반복 설정은 즉시, 키보드 배치는 labwc 가 환경 파일을 다시 읽을 때(재구성 또는 다음 로그인) 적용됩니다.") : qsTr("세션 밖에서 실행 중: 다음 로그인부터 적용됩니다.")
    readonly property var v: Input.values
    readonly property var layoutCodes: Input.layouts.map((l) => l.code)
    readonly property var toggleOptions: [ { id: "", label: qsTr("없음") }, { id: "grp:alt_shift_toggle", label: "Alt+Shift" }, { id: "grp:ctrl_space_toggle", label: "Ctrl+Space" },
                                           { id: "grp:win_space_toggle", label: "Super+Space" }, { id: "grp:caps_toggle", label: "Caps Lock" }, { id: "grp:rctrl_toggle", label: qsTr("오른쪽 Ctrl") } ]

    SSection { title: qsTr("키보드"); divider: false }
    SRow { label: qsTr("기본 배치"); description: qsTr("첫 배치. 현재: ") + v["keyboard/layout"]
        MComboBox { model: Input.layouts.map((l) => l.name + " (" + l.code + ")"); width: 300
                    currentIndex: Math.max(0, layoutCodes.indexOf(String(v["keyboard/layout"]).split(",")[0]))
                    onActivated: (i) => { var rest = String(v["keyboard/layout"]).split(",").slice(1).filter((c) => c !== layoutCodes[i]); Input.set("keyboard/layout", [layoutCodes[i]].concat(rest).join(",")) } } }
    SRow { label: qsTr("두 번째 배치 (전환용)"); description: qsTr("한국어 + 영어처럼 두 배치를 번갈아 쓰려면 지정합니다.")
        MComboBox { property var codes: [""].concat(layoutCodes); model: [qsTr("없음")].concat(Input.layouts.map((l) => l.name + " (" + l.code + ")")); width: 300
                    currentIndex: Math.max(0, codes.indexOf(String(v["keyboard/layout"]).split(",")[1] || ""))
                    onActivated: (i) => { var first = String(v["keyboard/layout"]).split(",")[0]; Input.set("keyboard/layout", codes[i].length ? first + "," + codes[i] : first) } } }
    SRow { label: qsTr("배치 전환 키"); description: qsTr("한/영 키가 없는 키보드용. 한글 입력기(fcitx5)를 쓰면 입력기의 전환 키를 씁니다.")
        MComboBox { model: toggleOptions.map((o) => o.label); width: 200
                    currentIndex: Math.max(0, toggleOptions.findIndex((o) => String(v["keyboard/options"]).indexOf(o.id) >= 0 && (o.id.length || String(v["keyboard/options"]).length === 0)))
                    onActivated: (i) => Input.set("keyboard/options", toggleOptions[i].id) } }
    SRow { label: qsTr("키 반복 속도"); description: qsTr("초당 반복 횟수")
        MSlider { from: 10; to: 60; stepSize: 5; value: parseInt(v["keyboard/repeatRate"]); valueText: parseInt(v["keyboard/repeatRate"]) + "/s"; live: false; width: 280; onMoved: (x) => Input.set("keyboard/repeatRate", x) } }
    SRow { label: qsTr("반복 시작 지연"); description: qsTr("키를 누르고 반복이 시작되기까지 (ms)")
        MSlider { from: 200; to: 1000; stepSize: 50; value: parseInt(v["keyboard/repeatDelay"]); valueText: parseInt(v["keyboard/repeatDelay"]) + " ms"; live: false; width: 280; onMoved: (x) => Input.set("keyboard/repeatDelay", x) } }

    SSection { title: qsTr("마우스와 터치패드") }
    SRow { label: qsTr("포인터 속도"); MSlider { from: -1; to: 1; stepSize: 0.1; value: parseFloat(v["pointer/speed"]); valueText: (parseFloat(v["pointer/speed"]) >= 0 ? "+" : "") + parseFloat(v["pointer/speed"]).toFixed(1); live: false; width: 280; onMoved: (x) => Input.set("pointer/speed", Math.round(x * 10) / 10) } }
    SRow { label: qsTr("탭으로 클릭 (터치패드)"); MCheckBox { checked: String(v["pointer/tap"]) === "true"; text: checked ? qsTr("사용") : qsTr("사용 안 함"); onToggled: (c) => Input.set("pointer/tap", c) } }
    SRow { label: qsTr("자연스러운 스크롤"); description: qsTr("손가락 방향으로 내용이 움직입니다."); MCheckBox { checked: String(v["pointer/naturalScroll"]) === "true"; text: checked ? qsTr("사용") : qsTr("사용 안 함"); onToggled: (c) => Input.set("pointer/naturalScroll", c) } }
    SRow { label: qsTr("왼손잡이 (버튼 바꿈)"); MCheckBox { checked: String(v["pointer/leftHanded"]) === "true"; text: checked ? qsTr("사용") : qsTr("사용 안 함"); onToggled: (c) => Input.set("pointer/leftHanded", c) } }
    SRow { label: qsTr("가운데 버튼 에뮬레이션"); description: qsTr("왼쪽+오른쪽 동시 클릭 = 가운데 클릭"); MCheckBox { checked: String(v["pointer/middleEmulation"]) === "true"; text: checked ? qsTr("사용") : qsTr("사용 안 함"); onToggled: (c) => Input.set("pointer/middleEmulation", c) } }
    Row { spacing: Theme.padding
        MButton { text: qsTr("모두 기본값으로"); icon: "reset"; onClicked: Input.resetAll() }
        MButton { text: qsTr("세션에 다시 적용"); icon: "refresh"; enabled: Input.sessionApplySupported; onClicked: Input.applyToSession() }
    }
    SNote { text: qsTr("저장 위치: ") + Input.configPath + qsTr(". 사용자가 ~/.config/hagra/labwc/rc.xml 또는 environment 를 직접 두면 이 설정은 그 파일을 덮지 않습니다.") }
}
