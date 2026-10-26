// 설정 → 네트워크: 인터페이스 상태(항상), Wi-Fi 검색·연결(NetworkManager 가 있을 때만)
import QtQuick
import HagraUI 1.0
import HagraSettings 1.0
import ".."

SPage {
    id: page
    title: "네트워크"
    subtitle: Network.online ? "연결됨 — 기본 경로: " + Network.defaultRoute : "기본 경로가 없습니다 (오프라인)"
    property string message: ""
    Timer { interval: 5000; running: page.visible; repeat: true; onTriggered: Network.refresh() }

    SNote { visible: !Network.managerAvailable; kind: "unavailable"; title: "네트워크 관리자 없음"; text: Network.reason }
    SSection { title: "인터페이스"; divider: false }
    Column { width: parent.width; spacing: 2
        Repeater { model: Network.interfaces
            delegate: MListRow { required property var modelData
                text: modelData.name + (modelData.isDefault ? "  (기본)" : "")
                detail: modelData.kind + " · " + (modelData.state.length ? modelData.state : (modelData.up ? "up" : "down")) + (modelData.addresses.length ? " · " + modelData.addresses : "") + (modelData.mac.length ? " · " + modelData.mac : "")
                icon: modelData.kind === "무선" ? "network" : "ethernet"; selected: false
                onClicked: {} } }
        MLabel { visible: Network.interfaces.length === 0; text: "네트워크 인터페이스가 없습니다"; muted: true }
    }
    SSection { visible: Network.managerAvailable; title: "Wi-Fi" }
    Row { visible: Network.managerAvailable; spacing: Theme.padding
        MButton { text: "검색"; icon: "refresh"; onClicked: Network.scanWifi() }
        MLabel { text: Network.wifi.length + "개 네트워크"; muted: true; anchors.verticalCenter: parent.verticalCenter }
    }
    Column { visible: Network.managerAvailable; width: parent.width; spacing: 2
        Repeater { model: Network.wifi
            delegate: MListRow { required property var modelData
                text: modelData.ssid; detail: "신호 " + modelData.signal + "% · " + (modelData.security.length && modelData.security !== "--" ? modelData.security : "열림") + (modelData.inUse ? " · 연결됨" : "")
                icon: "network"; selected: modelData.inUse
                onClicked: { ssidField.text = modelData.ssid; pwField.text = ""; pwField.forceActiveFocus() } } }
    }
    Column { visible: Network.managerAvailable; width: parent.width; spacing: Theme.padding
        Row { spacing: Theme.padding
            MTextField { id: ssidField; width: 220; placeholder: "SSID"; Accessible.name: "Wi-Fi 이름" }
            MTextField { id: pwField; width: 220; placeholder: "비밀번호 (열린 망이면 비움)"; echoMode: TextInput.Password; Accessible.name: "Wi-Fi 비밀번호"; onAccepted: connectBtn.clicked() }
            MButton { id: connectBtn; text: "연결"; defaultButton: true; enabled: ssidField.text.length > 0
                      onClicked: { var r = Network.connectWifi(ssidField.text, pwField.text); page.message = r.message } }
        }
        SNote { visible: page.message.length > 0; text: page.message }
    }
}
