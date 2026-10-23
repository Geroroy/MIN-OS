import QtQuick
import MinUI 1.0

Text {
    property bool muted: false
    color: enabled ? (muted ? Theme.textMuted : Theme.text) : Theme.textDisabled
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    elide: Text.ElideRight
    verticalAlignment: Text.AlignVCenter
    renderType: Text.NativeRendering
}
