// 생성된 파일 — 직접 수정하지 말 것. 원본: design/tokens/hagra.tokens.json, 생성기: design/tools/gen_tokens.py
// 토큰 세트: hagra-dancheong-v1 (status: design-v1) — 기본 테마. 색상·창 장식·치수·글꼴은 런타임에 ThemeManager(libs/hagratheme) 가 applyTokens() 로 바꿀 수 있다. 아래 값은 기본 테마의 초기값.
pragma Singleton
import QtQuick

QtObject {
    id: theme
    // 식별
    readonly property string tokenSet: "hagra-dancheong-v1"
    readonly property string tokenStatus: "design-v1"
    readonly property string brandName: "하그라"
    readonly property string brandNameLatin: "HAGRA"

    // 현재 테마 (applyTokens 로 바뀐다). themeAssets: 테마 팩 assets/ 의 name → url
    property string themeId: "hagra-dancheong-light"
    property string themeName: "연한 단청"
    property var themeAssets: ({})

    // 색상
    property color bg: "#E3ECE6"
    property color surface: "#FAF6EA"
    property color surfaceRaised: "#F0EBDD"
    property color border: "#90A99E"
    property color borderStrong: "#4F756D"
    property color text: "#203F42"
    property color textMuted: "#536963"
    property color textDisabled: "#79867E"
    property color accent: "#28717B"
    property color accentText: "#FFFFFF"
    property color warning: "#91631D"
    property color danger: "#A54042"
    property color success: "#3E746D"
    property color focusRing: "#28717B"
    property color selection: "#F8E7B8"
    property color selectionText: "#203F42"
    property color overlayDim: "#40203F42"
    property color titleActive: "#D2E2D5"
    property color titleInactive: "#E5EBE0"
    property color coral: "#E89B89"
    property color celadon: "#91B9A5"
    property color blue: "#8DAAC0"
    property color ochre: "#EDC486"
    property color ivory: "#FAF6EA"
    property color patternInk: "#3E746D"
    property color titleText: "#203F42"
    property color titleInactiveText: "#536963"
    property color panel: "#FAF6EA"
    property color panelText: "#203F42"
    property color panelMuted: "#536963"
    property color sidebar: "#E3ECE6"
    property color sidebarText: "#203F42"
    property color redBrown: "#8A5A4A"
    property color focusRingOnDark: "#FAF6EA"

    // 창 장식 (labwc 와 공유하는 값; QML 미리보기 모형·앱 내부 장식에서 사용)
    property color windowActiveBorder: "#4F756D"
    property color windowInactiveBorder: "#90A99E"
    property color windowActiveTitleBg: "#D2E2D5"
    property color windowInactiveTitleBg: "#E5EBE0"
    property color windowActiveTitleText: "#203F42"
    property color windowInactiveTitleText: "#536963"
    property color windowButtonHoverBg: "#E89B89"
    property int windowBorderWidth: 2
    property int windowCornerRadius: 2

    // 치수 (QML 논리 픽셀, 배율 1.0 기준)
    property int unit: 4
    property int panelHeight: 52
    property int panelBandHeight: 8
    property int titleBarHeight: 40
    property int rowHeight: 40
    property int controlHeight: 36
    property int borderWidth: 1
    property int focusRingWidth: 2
    property int focusWidth: 2
    property int selectionMarkerWidth: 3
    property int padding: 8
    property int paddingLarge: 16
    property int iconSize: 24
    property int iconSizeLarge: 32
    property int folderIconSize: 72
    property int radius: 2
    property int scrollBarWidth: 12
    property int dialogMinWidth: 360
    property int tooltipMaxWidth: 360
    property int ornamentBandHeight: 18
    property int ornamentFrameWidth: 6
    property int cornerSize: 24
    property int railWidth: 72

    // 글꼴
    property string fontFamily: "Noto Sans CJK KR"
    property string fontFamilyKo: "Noto Sans CJK KR"
    property string monoFamily: "DejaVu Sans Mono"
    property int fontSize: 15
    property int fontSizeSmall: 13
    property int fontSizeTitle: 16
    property real lineHeight: 1.4

    // 움직임
    readonly property int motionDuration: 0

    // 토큰 키 목록 (applyTokens 가 이 키만 받는다)
    readonly property var colorKeys: ["bg", "surface", "surfaceRaised", "border", "borderStrong", "text", "textMuted", "textDisabled", "accent", "accentText", "warning", "danger", "success", "focusRing", "selection", "selectionText", "overlayDim", "titleActive", "titleInactive", "coral", "celadon", "blue", "ochre", "ivory", "patternInk", "titleText", "titleInactiveText", "panel", "panelText", "panelMuted", "sidebar", "sidebarText", "redBrown", "focusRingOnDark"]
    readonly property var sizeKeys: ["unit", "panelHeight", "panelBandHeight", "titleBarHeight", "rowHeight", "controlHeight", "borderWidth", "focusRingWidth", "focusWidth", "selectionMarkerWidth", "padding", "paddingLarge", "iconSize", "iconSizeLarge", "folderIconSize", "radius", "scrollBarWidth", "dialogMinWidth", "tooltipMaxWidth", "ornamentBandHeight", "ornamentFrameWidth", "cornerSize", "railWidth"]
    readonly property var windowKeys: ["activeBorder", "inactiveBorder", "activeTitleBg", "inactiveTitleBg", "activeTitleText", "inactiveTitleText", "buttonHoverBg"]

    // 테마 토큰 적용: t = { themeId, displayName, color:{}, window:{}, size:{}, font:{}, assets:{name:url} } (ThemeManager.tokens 형식).
    // 없는 키는 그대로 둔다. 치수는 정수만 받는다.
    function applyTokens(t) {
        if (!t) return
        var i, k
        var c = t.color || {}
        for (i = 0; i < colorKeys.length; ++i) { k = colorKeys[i]; if (c[k] !== undefined) theme[k] = c[k] }
        var w = t.window || {}
        for (i = 0; i < windowKeys.length; ++i) { k = windowKeys[i]; if (w[k] !== undefined) theme["window" + k.charAt(0).toUpperCase() + k.slice(1)] = w[k] }
        if (w.borderWidth !== undefined) windowBorderWidth = w.borderWidth
        if (w.cornerRadius !== undefined) windowCornerRadius = w.cornerRadius
        var s = t.size || {}
        for (i = 0; i < sizeKeys.length; ++i) { k = sizeKeys[i]; if (s[k] !== undefined && isFinite(s[k])) theme[k] = Math.round(s[k]) }
        var f = t.font || {}
        if (f.family) fontFamily = f.family
        if (f.familyKo) fontFamilyKo = f.familyKo
        if (f.monoFamily) monoFamily = f.monoFamily
        if (f.size) fontSize = f.size
        if (f.sizeSmall) fontSizeSmall = f.sizeSmall
        if (f.sizeTitle) fontSizeTitle = f.sizeTitle
        if (f.lineHeight) lineHeight = f.lineHeight
        themeAssets = t.assets || ({})
        if (t.themeId) themeId = t.themeId
        if (t.displayName) themeName = t.displayName
    }

    // 자산: 1) 현재 테마 팩 assets/<name>.svg  2) 모듈 assets/<name>.svg (libs/hagraui/qml/HagraUI/assets, 모듈과 함께 설치)
    function asset(name) { var u = themeAssets[name]; return u ? u : Qt.resolvedUrl("assets/" + name + ".svg") }
    // 외부 아이콘 디렉터리(선택): HAGRA_ICON_PATH / --icons. 없으면 빈 문자열 → MIcon 이 자리 표시자를 그린다.
    property string iconBasePath: ""
    function iconSource(name) { return iconBasePath.length ? iconBasePath + "/" + name + ".svg" : "" }
    // 분백 잉크 변형(<name>-light.svg)이 있는 조작 아이콘 (생성 시 모듈 assets/ 를 스캔). MIcon { light: true } 가 이 목록에 있을 때만 변형을 찾는다.
    readonly property var lightIcons: ["accessibility", "apps", "back", "battery", "battery-charging", "bell", "bell-off", "calendar", "check", "clock", "close", "cursor", "display", "download", "drive", "error", "ethernet", "file", "folder", "forward", "globe", "home", "image", "info", "keyboard", "language", "lock", "menu", "moon", "mouse", "network", "network-off", "palette", "power", "refresh", "reset", "search", "speaker", "speaker-muted", "star", "sun", "terminal", "text-size", "trash", "up", "usb", "view-grid", "view-list", "window", "workspace"]
    // 어두운 면 판정 (패널·사이드바 위의 글자·아이콘·포커스 링 선택용). c 는 color 값.
    function isDark(c) { return (0.299 * c.r + 0.587 * c.g + 0.114 * c.b) < 0.5 }
}
