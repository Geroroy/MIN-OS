// 생성된 파일 — 직접 수정하지 말 것. 원본: design/tokens/hagra.tokens.json, 생성기: design/tools/gen_tokens.py
// 토큰 세트: hagra-dancheong-v1 (status: design-v1)
pragma Singleton
import QtQuick

QtObject {
    // 식별
    readonly property string tokenSet: "hagra-dancheong-v1"
    readonly property string tokenStatus: "design-v1"
    readonly property string brandName: "하그라"
    readonly property string brandNameLatin: "HAGRA"

    // 색상
    readonly property color bg: "#E3ECE6"
    readonly property color surface: "#FAF6EA"
    readonly property color surfaceRaised: "#F0EBDD"
    readonly property color border: "#90A99E"
    readonly property color borderStrong: "#4F756D"
    readonly property color text: "#203F42"
    readonly property color textMuted: "#536963"
    readonly property color textDisabled: "#79867E"
    readonly property color accent: "#28717B"
    readonly property color accentText: "#FFFFFF"
    readonly property color warning: "#91631D"
    readonly property color danger: "#A54042"
    readonly property color success: "#3E746D"
    readonly property color focusRing: "#28717B"
    readonly property color selection: "#F8E7B8"
    readonly property color selectionText: "#203F42"
    readonly property color overlayDim: "#40203F42"
    readonly property color titleActive: "#D2E2D5"
    readonly property color titleInactive: "#E5EBE0"
    readonly property color coral: "#E89B89"
    readonly property color celadon: "#91B9A5"
    readonly property color blue: "#8DAAC0"
    readonly property color ochre: "#EDC486"
    readonly property color ivory: "#FAF6EA"
    readonly property color patternInk: "#3E746D"

    // 창 장식 (labwc 와 공유하는 값; QML 미리보기 모형·앱 내부 장식에서 사용)
    readonly property color windowActiveBorder: "#4F756D"
    readonly property color windowInactiveBorder: "#90A99E"
    readonly property color windowActiveTitleBg: "#D2E2D5"
    readonly property color windowInactiveTitleBg: "#E5EBE0"
    readonly property color windowActiveTitleText: "#203F42"
    readonly property color windowInactiveTitleText: "#536963"
    readonly property color windowButtonHoverBg: "#E89B89"
    readonly property int windowBorderWidth: 2
    readonly property int windowCornerRadius: 2

    // 치수 (QML 논리 픽셀, 배율 1.0 기준)
    readonly property int unit: 4
    readonly property int panelHeight: 52
    readonly property int panelBandHeight: 8
    readonly property int titleBarHeight: 40
    readonly property int rowHeight: 40
    readonly property int controlHeight: 36
    readonly property int borderWidth: 1
    readonly property int focusRingWidth: 2
    readonly property int focusWidth: 2
    readonly property int selectionMarkerWidth: 3
    readonly property int padding: 8
    readonly property int paddingLarge: 16
    readonly property int iconSize: 24
    readonly property int iconSizeLarge: 32
    readonly property int folderIconSize: 72
    readonly property int radius: 2
    readonly property int scrollBarWidth: 12
    readonly property int dialogMinWidth: 360
    readonly property int tooltipMaxWidth: 360
    readonly property int ornamentBandHeight: 18
    readonly property int ornamentFrameWidth: 6
    readonly property int cornerSize: 24
    readonly property int railWidth: 72

    // 글꼴
    readonly property string fontFamily: "Noto Sans CJK KR"
    readonly property string fontFamilyKo: "Noto Sans CJK KR"
    readonly property string monoFamily: "DejaVu Sans Mono"
    readonly property int fontSize: 15
    readonly property int fontSizeSmall: 13
    readonly property int fontSizeTitle: 16
    readonly property real lineHeight: 1.4

    // 움직임
    readonly property int motionDuration: 0

    // 모듈 자산: libs/minui/qml/MinUI/assets/<name>.svg (모듈과 함께 설치됨). 원본: design/hagra-dancheong-v1/assets/
    function asset(name) { return Qt.resolvedUrl("assets/" + name + ".svg") }
    // 외부 아이콘 디렉터리(선택): HAGRA_ICON_PATH / --icons. 없으면 빈 문자열 → MIcon 이 자리 표시자를 그린다.
    property string iconBasePath: ""
    function iconSource(name) { return iconBasePath.length ? iconBasePath + "/" + name + ".svg" : "" }
}
