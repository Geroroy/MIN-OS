// 설정 → 알림: 방해 금지·표시 시간·위치 (notifications.conf, 셸 알림 서버가 읽음), 서버 상태, 테스트 알림.
import QtQuick
import HagraUI 1.0
import HagraSettings 1.0
import ".."

SPage {
    id: page
    title: "알림"
    subtitle: Notify.server.running ? "알림 서버: " + Notify.server.name + " " + Notify.server.version + " (" + Notify.server.vendor + ")" : "세션에 알림 서버(org.freedesktop.Notifications)가 없습니다"
    ConfFile { id: conf; name: "notifications" }
    readonly property int rev: conf.revision
    Timer { interval: 4000; running: page.visible; repeat: true; onTriggered: Notify.refresh() }

    SNote { visible: !Notify.server.busOk; kind: "unavailable"; title: "세션 D-Bus 없음"; text: "알림은 세션 버스가 필요합니다. hagra-session 은 dbus-run-session 또는 systemd --user 버스를 사용합니다." }
    SNote { visible: Notify.server.busOk && !Notify.server.running; kind: "warn"; title: "알림 서버가 실행 중이 아닙니다"
            text: "하그라 셸이 알림 서버를 제공합니다. 셸이 실행 중인지 확인하세요 (hagra-shell). 설정은 저장되며 서버가 뜨면 반영됩니다." }
    SRow { label: "방해 금지"; description: "켜면 팝업을 띄우지 않고 알림 센터에만 쌓습니다 (긴급 알림 제외)."
        MCheckBox { checked: conf.get("notifications/doNotDisturb", false) === true || String(conf.get("notifications/doNotDisturb", false)) === "true"; text: checked ? "켜짐" : "꺼짐"
                    onToggled: (c) => conf.set("notifications/doNotDisturb", c) } }
    SRow { label: "팝업 표시 시간"
        MSlider { from: 2; to: 20; stepSize: 1; value: parseInt(conf.get("notifications/timeoutSec", 6)); valueText: parseInt(conf.get("notifications/timeoutSec", 6)) + "초"; live: false; width: 260
                  onMoved: (x) => conf.set("notifications/timeoutSec", x) } }
    SRow { label: "팝업 위치"
        SChoice { current: String(conf.get("notifications/position", "top-right")) + "​".repeat(page.rev % 2)   // revision 에 묶어 다시 평가
                  options: [ { id: "top-right", label: "오른쪽 위" }, { id: "top-left", label: "왼쪽 위" }, { id: "bottom-right", label: "오른쪽 아래" } ]
                  onSelected: (id) => conf.set("notifications/position", id) } }
    SRow { label: "소리"; description: "알림 소리는 아직 제공하지 않습니다 (소리 서버·효과음 파일 미포함)."; MLabel { text: "없음"; muted: true } }
    Row { spacing: Theme.padding
        MButton { text: "테스트 알림 보내기"; icon: "bell"; enabled: Notify.server.running; onClicked: Notify.sendTest("하그라 알림 테스트", "이 알림이 보이면 서버가 정상입니다.") }
        MButton { text: "다시 확인"; icon: "refresh"; onClicked: Notify.refresh() }
    }
}
