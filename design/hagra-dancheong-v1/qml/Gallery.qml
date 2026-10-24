import QtQuick
import QtQuick.Controls
import "." as H

ApplicationWindow {
    id: window
    visible: true; width: 1040; height: 720
    title: "하그라 · 디자인 부품 미리보기"
    color: H.Theme.surface
    font.family: H.Theme.fontFamily
    font.pixelSize: H.Theme.fontSize
    Column {
        anchors.fill: parent; anchors.margins: 28; spacing: 20
        Text { text: window.title; color: H.Theme.text; font.pixelSize: 24 }
        Text { text: "SVG 자산 및 장식 레이어 검증용 · 실제 셸/파일 관리자는 별도 구현"; color: H.Theme.textMuted }
        H.MotifBand { width: parent.width }
        Row {
            spacing: 16
            Repeater {
                model: ["folder-writing", "folder-translation", "folder-reference", "folder-project", "document", "settings"]
                Image {
                    required property string modelData
                    source: "../assets/" + modelData + ".svg"
                    width: 80; height: 80; sourceSize.width: 160; sourceSize.height: 160
                }
            }
        }
        Rectangle {
            width: parent.width; height: 240; color: H.Theme.surfaceRaised
            H.OrnamentFrame { anchors.fill: parent }
            Column {
                anchors.fill: parent; anchors.margins: 32; spacing: 16
                Text { text: "한글과 English · 번역 노트 2026"; color: H.Theme.text; font.pixelSize: 20 }
                Row {
                    spacing: 12
                    Button { text: "기본 버튼" }
                    Button { text: "비활성"; enabled: false }
                    TextField { placeholderText: "한글 입력 확인"; width: 240 }
                }
                Text { text: "위 컨트롤은 Qt 기본 스타일입니다. 최종 MinUI 스킨 구현은 별도 단계입니다."; color: H.Theme.textMuted }
                Text { text: "키보드 Tab 이동 · IME 조합 · 100/150/200% 배율을 대상 Qt에서 확인하세요."; color: H.Theme.textMuted }
            }
        }
        Text { text: "현재 시간: " + Qt.formatDateTime(new Date(), "yyyy-MM-dd HH:mm"); color: H.Theme.text }
    }
}
