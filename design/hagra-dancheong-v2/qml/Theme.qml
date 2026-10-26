// Deep-dancheong preset only: register via the theme manager, never overwrite the global Theme singleton.
// Hagra handoff 2.0; existing MinUI property names preserved.
pragma Singleton
import QtQuick
QtObject {
    readonly property color bg: "#183C35"
    readonly property color surface: "#F2EADB"
    readonly property color surfaceRaised: "#E4DAC6"
    readonly property color border: "#728D78"
    readonly property color borderStrong: "#28574A"
    readonly property color text: "#20352E"
    readonly property color textMuted: "#4D6055"
    readonly property color textDisabled: "#788178"
    readonly property color accent: "#28574A"
    readonly property color accentText: "#F2EADB"
    readonly property color warning: "#79541B"
    readonly property color danger: "#A52E20"
    readonly property color titleActive: "#28574A"
    readonly property color titleInactive: "#52695A"
    readonly property color selection: "#BDD7C6"
    readonly property color selectionText: "#20352E"
    readonly property color coral: "#C74729"
    readonly property color celadon: "#2FA58F"
    readonly property color blue: "#203C7A"
    readonly property color ochre: "#C29A4B"
    readonly property color ivory: "#F2EADB"
    readonly property color patternInk: "#183C35"
    readonly property color titleText: "#F2EADB"
    readonly property color titleInactiveText: "#F2EADB"
    readonly property color panel: "#183C35"
    readonly property color panelText: "#F2EADB"
    readonly property color sidebar: "#28574A"
    readonly property color sidebarText: "#F2EADB"
    readonly property color redBrown: "#643C32"
    readonly property color focus: "#203C7A"
    readonly property int unit: 4
    readonly property int panelHeight: 52
    readonly property int titleBarHeight: 40
    readonly property int rowHeight: 40
    readonly property int controlHeight: 36
    readonly property int borderWidth: 1
    readonly property int padding: 8
    readonly property int paddingLarge: 16
    readonly property int iconSize: 24
    readonly property int radius: 2
    readonly property int fontSize: 15
    readonly property int fontSizeSmall: 13
    readonly property int fontSizeTitle: 16
    readonly property int ornamentBandHeight: 18
    readonly property int ornamentFrameWidth: 6
    readonly property int cornerSize: 24
    readonly property int railWidth: 72
    readonly property int folderIconSize: 72
    readonly property int focusWidth: 2
    readonly property string fontFamily: "Noto Sans CJK KR"
    readonly property string monoFamily: "DejaVu Sans Mono"
}
