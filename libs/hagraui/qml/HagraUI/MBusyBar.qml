import QtQuick
import HagraUI 1.0

// 진행 중 상태의 가는 이동 막대 (허용된 유일한 애니메이션: 진행 표시기)
Rectangle {
    id: bar
    height: 2
    color: "transparent"
    property int tick: 0
    Rectangle {
        width: Math.max(16, bar.width / 4); height: parent.height
        x: ((bar.tick * 8) % (bar.width + width)) - width
        color: Theme.accent
    }
    Timer { interval: 50; running: bar.visible; repeat: true; onTriggered: bar.tick = (bar.tick + 1) % 100000 }
}
