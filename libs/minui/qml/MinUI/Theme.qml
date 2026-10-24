// 생성된 파일 — 직접 수정하지 말 것. 원본: design/tokens/hagra.tokens.json, 생성기: design/tools/gen_tokens.py
// 토큰 세트: hagra-provisional (status: provisional)
pragma Singleton
import QtQuick

QtObject {
    // 식별
    readonly property string tokenSet: "hagra-provisional"
    readonly property string tokenStatus: "provisional"
    readonly property string brandName: "하그라"
    readonly property string brandNameLatin: "HAGRA"

    // 색상
    readonly property color bg: "#1a1a1a"
    readonly property color surface: "#242424"
    readonly property color surfaceRaised: "#2e2e2e"
    readonly property color border: "#3a3a3a"
    readonly property color borderStrong: "#5c5c5c"
    readonly property color text: "#e4e4e4"
    readonly property color textMuted: "#9a9a9a"
    readonly property color textDisabled: "#5c5c5c"
    readonly property color accent: "#3d7bd9"
    readonly property color accentText: "#ffffff"
    readonly property color warning: "#c9a227"
    readonly property color danger: "#c0392b"
    readonly property color success: "#5c9a5c"
    readonly property color focusRing: "#3d7bd9"
    readonly property color selection: "#3d7bd9"
    readonly property color selectionText: "#ffffff"
    readonly property color overlayDim: "#80000000"

    // 창 장식 (labwc 와 공유하는 값; QML 미리보기 모형에서 사용)
    readonly property color windowActiveBorder: "#5c5c5c"
    readonly property color windowInactiveBorder: "#3a3a3a"
    readonly property color windowActiveTitleBg: "#242424"
    readonly property color windowInactiveTitleBg: "#1e1e1e"
    readonly property color windowActiveTitleText: "#e4e4e4"
    readonly property color windowInactiveTitleText: "#9a9a9a"

    // 치수 (QML 논리 픽셀, 배율 1.0 기준)
    readonly property int unit: 4
    readonly property int panelHeight: 28
    readonly property int titleBarHeight: 22
    readonly property int rowHeight: 20
    readonly property int controlHeight: 22
    readonly property int borderWidth: 1
    readonly property int focusRingWidth: 1
    readonly property int selectionMarkerWidth: 3
    readonly property int padding: 4
    readonly property int paddingLarge: 8
    readonly property int iconSize: 16
    readonly property int iconSizeLarge: 24
    readonly property int radius: 0
    readonly property int scrollBarWidth: 10
    readonly property int dialogMinWidth: 320
    readonly property int tooltipMaxWidth: 320

    // 글꼴
    readonly property string fontFamily: "Inter"
    readonly property string fontFamilyKo: "Noto Sans CJK KR"
    readonly property string monoFamily: "DejaVu Sans Mono"
    readonly property int fontSize: 12
    readonly property int fontSizeSmall: 11
    readonly property int fontSizeTitle: 13
    readonly property real lineHeight: 1.4

    // 움직임
    readonly property int motionDuration: 0

    // 아이콘 자산: design/assets/icons/<name>.svg (설치: /usr/share/hagra/icons). 없으면 빈 문자열 → MIcon 이 자리 표시자를 그린다.
    property string iconBasePath: ""
    function iconSource(name) { return iconBasePath.length ? iconBasePath + "/" + name + ".svg" : "" }
}
