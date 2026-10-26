import QtQuick
import HagraUI 1.0

Text {
    Accessible.role: Accessible.StaticText
    Accessible.name: text
    property bool muted: false
    property bool wrap: false
    property color textColor: Theme.text          // 역할별 전경 (패널: Theme.panelText, 사이드바: Theme.sidebarText)
    property color mutedColor: Theme.textMuted
    color: enabled ? (muted ? mutedColor : textColor) : Theme.textDisabled
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    elide: wrap ? Text.ElideNone : Text.ElideRight
    wrapMode: wrap ? Text.Wrap : Text.NoWrap
    lineHeight: Theme.lineHeight
    verticalAlignment: Text.AlignVCenter
    renderType: Text.NativeRendering
}
