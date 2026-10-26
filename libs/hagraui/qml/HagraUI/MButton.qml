import QtQuick
import HagraUI 1.0

// 버튼. 상태: 기본 · 호버 · 눌림 · 선택(checked/highlighted) · 키보드 포커스 · 비활성 · 오류 · 진행 중
// 색 이외의 단서: 선택 = 하단 3px 막대, 포커스 = 바깥 1px 링, 오류 = "!" 배지, 진행 중 = 하단 이동 막대
Rectangle {
    id: control
    property string text: ""
    property bool flat: false
    property bool highlighted: false      // 선택/활성 상태 (예: 열린 메뉴의 버튼, 작업 표시줄 활성 창)
    property alias checked: control.highlighted
    property bool bold: false
    property bool danger: false
    property bool defaultButton: false    // Enter 로 실행되는 기본 버튼 (2px accent 테두리)
    property bool error: false
    property bool busy: false
    property string icon: ""              // 모듈/테마 assets/<icon>.svg
    property bool onDark: false           // 어두운 면(패널·사이드바) 위: 전경 분백, 포커스 링 focusRingOnDark, 호버는 반투명
    property alias hovered: mouse.containsMouse
    property alias pressed: mouse.pressed
    property alias horizontalPadding: control.hPad
    property int hPad: Theme.paddingLarge
    signal clicked()

    implicitWidth: row.implicitWidth + hPad * 2
    implicitHeight: Theme.controlHeight
    radius: Theme.radius
    readonly property color fg: onDark ? Theme.panelText : Theme.text
    color: !enabled ? "transparent"
         : mouse.pressed ? Theme.selection
         : highlighted ? Theme.selection
         : mouse.containsMouse ? (onDark ? Qt.rgba(Theme.panelText.r, Theme.panelText.g, Theme.panelText.b, 0.14) : Theme.surfaceRaised)
         : (flat ? "transparent" : Theme.surface)
    border.width: flat ? 0 : (defaultButton ? 2 : Theme.borderWidth)
    border.color: !enabled ? Theme.border
                : error ? Theme.danger
                : mouse.pressed ? Theme.accent
                : (danger ? Theme.danger : (defaultButton ? Theme.accent : Theme.borderStrong))

    activeFocusOnTab: enabled
    Keys.onReturnPressed: if (enabled) clicked()
    Keys.onEnterPressed: if (enabled) clicked()
    Keys.onSpacePressed: if (enabled) clicked()

    Rectangle { // 선택 표시 (색 이외 단서)
        visible: control.highlighted
        anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right
        height: Theme.selectionMarkerWidth
        color: Theme.selection
    }
    Rectangle { // 포커스 링 (컨트롤 바깥, 장식 경계보다 앞)
        visible: control.activeFocus
        z: 5
        anchors.fill: parent; anchors.margins: -(Theme.focusRingWidth + 1)
        color: "transparent"; border.width: Theme.focusRingWidth; border.color: control.onDark ? Theme.focusRingOnDark : Theme.focusRing; radius: Theme.radius
    }
    Row {
        id: row
        anchors.centerIn: parent
        anchors.verticalCenterOffset: mouse.pressed ? 1 : 0   // 눌림: 1 논리 px 오프셋, 레이아웃 재배치 없음
        spacing: Theme.padding
        MIcon { visible: control.icon.length > 0; name: control.icon; anchors.verticalCenter: parent.verticalCenter
                light: control.onDark && !control.highlighted && !mouse.pressed
                enabled: control.enabled; color: !control.enabled ? Theme.textDisabled : control.fg }
        Text {
            id: label
            anchors.verticalCenter: parent.verticalCenter
            text: control.text
            visible: text.length > 0
            color: !control.enabled ? Theme.textDisabled : (control.danger ? Theme.danger : (control.highlighted || mouse.pressed) ? Theme.selectionText : control.fg)
            font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize; font.bold: control.bold
            renderType: Text.NativeRendering
        }
        Text { // 오류 배지
            visible: control.error
            anchors.verticalCenter: parent.verticalCenter
            text: "!"; color: Theme.danger; font.bold: true; font.pixelSize: Theme.fontSize; renderType: Text.NativeRendering
        }
    }
    MBusyBar { visible: control.busy; anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: control.enabled && !control.busy
        onClicked: control.clicked()
    }
}
