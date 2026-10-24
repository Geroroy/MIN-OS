import QtQuick
import MinUI 1.0

Text {
    property bool muted: false
    property bool wrap: false
    color: enabled ? (muted ? Theme.textMuted : Theme.text) : Theme.textDisabled
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    elide: wrap ? Text.ElideNone : Text.ElideRight
    wrapMode: wrap ? Text.Wrap : Text.NoWrap
    lineHeight: Theme.lineHeight
    verticalAlignment: Text.AlignVCenter
    renderType: Text.NativeRendering
}
