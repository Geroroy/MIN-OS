import QtQuick
// Decorative only: does not consume input. SVG uses no filters or external fonts.
Image {
    source: "../assets/lotus-band.svg"
    fillMode: Image.TileHorizontally
    sourceSize.width: 108
    sourceSize.height: 18
    height: 18
    smooth: true
    cache: true
    clip: true
}
