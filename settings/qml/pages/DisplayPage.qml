// 설정 → 디스플레이: 출력별 모드·배율·회전·켜기/끄기 (wlr-randr). 적용하면 저장되어 다음 로그인에도 복원된다.
import QtQuick
import HagraUI 1.0
import HagraSettings 1.0
import ".."

SPage {
    id: page
    title: "디스플레이"
    subtitle: Display.available ? "wlr-output-management 로 즉시 적용됩니다. 적용한 값은 저장되어 로그인할 때 복원됩니다." : ""
    property string lastError: ""
    Connections { target: Display; function onError(m) { page.lastError = m } }

    SNote { visible: !Display.available; kind: "unavailable"; title: "디스플레이 설정을 쓸 수 없습니다"; text: Display.reason }
    SNote { visible: page.lastError.length > 0; kind: "unavailable"; title: "적용 실패"; text: page.lastError }

    Repeater { model: Display.outputs
        delegate: Column { id: out; required property var modelData; required property int index
            width: parent.width; spacing: Theme.padding
            property string mode: modelData.currentMode
            property real outScale: modelData.scale
            property string outTransform: modelData.transform
            property bool outEnabled: modelData.enabled
            readonly property var outScales: [1, 1.25, 1.5, 1.75, 2, 2.5, 3]
            readonly property var outTransforms: ["normal", "90", "180", "270", "flipped", "flipped-90", "flipped-180", "flipped-270"]
            SSection { title: modelData.description + (modelData.make.length ? "  —  " + modelData.make + " " + modelData.model : ""); divider: index > 0 }
            MLabel { text: "출력 " + modelData.name + " · 위치 " + modelData.x + "," + modelData.y + (modelData.saved ? " · 저장된 설정 있음" : ""); muted: true; font.pixelSize: Theme.fontSizeSmall }
            SRow { label: "켜기"; MCheckBox { checked: out.outEnabled; text: out.outEnabled ? "켜짐" : "꺼짐"; onToggled: (c) => out.outEnabled = c; enabled: Display.outputs.length > 1 || !out.outEnabled
                   MToolTip { text: Display.outputs.length > 1 ? "" : "출력이 하나뿐이면 끌 수 없습니다" } } }
            SRow { label: "해상도 · 주사율"
                MComboBox { property var labels: modelData.modes.map((m) => m.label + (m.preferred ? " (권장)" : ""))
                            model: labels; currentIndex: Math.max(0, modelData.modes.findIndex((m) => m.label === out.mode))
                            onActivated: (i) => out.mode = modelData.modes[i].label; enabled: out.outEnabled } }
            SRow { label: "배율"; description: "HiDPI 화면은 1.5 또는 2. 논리 해상도 = 물리 해상도 ÷ 배율."
                MComboBox { model: out.outScales.map((s) => Math.round(s * 100) + "%"); currentIndex: Math.max(0, out.outScales.indexOf(out.outScale))
                            onActivated: (i) => out.outScale = out.outScales[i]; enabled: out.outEnabled } }
            SRow { label: "회전"
                MComboBox { model: ["없음", "90°", "180°", "270°", "좌우 반전", "반전 90°", "반전 180°", "반전 270°"]; currentIndex: Math.max(0, out.outTransforms.indexOf(out.outTransform))
                            onActivated: (i) => out.outTransform = out.outTransforms[i]; enabled: out.outEnabled } }
            Row { spacing: Theme.padding
                MButton { text: "적용"; defaultButton: true; icon: "check"
                          enabled: out.mode !== modelData.currentMode || out.outScale !== modelData.scale || out.outTransform !== modelData.transform || out.outEnabled !== modelData.enabled
                          onClicked: { page.lastError = ""; Display.apply(modelData.name, out.mode, out.outScale, out.outTransform, out.outEnabled) } }
                MButton { text: "저장된 설정 지우기"; enabled: modelData.saved; onClicked: Display.forget(modelData.name)
                          MToolTip { text: "다음 로그인부터 컴포지터 기본값(권장 모드, 배율 1)을 씁니다. 현재 화면은 바뀌지 않습니다." } }
                MButton { visible: Display.outputs.length > 1 && index > 0; text: "첫 출력 오른쪽에"; onClicked: { var p = Display.outputs[0]; var m = p.currentMode.split("x"); Display.setPosition(modelData.name, parseInt(m[0]) / p.scale, 0) } }
                MButton { visible: Display.outputs.length > 1 && index > 0; text: "첫 출력 왼쪽에"; onClicked: { var m = out.mode.split("x"); Display.setPosition(Display.outputs[0].name, Math.round(parseInt(m[0]) / out.outScale), 0); Display.setPosition(modelData.name, 0, 0) } }
            }
        }
    }
    MButton { visible: Display.available; text: "다시 읽기"; icon: "refresh"; onClicked: { page.lastError = ""; Display.refresh() } }
    SNote { visible: Display.available; text: "배율을 바꾸면 하그라 셸·설정 창은 컴포지터 출력 배율을 따라 즉시 다시 그려집니다. 다중 모니터 배치는 '첫 출력 왼쪽/오른쪽에' 버튼으로 가로로 나란히 놓습니다." }
}
