// 설정 → 모양과 테마: 테마 카드(즉시 적용·저장), 밝게/어둡게, 포인트 색, 기본으로, 커서. 글자 크기는 접근성 페이지와 공유(accessibility.conf).
import QtQuick
import HagraUI 1.0
import HagraTheme 1.0
import HagraSettings 1.0
import ".."

SPage {
    id: page
    title: qsTr("모양과 테마")
    subtitle: qsTr("선택하면 바로 저장되고 셸·창 장식·배경에 적용됩니다. 재로그인 후에도 유지됩니다.")
    ConfFile { id: cursorConf; name: "cursor" }
    ConfFile { id: panelConf; name: "panel" }

    SSection { title: qsTr("테마"); divider: false }
    Column { id: list; width: parent.width; spacing: Theme.padding
        property int focusIndex: 0
        activeFocusOnTab: true
        Accessible.role: Accessible.List
        Keys.onUpPressed: focusIndex = Math.max(0, focusIndex - 1)
        Keys.onDownPressed: focusIndex = Math.min(ThemeManager.themes.length - 1, focusIndex + 1)
        Keys.onSpacePressed: ThemeManager.apply(ThemeManager.themes[focusIndex].id)
        Keys.onReturnPressed: ThemeManager.apply(ThemeManager.themes[focusIndex].id)
        Repeater { model: ThemeManager.themes
            delegate: ThemeCard { required property var modelData; required property int index; theme: modelData
                                  focusVisible: list.activeFocus && list.focusIndex === index
                                  onChosen: (id) => { list.focusIndex = index; list.forceActiveFocus(); ThemeManager.apply(id) } } }
    }
    SRow { label: qsTr("밝기"); description: qsTr("같은 계열의 밝은/어두운 테마로 바꿉니다. 해당 밝기의 테마가 없으면 비활성.")
        SChoice { current: ThemeManager.appearance
                  options: [ { id: "light", label: qsTr("밝게"), icon: "sun", enabled: ThemeManager.themeWithAppearance("light").length > 0 },
                             { id: "dark", label: qsTr("어둡게"), icon: "moon", enabled: ThemeManager.themeWithAppearance("dark").length > 0 } ]
                  onSelected: (id) => { var t = ThemeManager.themeWithAppearance(id); if (t.length) ThemeManager.apply(t) } }
    }
    SRow { label: qsTr("포인트 색"); visible: ThemeManager.accents.length > 0
           description: qsTr("테마가 정의한 대비 검증된 변형만 제공합니다. 강조·포커스 링·선택 표시에 쓰입니다.")
        Row { spacing: Theme.padding
            Repeater { model: [{ id: "", name: qsTr("테마 기본"), accent: Theme.accent, current: ThemeManager.accentId === "" }].concat(ThemeManager.accents)
                delegate: Rectangle { required property var modelData
                    width: 40; height: 40; radius: 20; color: modelData.accent
                    border.width: modelData.current ? 3 : 1; border.color: modelData.current ? Theme.text : Theme.border
                    activeFocusOnTab: true
                    Accessible.role: Accessible.RadioButton; Accessible.name: modelData.name + (modelData.current ? qsTr(" (선택됨)") : "")
                    Keys.onSpacePressed: ThemeManager.accentId = modelData.id
                    Keys.onReturnPressed: ThemeManager.accentId = modelData.id
                    Rectangle { visible: parent.activeFocus; anchors.fill: parent; anchors.margins: -4; radius: width / 2; color: "transparent"; border.width: Theme.focusRingWidth; border.color: Theme.focusRing }
                    MLabel { anchors.centerIn: parent; visible: modelData.current; text: "✓"; color: Theme.accentText; font.bold: true }
                    MouseArea { anchors.fill: parent; onClicked: { parent.forceActiveFocus(); ThemeManager.accentId = modelData.id } }
                    MToolTip { text: modelData.name }
                } }
        }
    }
    SRow { label: qsTr("기본 테마로 되돌리기"); description: qsTr("기본 테마(") + ThemeManager.defaultId + qsTr(")와 테마 기본 포인트 색으로 돌아갑니다. 사용자 배경은 유지됩니다.")
        MButton { text: qsTr("기본 테마로"); icon: "reset"; enabled: ThemeManager.currentId !== ThemeManager.defaultId || ThemeManager.accentId !== ""
                  onClicked: { ThemeManager.accentId = ""; ThemeManager.resetToDefault() } }
    }
    SNote { kind: ThemeManager.sessionReloadSupported ? "info" : "warn"
            text: ThemeManager.sessionReloadSupported ? qsTr("창 장식(labwc)은 재구성 명령으로 즉시 갱신됩니다. 이미 실행 중인 다른 앱은 다음 실행부터 새 테마를 씁니다.")
                                                      : qsTr("세션 밖에서 실행 중: 창 장식·배경은 다음 로그인부터 적용됩니다.") }

    SSection { title: qsTr("패널") }
    SRow { label: qsTr("패널 위치"); description: qsTr("작업 표시줄을 화면 아래 또는 위에 둡니다. 실행 메뉴·전원 메뉴·알림 센터가 같은 쪽에 붙습니다. 즉시 적용.")
        SChoice { current: panelConf.revision >= 0 ? String(panelConf.get("panel/position", "bottom")) : ""
                  options: [ { id: "bottom", label: qsTr("아래") }, { id: "top", label: qsTr("위") } ]
                  onSelected: (id) => panelConf.set("panel/position", id) }
    }
    SRow { label: qsTr("시계에 초 표시"); MCheckBox { checked: String(panelConf.get("panel/clockSeconds", false)) === "true"; text: checked ? qsTr("켜짐") : qsTr("꺼짐"); onToggled: (c) => panelConf.set("panel/clockSeconds", c) } }
    SSection { title: qsTr("커서") }
    SRow { label: qsTr("커서 테마"); description: qsTr("설치된 커서 테마(/usr/share/icons/*/cursors). 다음 로그인부터 적용됩니다.")
        MComboBox { id: cursorTheme
            property var names: SystemInfo.cursorThemes()
            model: names.length ? names : ["Adwaita"]
            currentIndex: Math.max(0, model.indexOf(cursorConf.get("theme", "Adwaita")))
            onActivated: (i) => cursorConf.set("theme", model[i]) }
    }
    SRow { label: qsTr("커서 크기"); description: qsTr("24(기본) · 32 · 48. HiDPI 화면에서는 큰 값을 권합니다. 다음 로그인부터 적용됩니다.")
        SChoice { current: cursorConf.revision >= 0 ? String(cursorConf.get("size", 24)) : ""
                  options: [ { id: "24", label: "24" }, { id: "32", label: "32" }, { id: "48", label: "48" } ]
                  onSelected: (id) => cursorConf.set("size", parseInt(id)) }
    }
    SRow { label: qsTr("글자 크기"); description: qsTr("접근성 페이지에서 바꿉니다 (현재 배율 ") + Math.round(ThemeManager.textScale * 100) + "%)."
        MButton { text: qsTr("접근성으로"); icon: "text-size"; onClicked: win.openPage("accessibility") }
    }
}
