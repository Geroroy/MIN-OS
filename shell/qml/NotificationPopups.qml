// 알림 팝업 (overlay, 설정의 위치에 따라 모서리 고정). 최근 3개, 만료되면 사라진다. 클릭 = 팝업 내림, 동작 버튼 = ActionInvoked.
import QtQuick
import HagraLayerShell 1.0
import HagraUI 1.0
import HagraShell 1.0

LayerWindow {
    id: popups
    scope: "hagra-notifications"
    layer: LayerWindow.Overlay
    readonly property string pos: Notifications.position
    anchors: (pos.indexOf("left") >= 0 ? LayerWindow.AnchorLeft : LayerWindow.AnchorRight) | (pos.indexOf("bottom") >= 0 ? LayerWindow.AnchorBottom : LayerWindow.AnchorTop)
    marginTop: 12; marginRight: 12; marginLeft: 12; marginBottom: 12
    keyboardInteractivity: LayerWindow.KeyboardNone
    width: 360
    height: Math.max(1, stack.implicitHeight)
    color: "transparent"
    visible: Notifications.popups.length > 0
    Column {
        id: stack
        width: parent.width
        spacing: Theme.padding
        Repeater { model: Notifications.popups
            delegate: MNotification { required property var modelData
                width: stack.width
                appName: modelData.appName; title: modelData.summary; body: modelData.body; urgent: modelData.urgency === 2
                actions: modelData.actions.map((a) => ({ text: a.text }))
                onActionClicked: (i) => Notifications.invokeAction(modelData.nid, modelData.actions[i].key)
                onClosed: Notifications.dismissPopup(modelData.nid)
                MouseArea { anchors.fill: parent; z: -1; onClicked: Notifications.dismissPopup(modelData.nid) }
            } }
    }
}
