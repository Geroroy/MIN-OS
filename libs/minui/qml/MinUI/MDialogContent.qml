import QtQuick
import MinUI 1.0

// 대화상자 내용(제목·본문·버튼). MDialogWindow 가 별도 창으로 감싸고, 갤러리는 모형으로 직접 표시한다.
Rectangle {
    id: content
    property string title: ""
    property string message: ""
    property var buttons: [ { text: "확인", role: "accept", isDefault: true } ]   // role: accept|reject|destructive
    signal buttonClicked(string role, int index)
    implicitWidth: Math.max(Theme.dialogMinWidth, body.implicitWidth + Theme.paddingLarge * 4)
    implicitHeight: col.implicitHeight + Theme.paddingLarge * 2
    color: Theme.surface
    Column {
        id: col
        anchors.fill: parent; anchors.margins: Theme.paddingLarge
        spacing: Theme.paddingLarge
        MLabel { text: content.title; font.pixelSize: Theme.fontSizeTitle; font.bold: true; width: parent.width; visible: text.length > 0 }
        MOrnamentDivider { width: parent.width; visible: content.title.length > 0 }
        MLabel { id: body; text: content.message; wrap: true; width: parent.width; visible: text.length > 0 }
        Row {
            anchors.right: parent.right; spacing: Theme.padding
            Repeater {
                model: content.buttons
                delegate: MButton {
                    required property int index
                    required property var modelData
                    text: modelData.text
                    defaultButton: modelData.isDefault === true
                    danger: modelData.role === "destructive"
                    // 보이지 않는 대화상자 내용이 창의 포커스를 가져가지 않도록 가시성 조건을 둔다
                    focus: modelData.isDefault === true && content.visible
                    onClicked: content.buttonClicked(modelData.role, index)
                }
            }
        }
    }
}
