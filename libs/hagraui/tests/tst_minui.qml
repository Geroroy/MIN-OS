// HagraUI 동작 검사 (키보드·포인터·비활성·포커스·오류·자산). 실행: qmltestrunner -import libs/hagraui/qml -input libs/hagraui/tests
// 화면 캡처가 아니라 이벤트 전달과 상태 변화를 검사한다. 소프트웨어 렌더러·offscreen 플랫폼에서도 동작한다.
import QtQuick
import QtTest
import HagraUI 1.0

Item {
    id: root
    width: 640; height: 480

    // ---- 버튼: Tab 이동, Enter/Space 실행, 비활성 차단, 포커스 링, 오류 배지 ----
    Row { id: buttons; spacing: 8; x: 20; y: 20
        MButton { id: b1; text: "하나"; property int hits: 0; onClicked: hits++ }
        MButton { id: b2; text: "둘"; property int hits: 0; onClicked: hits++ }
        MButton { id: bDisabled; text: "비활성"; enabled: false; property int hits: 0; onClicked: hits++ }
        MButton { id: b3; text: "셋"; property int hits: 0; onClicked: hits++ }
        MButton { id: bError; text: "오류"; error: true }
    }
    MTextField { id: field; x: 20; y: 80; width: 200; property int accepts: 0; onAccepted: accepts++ }
    MTextField { id: fieldError; x: 240; y: 80; width: 200; error: true; errorText: "잘못된 값" }
    MCheckBox { id: check; x: 20; y: 140; text: "확인" }
    MCheckBox { id: checkDisabled; x: 200; y: 140; text: "비활성"; enabled: false; checked: true }
    Column { x: 20; y: 200; width: 300
        MListRow { id: row1; text: "행 1"; property int hits: 0; onClicked: hits++ }
        MListRow { id: rowDisabled; text: "비활성 행"; enabled: false; property int hits: 0; onClicked: hits++ }
    }
    MMenu { id: menu; items: [ { text: "열기" }, { text: "비활성", enabled: false }, { separator: true }, { text: "삭제" } ]
            property int lastIndex: -1; onTriggered: (i) => lastIndex = i }
    MIcon { id: iconAsset; name: "lotus"; x: 400; y: 200 }
    MIcon { id: iconUi; name: "home"; x: 440; y: 200 }
    MIcon { id: iconMissing; name: "no-such-icon"; x: 480; y: 200 }
    MOrnamentBand { id: band; x: 20; y: 300; width: 300 }
    MOrnamentBand { id: bandCompact; x: 20; y: 330; width: 300; compact: true }

    TestCase {
        name: "HagraUI"
        when: windowShown

        function test_01_tokens() {
            compare(Theme.tokenSet, "hagra-dancheong-v1")
            compare(Theme.panelHeight, 52)
            verify(Theme.panelBandHeight + Theme.borderWidth + Theme.controlHeight <= Theme.panelHeight, "panel band + control fit in panelHeight")
            compare(Theme.brandName, "하그라")
        }

        function test_02_button_keyboard() {
            b1.forceActiveFocus()
            verify(b1.activeFocus)
            keyClick(Qt.Key_Return); compare(b1.hits, 1)
            keyClick(Qt.Key_Space);  compare(b1.hits, 2)
            keyClick(Qt.Key_Tab);    verify(b2.activeFocus, "Tab moves to next button")
            keyClick(Qt.Key_Tab);    verify(b3.activeFocus, "Tab skips the disabled button")
            verify(!bDisabled.activeFocus)
            keyClick(Qt.Key_Enter);  compare(b3.hits, 1)
            keyClick(Qt.Key_Backtab); verify(b2.activeFocus, "Shift+Tab moves back")
        }

        function test_03_button_pointer_and_disabled() {
            mouseClick(b2); compare(b2.hits, 1)
            mouseClick(bDisabled); compare(bDisabled.hits, 0, "disabled button ignores clicks")
            verify(!bDisabled.activeFocusOnTab, "disabled button is not in the Tab chain")
            compare(bDisabled.color, Qt.color("transparent"))
        }

        function test_04_button_states() {
            b1.forceActiveFocus()
            // 포커스 링: z 5 의 투명 사각형이 보인다 (색 이외 단서)
            var ring = null
            for (var i = 0; i < b1.children.length; ++i) if (b1.children[i].z === 5) ring = b1.children[i]
            verify(ring && ring.visible, "focus ring visible while focused")
            b2.forceActiveFocus()
            verify(!ring.visible, "focus ring hidden when focus leaves")
            compare(bError.border.color, Theme.danger)
        }

        function test_05_textfield() {
            field.forceActiveFocus()
            verify(field.input.activeFocus, "focus forwarded to inner TextInput")
            keyClick(Qt.Key_A); keyClick(Qt.Key_B)
            compare(field.text, "ab")
            keyClick(Qt.Key_Return); compare(field.accepts, 1)
            keyClick(Qt.Key_Tab); verify(fieldError.input.activeFocus, "Tab moves to the next field")
            compare(fieldError.border.color, Theme.danger)
            field.text = ""
        }

        function test_06_checkbox() {
            check.forceActiveFocus()
            keyClick(Qt.Key_Space); compare(check.checked, true)
            keyClick(Qt.Key_Space); compare(check.checked, false)
            mouseClick(check);       compare(check.checked, true)
            mouseClick(checkDisabled); compare(checkDisabled.checked, true, "disabled checkbox keeps its state")
            verify(!checkDisabled.activeFocusOnTab)
        }

        function test_07_listrow() {
            mouseClick(row1); compare(row1.hits, 1)
            mouseClick(rowDisabled); compare(rowDisabled.hits, 0)
            row1.selected = true; compare(row1.color, Theme.selection)
        }

        function test_08_menu() {
            menu.open(b1, 0, 40)
            tryVerify(function() { return menu.opened }, 1000)
            compare(menu.currentIndex, 0)
            keyClick(Qt.Key_Down); compare(menu.currentIndex, 3, "Down skips disabled item and separator")
            keyClick(Qt.Key_Up);   compare(menu.currentIndex, 0)
            keyClick(Qt.Key_Escape); tryVerify(function() { return !menu.opened }, 1000)
            // 창 오른쪽 끝에서 열어도 창 안에 머문다
            menu.open(root, root.width - 10, root.height - 10)
            tryVerify(function() { return menu.opened }, 1000)
            wait(50)
            verify(menu.popup.x + menu.popup.width <= root.width + 0.5, "menu clamped horizontally")
            verify(menu.popup.y + menu.popup.height <= root.height + 0.5, "menu clamped vertically")
            keyClick(Qt.Key_Return); tryVerify(function() { return !menu.opened }, 1000)
            compare(menu.lastIndex, 0)
        }

        function test_10_applyTokens() {
            var bg0 = String(Theme.bg), panel0 = String(Theme.panel)   // 값 타입 참조가 아니라 문자열로 보관 (속성이 바뀌면 참조도 바뀐다)
            Theme.applyTokens({ themeId: "t-test", displayName: "테스트", color: { bg: "#183C35", panel: "#183C35", panelText: "#F2EADB" },
                                window: { activeTitleBg: "#28574A", borderWidth: 3 }, size: { panelHeight: 60 }, assets: { lotus: "file:///nonexistent/lotus.svg" } })
            compare(Theme.themeId, "t-test")
            compare(Theme.bg, Qt.color("#183C35"))
            compare(Theme.panelText, Qt.color("#F2EADB"))
            verify(Theme.isDark(Theme.panel), "dark panel detected")
            compare(Theme.windowActiveTitleBg, Qt.color("#28574A"))
            compare(Theme.windowBorderWidth, 3)
            compare(Theme.panelHeight, 60)
            compare(String(Theme.asset("lotus")), "file:///nonexistent/lotus.svg", "theme asset wins")
            verify(String(Theme.asset("home")).indexOf("HagraUI/assets/home.svg") > 0, "module asset fallback")
            compare(Theme.surface, Qt.color("#FAF6EA"), "keys not in the token set are untouched")
            // 되돌리기
            Theme.applyTokens({ themeId: "hagra-dancheong-light", color: { bg: bg0, panel: panel0, panelText: "#203F42" },
                                window: { activeTitleBg: "#D2E2D5", borderWidth: 2 }, size: { panelHeight: 52 }, assets: {} })
            compare(Theme.panelHeight, 52)
            verify(!Theme.isDark(Theme.panel))
            tryVerify(function() { return iconAsset.ready }, 2000)
        }

        function test_09_assets() {
            tryVerify(function() { return iconAsset.ready }, 2000)
            tryVerify(function() { return iconUi.ready }, 2000)
            wait(200)
            verify(!iconMissing.ready, "unknown icon shows placeholder")
            tryVerify(function() { return band.children[0].status === Image.Ready }, 2000)
            compare(band.height, Theme.ornamentBandHeight)
            compare(bandCompact.height, Theme.panelBandHeight)
        }
    }
}
