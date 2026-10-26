import QtQuick
import HagraUI 1.0

// 작은 확인 대화상자 = 별도 최상위 창. 창 장식(제목·닫기)은 labwc 가 그린다. Esc = 거부, Enter = 기본 버튼.
Window {
    id: dlg
    property alias dialogTitle: body.title
    property alias message: body.message
    property alias buttons: body.buttons
    signal accepted()
    signal rejected()
    title: dialogTitle
    modality: Qt.WindowModal
    flags: Qt.Dialog
    color: Theme.surface
    width: body.implicitWidth; height: body.implicitHeight
    minimumWidth: width; minimumHeight: height; maximumWidth: width; maximumHeight: height
    MDialogContent {
        id: body
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: { dlg.rejected(); dlg.close() }
        onButtonClicked: (role) => { if (role === "accept" || role === "destructive") dlg.accepted(); else dlg.rejected(); dlg.close() }
    }
}
