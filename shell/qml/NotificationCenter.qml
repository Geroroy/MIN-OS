// 알림 센터 (패널 종 버튼): 모든 알림 목록 · 방해 금지 · 모두 지우기
import QtQuick
import HagraLayerShell 1.0
import HagraUI 1.0
import HagraShell 1.0

LayerWindow {
    id: center
    scope: "hagra-notification-center"
    layer: LayerWindow.Overlay
    property bool panelAtTop: false
    anchors: LayerWindow.AnchorRight | (panelAtTop ? LayerWindow.AnchorTop : LayerWindow.AnchorBottom)
    keyboardInteractivity: LayerWindow.KeyboardExclusive
    width: 380
    height: Math.max(260, Math.min(560, (Screen.height > 0 ? Screen.height : 720) - Theme.panelHeight - 8))
    color: Theme.surface
    visible: false
    function toggle() { visible = !visible }
    onVisibleChanged: if (visible) { Notifications.markRead(); content.forceActiveFocus() }
    Rectangle { anchors.fill: parent; color: "transparent"; border.width: Theme.windowBorderWidth; border.color: Theme.borderStrong; z: 10 }
    Item {
        id: content
        anchors.fill: parent; anchors.margins: Theme.windowBorderWidth
        focus: true
        Keys.onEscapePressed: center.visible = false
        Column { anchors.fill: parent; spacing: 0
            MOrnamentBand { width: parent.width }
            MSeparator { width: parent.width }
            Item { width: parent.width; height: Theme.controlHeight + Theme.paddingLarge
                MLabel { x: Theme.paddingLarge; anchors.verticalCenter: parent.verticalCenter; text: qsTr("알림"); font.bold: true; font.pixelSize: Theme.fontSizeTitle }
                MCheckBox { anchors.right: parent.right; anchors.rightMargin: Theme.paddingLarge; anchors.verticalCenter: parent.verticalCenter
                            text: qsTr("방해 금지"); checked: Notifications.doNotDisturb; onToggled: (c) => Notifications.doNotDisturb = c }
            }
            MSeparator { width: parent.width }
            ListView {
                id: list
                width: parent.width; height: parent.height - y - footer.height - 1
                clip: true; model: Notifications; spacing: Theme.padding; boundsBehavior: Flickable.StopAtBounds
                topMargin: Theme.padding; bottomMargin: Theme.padding
                delegate: Item { required property int index; required property int nid; required property string appName; required property string summary
                                 required property string body; required property var actions; required property int urgency; required property string timeText
                    width: list.width; height: card.implicitHeight
                    MNotification { id: card; x: Theme.padding; width: parent.width - Theme.padding * 2
                        appName: parent.appName + " · " + parent.timeText; title: parent.summary; body: parent.body; urgent: parent.urgency === 2
                        actions: parent.actions.map((a) => ({ text: a.text }))
                        onActionClicked: (i) => Notifications.invokeAction(parent.nid, parent.actions[i].key)
                        onClosed: Notifications.remove(parent.nid) }
                }
                MScrollBar { flickable: list; anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom }
                Column { anchors.centerIn: parent; spacing: Theme.padding; visible: Notifications.count === 0; width: parent.width - Theme.paddingLarge * 4
                    MIcon { name: "bell"; size: Theme.iconSizeLarge; anchors.horizontalCenter: parent.horizontalCenter; color: Theme.textMuted }
                    MLabel { text: qsTr("새 알림이 없습니다"); muted: true; horizontalAlignment: Text.AlignHCenter; width: parent.width }
                    MLabel { visible: !Notifications.registered; text: qsTr("알림 서버를 등록하지 못했습니다 (세션 D-Bus 없음 또는 다른 서버가 실행 중)"); muted: true; wrap: true; width: parent.width
                             horizontalAlignment: Text.AlignHCenter; font.pixelSize: Theme.fontSizeSmall }
                }
            }
            MSeparator { width: parent.width }
            Item { id: footer; width: parent.width; height: Theme.controlHeight + Theme.paddingLarge * 2
                MButton { text: qsTr("모두 지우기"); icon: "trash"; enabled: Notifications.count > 0; anchors.left: parent.left; anchors.leftMargin: Theme.paddingLarge; anchors.verticalCenter: parent.verticalCenter; onClicked: Notifications.clearAll() }
                MButton { text: qsTr("알림 설정"); icon: "settings"; anchors.right: parent.right; anchors.rightMargin: Theme.paddingLarge; anchors.verticalCenter: parent.verticalCenter
                          onClicked: { center.visible = false; Shell.dispatch("settings:notifications") } }
            }
        }
    }
}
