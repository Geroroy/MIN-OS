// 설정 → 전원: 배터리(/sys), logind 동작(가능한 것만), 유휴 동작은 도구가 있을 때만.
import QtQuick
import HagraUI 1.0
import HagraSettings 1.0
import ".."

SPage {
    id: page
    title: qsTr("전원")
    subtitle: Power.batteries.length ? (Power.onBattery ? qsTr("배터리 사용 중") : qsTr("전원 연결됨")) : qsTr("배터리가 없는 장치입니다")
    property string message: ""
    Connections { target: Power; function onFailed(m) { page.message = m } }
    Timer { interval: 10000; running: page.visible; repeat: true; onTriggered: Power.refresh() }
    function can(k) { return Power.logind[k] === "yes" || Power.logind[k] === "challenge" }

    SSection { visible: Power.batteries.length > 0; title: qsTr("배터리"); divider: false }
    Repeater { model: Power.batteries
        delegate: Column { required property var modelData; width: parent.width; spacing: 4
            MLabel { text: modelData.name + (modelData.model.length ? " · " + modelData.model : "") + " — " + modelData.capacity + "% · " + modelData.status + (modelData.health > 0 ? qsTr(" · 수명 ") + modelData.health + "%" : "") }
            MProgressBar { width: Math.min(360, parent.width); value: Math.max(0, modelData.capacity) / 100 }
        } }

    SSection { title: qsTr("지금 실행"); divider: Power.batteries.length > 0 }
    SNote { visible: !Power.logind.available; kind: "unavailable"; title: qsTr("logind 에 연결할 수 없습니다"); text: qsTr("종료·절전은 systemd-logind D-Bus 가 필요합니다.") }
    Row { spacing: Theme.padding
        MButton { text: qsTr("절전"); enabled: can("CanSuspend"); onClicked: Power.action("Suspend"); MToolTip { text: Power.logind.CanSuspend === "na" ? qsTr("이 장치는 절전을 지원하지 않습니다") : "" } }
        MButton { text: qsTr("최대 절전"); enabled: can("CanHibernate"); onClicked: Power.action("Hibernate"); MToolTip { text: Power.logind.CanHibernate === "na" ? qsTr("스왑이 없어 최대 절전을 지원하지 않습니다") : "" } }
        MButton { text: qsTr("다시 시작"); enabled: can("CanReboot"); onClicked: Power.action("Reboot") }
        MButton { text: qsTr("시스템 종료"); danger: true; enabled: can("CanPowerOff"); onClicked: Power.action("PowerOff") }
    }
    SNote { visible: page.message.length > 0; kind: "unavailable"; text: page.message }
    SSection { title: qsTr("유휴 동작") }
    SNote { visible: !Power.idleToolAvailable; kind: "unavailable"; title: qsTr("자동 화면 끄기·절전 미지원"); text: Power.idleReason }
    SNote { visible: Power.idleToolAvailable; text: qsTr("swayidle 이 설치되어 있습니다. 유휴 시간 설정 UI는 아직 없습니다 — ~/.config/hagra/labwc/autostart 에서 swayidle 을 직접 실행하세요.") }
    SNote { text: qsTr("덮개 닫힘·전원 단추 동작은 /etc/systemd/logind.conf 의 HandleLidSwitch/HandlePowerKey 로 정해지며 관리자 권한이 필요합니다. 하그라 기본: 전원 단추 = 종료 메뉴 표시가 아니라 logind 기본(poweroff).") }
}
