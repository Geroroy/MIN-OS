// 설정 → 정보: 하그라 버전·기반·빌드, 하드웨어, 세션, 로그 보기
import QtQuick
import HagraUI 1.0
import HagraTheme 1.0
import HagraSettings 1.0
import ".."

SPage {
    id: page
    title: SystemInfo.info.hagraName + qsTr(" 정보")
    subtitle: "HAGRA " + SystemInfo.info.hagraVersion + (SystemInfo.info.hagraBase.length ? qsTr(" · 기반 ") + SystemInfo.info.hagraBase : "") + (SystemInfo.info.live ? qsTr(" · 라이브 매체 (설정이 재부팅 후 남지 않음)") : "")
    property string logText: ""
    property string logTitle: ""
    function fmtUptime(s) { var h = Math.floor(s / 3600), m = Math.floor((s % 3600) / 60); return h + qsTr("시간 ") + m + qsTr("분") }
    readonly property var rows: [
        [qsTr("운영체제"), SystemInfo.info.osPretty], [qsTr("커널"), SystemInfo.info.kernel + " (" + SystemInfo.info.arch + ")"],
        [qsTr("호스트 이름"), SystemInfo.info.hostname + qsTr(" · 사용자 ") + SystemInfo.info.user],
        [qsTr("프로세서"), SystemInfo.info.cpu + " × " + SystemInfo.info.cores], [qsTr("메모리"), SystemInfo.info.memTotal + qsTr(" (사용 가능 ") + SystemInfo.info.memFree + ")"],
        [qsTr("디스크 (/)"), SystemInfo.info.diskTotal + " " + SystemInfo.info.diskFs + qsTr(" (남음 ") + SystemInfo.info.diskFree + ")"],
        [qsTr("가동 시간"), fmtUptime(SystemInfo.info.uptimeSec || 0)],
        [qsTr("컴포지터"), SystemInfo.info.compositor], [qsTr("세션"), SystemInfo.info.session + qsTr(" · 렌더링 ") + SystemInfo.info.renderer],
        ["Qt", SystemInfo.info.qtVersion], [qsTr("화면"), (SystemInfo.info.screens || []).join("\n")],
        [qsTr("테마"), ThemeManager.currentName + " (" + ThemeManager.currentId + ")" + (ThemeManager.accentId.length ? qsTr(" · 포인트 ") + ThemeManager.accentId : "")],
        [qsTr("빌드"), SystemInfo.info.hagraBuildDate.length ? SystemInfo.info.hagraBuildDate : qsTr("개발 호스트 빌드")],
    ]
    Row { spacing: Theme.paddingLarge; width: parent.width
        MIcon { name: "lotus"; size: 64 }
        Column { anchors.verticalCenter: parent.verticalCenter; spacing: 2
            MLabel { text: Theme.brandName + " · " + Theme.brandNameLatin; font.bold: true; font.pixelSize: Theme.fontSizeTitle + 6 }
            MLabel { text: qsTr("한국의 미감과 생활에 대한 이해를 바탕으로 만드는 데스크톱 운영체제"); muted: true; font.pixelSize: Theme.fontSizeSmall }
        }
    }
    Column { width: parent.width; spacing: 0
        Repeater { model: page.rows
            delegate: Item { required property var modelData; required property int index; width: parent.width; height: Math.max(Theme.rowHeight, val.implicitHeight + Theme.padding * 2)
                Rectangle { anchors.fill: parent; color: index % 2 ? "transparent" : Theme.surfaceRaised; radius: Theme.radius }
                MLabel { x: Theme.paddingLarge; width: 140; anchors.verticalCenter: parent.verticalCenter; text: modelData[0]; muted: true; font.pixelSize: Theme.fontSizeSmall }
                MLabel { id: val; x: 150 + Theme.paddingLarge; width: parent.width - x - Theme.paddingLarge; anchors.verticalCenter: parent.verticalCenter; text: modelData[1] || ""; wrap: true
                         Accessible.name: modelData[0] + ": " + modelData[1] }
            } }
    }
    SSection { title: qsTr("진단") }
    Row { spacing: Theme.padding
        MButton { text: qsTr("세션 로그"); onClicked: { page.logTitle = SystemInfo.sessionLogPath(); page.logText = SystemInfo.readTail(SystemInfo.sessionLogPath(), 80) } }
        MButton { text: qsTr("셸 로그"); onClicked: { page.logTitle = SystemInfo.shellLogPath(); page.logText = SystemInfo.readTail(SystemInfo.shellLogPath(), 80) } }
        MButton { text: qsTr("테마 설정 파일"); onClicked: { page.logTitle = ThemeManager.configFilePath; page.logText = SystemInfo.readTail(ThemeManager.configFilePath, 40) } }
        MButton { text: qsTr("새로 고침"); icon: "refresh"; onClicked: SystemInfo.refresh() }
    }
    Column { visible: page.logText.length > 0; width: parent.width; spacing: 4
        MLabel { text: page.logTitle; muted: true; font.pixelSize: Theme.fontSizeSmall; width: parent.width; elide: Text.ElideMiddle }
        Rectangle { width: parent.width; height: Math.min(320, logLabel.implicitHeight + Theme.paddingLarge); color: Theme.surfaceRaised; border.width: 1; border.color: Theme.border; radius: Theme.radius; clip: true
            Flickable { anchors.fill: parent; anchors.margins: Theme.padding; contentHeight: logLabel.implicitHeight; clip: true
                MLabel { id: logLabel; width: parent.width; text: page.logText; wrap: true; font.family: Theme.monoFamily; font.pixelSize: 12; lineHeight: 1.2 } }
        }
    }
    SNote { text: qsTr("저장소: github.com/Geroroy/MIN-OS · 라이선스 GPL-3.0-or-later. 문제 보고 시 위 로그와 '정보' 항목을 함께 보내 주세요.") }
}
