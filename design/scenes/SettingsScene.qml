// 대표 장면의 보조 창: 설정 → 모양 (디자인 검증용 예제). 설정 앱은 M2 에서 구현되므로 여기의 조작은 저장되지 않는다.
// 기준 시안: design/hagra-dancheong-v1/reference/hagra-dancheong-concept.png (설정 창, 비활성 상태 확인용).
import QtQuick
import MinUI 1.0

Window {
    id: win
    title: "설정"
    width: 560; height: 500
    minimumWidth: 400; minimumHeight: 320
    color: Theme.surface
    visible: true
    readonly property int inset: Theme.ornamentFrameWidth
    property int scheme: 0
    property int pointColor: 1

    Column {
        id: content
        anchors.fill: parent; anchors.margins: win.inset; spacing: 0
        MOrnamentBand { width: parent.width }
        MSeparator { width: parent.width }
        Row { width: parent.width; height: content.height - y
            Rectangle { id: side; width: Math.min(150, parent.width / 3); height: parent.height; color: Theme.bg
                Column { id: sideList; width: parent.width; y: Theme.padding
                    Repeater { model: [ { t: "시스템", i: "settings" }, { t: "모양", i: "lotus" }, { t: "입력", i: "window" }, { t: "저장 장치", i: "drive" } ]
                        delegate: MListRow { required property var modelData; required property int index
                            text: modelData.t; icon: modelData.i; selected: index === 1; leftPadding: Theme.paddingLarge } }
                }
                Item { anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                       height: Math.max(0, Math.min(72, side.height - sideList.height - Theme.paddingLarge * 3))
                    Image { anchors.fill: parent; source: Theme.asset("lattice-tile"); fillMode: Image.Tile; sourceSize: Qt.size(48, 48); opacity: 0.55; smooth: true } }
                MSeparator { vertical: true; anchors.right: parent.right }
            }
            Flickable { width: parent.width - side.width; height: parent.height; contentHeight: form.height + Theme.paddingLarge * 2; clip: true
                Column { id: form; x: Theme.paddingLarge; y: Theme.paddingLarge; width: parent.width - Theme.paddingLarge * 2; spacing: Theme.paddingLarge
                    MLabel { text: "모양"; font.pixelSize: Theme.fontSizeTitle; font.bold: true }

                    MLabel { text: "색 구성"; muted: true; font.pixelSize: Theme.fontSizeSmall }
                    Row { spacing: Theme.paddingLarge
                        Repeater { model: [ { t: "단청", a: "bojagi-tile" }, { t: "연화", a: "lotus" }, { t: "창살", a: "lattice-tile" } ]
                            delegate: Column { required property var modelData; required property int index; spacing: Theme.padding
                                Rectangle { width: 96; height: 64; radius: Theme.radius; color: Theme.surfaceRaised
                                    border.width: index === win.scheme ? 2 : 1; border.color: index === win.scheme ? Theme.accent : Theme.border
                                    Image { anchors.fill: parent; anchors.margins: 6; source: Theme.asset(modelData.a); fillMode: Image.PreserveAspectFit; sourceSize: Qt.size(96, 96); smooth: true }
                                    MouseArea { anchors.fill: parent; onClicked: win.scheme = index }
                                    MToolTip { text: "예제: 선택 표시만 바뀌고 저장되지 않습니다" }
                                }
                                MLabel { text: modelData.t; width: 96; horizontalAlignment: Text.AlignHCenter; font.bold: index === win.scheme }
                            } }
                    }
                    MOrnamentDivider { width: parent.width; height: 20 }

                    MLabel { text: "포인트 색상"; muted: true; font.pixelSize: Theme.fontSizeSmall }
                    Row { spacing: Theme.paddingLarge
                        Repeater { model: [Theme.coral, Theme.accent, Theme.celadon, Theme.ochre, Theme.blue, Theme.danger]
                            delegate: Rectangle { required property var modelData; required property int index
                                width: 36; height: 36; radius: 18; color: modelData
                                border.width: index === win.pointColor ? 3 : 0; border.color: Theme.text
                                MouseArea { anchors.fill: parent; onClicked: win.pointColor = index }
                                Image { visible: index === win.pointColor; anchors.centerIn: parent; width: 16; height: 16; source: Theme.asset("check"); sourceSize: Qt.size(32, 32) }
                            } }
                    }
                    MOrnamentDivider { width: parent.width; height: 20 }

                    MLabel { text: "아이콘 크기"; muted: true; font.pixelSize: Theme.fontSizeSmall }
                    Row { spacing: Theme.paddingLarge
                        MIcon { name: "lotus"; size: Theme.iconSize; anchors.verticalCenter: parent.verticalCenter }
                        MProgressBar { value: 0.5; width: 200; anchors.verticalCenter: parent.verticalCenter; MToolTip { text: "예제: 슬라이더는 설정 앱(M2)에서 구현" } }
                        MLabel { text: "중간"; muted: true; anchors.verticalCenter: parent.verticalCenter }
                    }

                    MLabel { text: "창 테두리 스타일"; muted: true; font.pixelSize: Theme.fontSizeSmall }
                    MComboBox { model: ["단청", "연화", "창살"]; currentIndex: 0; width: 240 }

                    MLabel { text: "예제 화면 — 이 창의 조작은 저장되지 않습니다 (설정 앱은 M2)."; muted: true; font.pixelSize: Theme.fontSizeSmall; wrap: true; width: parent.width }
                }
            }
        }
    }
    MOrnamentFrame { anchors.fill: parent; active: win.active; z: 20 }
}
