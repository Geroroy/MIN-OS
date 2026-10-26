// 설정 → 배경: 테마 배경 / 시스템·사용자 폴더의 이미지 격자, 경로 직접 지정. 즉시 적용(swaybg 재시작)·저장.
import QtQuick
import HagraUI 1.0
import HagraTheme 1.0
import HagraSettings 1.0
import ".."

SPage {
    id: page
    title: "배경"
    subtitle: "현재: " + ThemeManager.effectiveWallpaper
    property string draft: ThemeManager.userWallpaper
    property string message: ""
    Connections { target: ThemeManager; function onWallpaperChanged() { page.draft = ThemeManager.userWallpaper } }

    MCheckBox { text: "테마 기본 배경 사용 (테마를 바꾸면 배경도 함께 바뀜)"; checked: ThemeManager.useThemeWallpaper
                onToggled: (c) => { if (ThemeManager.useThemeWallpaper !== c) ThemeManager.useThemeWallpaper = c } }

    SSection { title: "이미지 고르기"; divider: false }
    Flow { id: grid; width: parent.width; spacing: Theme.paddingLarge
        Repeater { model: Wallpapers.items
            delegate: Column { required property var modelData
                readonly property bool cur: modelData.path === ThemeManager.effectiveWallpaper
                width: 180; spacing: 4
                Rectangle { width: 180; height: 102; color: Theme.bg; radius: Theme.radius
                    border.width: cur ? 3 : 1; border.color: cur ? Theme.accent : Theme.border
                    activeFocusOnTab: true
                    Accessible.role: Accessible.Button; Accessible.name: modelData.title + (cur ? " (현재 배경)" : "")
                    Keys.onSpacePressed: ThemeManager.userWallpaper = modelData.path
                    Keys.onReturnPressed: ThemeManager.userWallpaper = modelData.path
                    Rectangle { visible: parent.activeFocus; anchors.fill: parent; anchors.margins: -(Theme.focusRingWidth + 1); color: "transparent"; border.width: Theme.focusRingWidth; border.color: Theme.focusRing; z: 5 }
                    Image { anchors.fill: parent; anchors.margins: 2; source: modelData.url; fillMode: Image.PreserveAspectCrop; sourceSize.width: 360; asynchronous: true; smooth: true; cache: true }
                    MLabel { visible: cur; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 6; text: "✓"; font.bold: true; color: Theme.accentText
                             Rectangle { anchors.fill: parent; anchors.margins: -4; z: -1; radius: 10; color: Theme.accent } }
                    MouseArea { anchors.fill: parent; onClicked: { parent.forceActiveFocus(); ThemeManager.userWallpaper = modelData.path } }
                }
                MLabel { text: modelData.title; width: 180; elide: Text.ElideMiddle; font.pixelSize: Theme.fontSizeSmall }
                MLabel { text: modelData.source === "theme" ? "테마" : modelData.source === "user" ? "내 이미지" : "시스템"; muted: true; font.pixelSize: 11 }
            }
        }
    }
    SNote { visible: Wallpapers.items.length === 0; kind: "warn"; text: "배경 이미지를 찾지 못했습니다. 아래 경로에 PNG/JPG 를 넣거나 경로를 직접 지정하세요." }

    SSection { title: "직접 지정" }
    Row { spacing: Theme.padding; width: parent.width
        MTextField { id: field; width: parent.width - applyBtn.width - Theme.padding; placeholder: "이미지 파일 경로 (PNG/JPG/WebP)"; text: page.draft
                     onAccepted: applyBtn.clicked(); Accessible.name: "배경 이미지 경로" }
        MButton { id: applyBtn; text: "적용"; defaultButton: true; enabled: field.text.trim().length > 0
                  onClicked: { if (Wallpapers.isImage(field.text.trim())) { ThemeManager.userWallpaper = field.text.trim(); page.message = "" } else page.message = "이미지 파일을 읽을 수 없습니다: " + field.text } }
    }
    SNote { visible: page.message.length > 0; kind: "unavailable"; text: page.message }
    SNote { text: "검색 폴더: " + Wallpapers.searchDirs.join("  ·  ") + "\n내 이미지는 " + Wallpapers.userDir() + " 에 넣으면 목록에 나타납니다. 테마를 바꿔도 사용자 지정 배경은 유지됩니다." }
    MButton { text: "목록 새로 고침"; icon: "refresh"; onClicked: Wallpapers.refresh() }
}
