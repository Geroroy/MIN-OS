import QtQuick
import MinUI 1.0

// 반복 연화 띠 (장식 전용, 입력을 받지 않음). 가로로 타일링한다. 세로 변에는 쓰지 않는다(꽃잎이 늘어남).
// 원본 SVG: design/hagra-dancheong-v1/assets/lotus-band.svg (108×18). 모듈 사본 assets/lotus-band.svg 를 Theme.asset() 으로 읽는다.
// compact=true 이면 패널용 8px 축소형. 자산이 없으면 단색 겹선으로 대체한다.
Item {
    id: band
    property bool compact: false
    property string asset: "lotus-band"
    readonly property int bandHeight: compact ? Theme.panelBandHeight : Theme.ornamentBandHeight
    implicitHeight: bandHeight
    height: bandHeight
    clip: true
    Image {
        id: img
        anchors.fill: parent
        source: Theme.asset(band.asset)
        fillMode: Image.TileHorizontally
        sourceSize.width: Math.round(108 * band.bandHeight / 18)
        sourceSize.height: band.bandHeight
        smooth: true
        cache: true
        asynchronous: false
    }
    Column { // 대체: 산호·청자 겹선
        visible: img.status !== Image.Ready
        anchors.fill: parent
        Rectangle { width: parent.width; height: Math.max(1, band.bandHeight / 3); color: Theme.coral }
        Rectangle { width: parent.width; height: Math.max(1, band.bandHeight / 3); color: Theme.ivory }
        Rectangle { width: parent.width; height: Math.max(1, band.bandHeight / 3); color: Theme.celadon }
    }
}
