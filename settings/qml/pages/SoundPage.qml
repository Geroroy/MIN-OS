// 설정 → 소리: 기본 출력 볼륨·음소거, 마이크 음소거, 출력 장치 (wpctl/pactl 가 있을 때만)
import QtQuick
import HagraUI 1.0
import HagraSettings 1.0
import ".."

SPage {
    id: page
    title: qsTr("소리")
    subtitle: Sound.available ? qsTr("도구: ") + Sound.tool : ""
    Timer { interval: 3000; running: Sound.available && page.visible; repeat: true; onTriggered: Sound.refresh() }

    SNote { visible: !Sound.available; kind: "unavailable"; title: qsTr("소리 설정을 쓸 수 없습니다"); text: Sound.reason }
    SRow { visible: Sound.available; label: qsTr("출력 볼륨"); description: qsTr("100% 를 넘기면 소리가 왜곡될 수 있습니다.")
        MSlider { from: 0; to: 150; stepSize: 5; value: Sound.volume; valueText: Sound.volume + "%"; live: false; width: 280; onMoved: (v) => Sound.setVolume(v); enabled: !Sound.muted } }
    SRow { visible: Sound.available; label: qsTr("음소거"); MCheckBox { checked: Sound.muted; text: Sound.muted ? qsTr("꺼짐") : qsTr("켜짐"); onToggled: (c) => Sound.setMuted(c) } }
    SRow { visible: Sound.available; label: qsTr("마이크"); description: qsTr("기본 입력 장치 (볼륨 ") + Sound.micVolume + "%)"
        MCheckBox { checked: !Sound.micMuted; text: Sound.micMuted ? qsTr("음소거") : qsTr("사용"); onToggled: (c) => Sound.setMicMuted(!c) } }
    SSection { visible: Sound.available && Sound.sinks.length > 0; title: qsTr("출력 장치") }
    Column { visible: Sound.available; width: parent.width; spacing: 2
        Repeater { model: Sound.sinks
            delegate: MListRow { required property var modelData; text: modelData.name; detail: modelData.state; icon: "speaker"; onClicked: Sound.setDefaultSink(modelData.id) } }
    }
    SNote { visible: Sound.available && Sound.sinks.length === 0; text: qsTr("장치 목록은 pactl (pipewire-pulse) 이 있을 때 표시됩니다.") }
    MButton { visible: Sound.available; text: qsTr("다시 읽기"); icon: "refresh"; onClicked: Sound.refresh() }
}
