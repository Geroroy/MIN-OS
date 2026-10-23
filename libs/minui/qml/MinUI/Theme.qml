// MinUI Theme — docs/DESIGN_LANGUAGE.md 의 토큰. 기본 테마 "Graphite".
pragma Singleton
import QtQuick

QtObject {
    // 색상
    readonly property color bg:            "#1a1a1a"
    readonly property color surface:       "#242424"
    readonly property color surfaceRaised: "#2e2e2e"
    readonly property color border:        "#3a3a3a"
    readonly property color borderStrong:  "#5c5c5c"
    readonly property color text:          "#e4e4e4"
    readonly property color textMuted:     "#9a9a9a"
    readonly property color textDisabled:  "#5c5c5c"
    readonly property color accent:        "#3d7bd9"
    readonly property color accentText:    "#ffffff"
    readonly property color warning:       "#c9a227"
    readonly property color danger:        "#c0392b"

    // 치수 (px)
    readonly property int unit: 4
    readonly property int panelHeight: 28
    readonly property int titleBarHeight: 22
    readonly property int rowHeight: 20
    readonly property int controlHeight: 22
    readonly property int borderWidth: 1
    readonly property int padding: 4
    readonly property int paddingLarge: 8
    readonly property int iconSize: 16
    readonly property int radius: 0

    // 글꼴
    readonly property string fontFamily: "Inter"
    readonly property string monoFamily: "DejaVu Sans Mono"
    readonly property int fontSize: 12
    readonly property int fontSizeSmall: 11
    readonly property int fontSizeTitle: 13
}
