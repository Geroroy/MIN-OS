// 하그라 셸 — 모양 설정 창 (설정 → 모양 → 테마). 실제 동작: 테마 선택·저장·즉시 적용, 배경 선택.
// 설정 앱 전체는 M2 에서 구현되며 그때 이 창의 내용을 가져간다. 창 장식은 labwc(SSD).
import QtQuick
import MinUI 1.0
import HagraTheme 1.0

Window {
    id: win
    title: "모양 설정 — " + Theme.brandName
    width: 640; height: 520
    minimumWidth: 480; minimumHeight: 400
    color: Theme.surface
    visible: false

    readonly property int inset: Theme.ornamentFrameWidth
    property string wallpaperDraft: ThemeManager.userWallpaper

    Column {
        anchors.fill: parent; anchors.margins: win.inset; spacing: 0
        MOrnamentBand { width: parent.width }
        MSeparator { width: parent.width }

        Flickable { width: parent.width; height: parent.height - y; contentHeight: form.height + Theme.paddingLarge * 2; clip: true
            Column { id: form; x: Theme.paddingLarge; y: Theme.paddingLarge; width: parent.width - Theme.paddingLarge * 2; spacing: Theme.paddingLarge
                MLabel { text: "테마"; font.pixelSize: Theme.fontSizeTitle; font.bold: true }
                MLabel { text: "선택하면 바로 저장되고 셸·배경·창 장식에 적용됩니다. 재로그인 후에도 유지됩니다."; muted: true; font.pixelSize: Theme.fontSizeSmall; wrap: true; width: parent.width }

                // 테마 목록: 이름 · 미리보기 · 현재 선택 표시. 방향키/Space/Enter 로 선택.
                Column { id: list; width: parent.width; spacing: Theme.padding
                    property int focusIndex: 0
                    activeFocusOnTab: true
                    Keys.onUpPressed: focusIndex = Math.max(0, focusIndex - 1)
                    Keys.onDownPressed: focusIndex = Math.min(ThemeManager.themes.length - 1, focusIndex + 1)
                    Keys.onSpacePressed: ThemeManager.apply(ThemeManager.themes[focusIndex].id)
                    Keys.onReturnPressed: ThemeManager.apply(ThemeManager.themes[focusIndex].id)
                    Keys.onEnterPressed: ThemeManager.apply(ThemeManager.themes[focusIndex].id)
                    Repeater {
                        model: ThemeManager.themes
                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            readonly property bool cur: modelData.current
                            readonly property bool foc: list.activeFocus && list.focusIndex === index
                            width: list.width; height: 112
                            radius: Theme.radius
                            color: cur ? Theme.selection : (hov.containsMouse ? Theme.surfaceRaised : Theme.surface)
                            border.width: Theme.borderWidth; border.color: cur ? Theme.accent : Theme.border
                            Rectangle { visible: cur; width: Theme.selectionMarkerWidth; height: parent.height; color: Theme.accent }
                            Rectangle { visible: foc; anchors.fill: parent; anchors.margins: -(Theme.focusRingWidth + 1); z: 5; color: "transparent"; radius: Theme.radius
                                        border.width: Theme.focusRingWidth; border.color: Theme.focusRing }
                            Row { anchors.fill: parent; anchors.margins: Theme.padding; anchors.leftMargin: Theme.paddingLarge; spacing: Theme.paddingLarge
                                Rectangle { width: 160; height: 90; color: Theme.bg; border.width: 1; border.color: Theme.border; anchors.verticalCenter: parent.verticalCenter
                                    Image { anchors.fill: parent; anchors.margins: 1; source: modelData.preview; fillMode: Image.PreserveAspectCrop; sourceSize.width: 280; smooth: true; cache: true }
                                }
                                Column { id: info; anchors.verticalCenter: parent.verticalCenter; spacing: 2; width: parent.width - 160 - Theme.paddingLarge * 2 - 90
                                    Row { spacing: Theme.padding
                                        MLabel { text: modelData.displayName; font.bold: true; font.pixelSize: Theme.fontSizeTitle; color: cur ? Theme.selectionText : Theme.text }
                                        MLabel { visible: modelData.isDefault; text: "기본"; muted: true; font.pixelSize: Theme.fontSizeSmall; anchors.verticalCenter: parent.verticalCenter }
                                    }
                                    MLabel { text: modelData.description; wrap: true; width: info.width; maximumLineCount: 2; elide: Text.ElideRight
                                             font.pixelSize: Theme.fontSizeSmall; color: cur ? Theme.selectionText : Theme.textMuted }
                                    MLabel { text: modelData.id; muted: true; font.pixelSize: 11; font.family: Theme.monoFamily; color: cur ? Theme.selectionText : Theme.textMuted }
                                }
                                Item { width: 90; height: parent.height
                                    MLabel { anchors.centerIn: parent; visible: cur; text: "✓ 현재"; font.bold: true; color: Theme.selectionText }
                                    MButton { anchors.centerIn: parent; visible: !cur; text: "선택"; onClicked: ThemeManager.apply(modelData.id) }
                                }
                            }
                            MouseArea { id: hov; anchors.fill: parent; hoverEnabled: true; z: -1
                                        onClicked: { list.focusIndex = index; list.forceActiveFocus(); ThemeManager.apply(modelData.id) } }
                        }
                    }
                }
                MButton { text: "기본 테마로"; enabled: ThemeManager.currentId !== ThemeManager.defaultId; onClicked: ThemeManager.resetToDefault() }
                MLabel { muted: true; font.pixelSize: Theme.fontSizeSmall; wrap: true; width: parent.width
                         text: ThemeManager.sessionReloadSupported ? "창 장식(labwc)은 재구성 명령으로 즉시 갱신됩니다. 이미 실행 중인 다른 앱은 다음 실행부터 새 테마를 씁니다."
                                                                   : "세션 밖에서 실행 중: 창 장식·배경은 다음 로그인부터 적용됩니다." }
                MOrnamentDivider { width: parent.width; height: 20 }

                MLabel { text: "배경"; font.pixelSize: Theme.fontSizeTitle; font.bold: true }
                MCheckBox { id: useTheme; text: "테마 기본 배경 사용"; checked: ThemeManager.useThemeWallpaper
                            onToggled: (c) => { if (ThemeManager.useThemeWallpaper !== c) ThemeManager.useThemeWallpaper = c } }
                Row { spacing: Theme.padding; width: parent.width
                    MTextField { id: wallField; width: parent.width - applyWall.width - Theme.padding; placeholder: "사용자 배경 이미지 경로 (PNG/JPG)"
                                 text: win.wallpaperDraft; enabled: !useTheme.checked; onAccepted: applyWall.clicked() }
                    MButton { id: applyWall; text: "적용"; enabled: !useTheme.checked && wallField.text.length > 0
                              onClicked: ThemeManager.userWallpaper = wallField.text }
                }
                MLabel { text: "현재 배경: " + ThemeManager.effectiveWallpaper; muted: true; font.pixelSize: Theme.fontSizeSmall; width: parent.width; elide: Text.ElideMiddle }
                MLabel { text: "테마를 바꿔도 사용자 지정 배경은 유지됩니다. 키보드·패널·소리 등 다른 설정은 바뀌지 않습니다."; muted: true; font.pixelSize: Theme.fontSizeSmall; wrap: true; width: parent.width }
            }
        }
    }
    MOrnamentFrame { anchors.fill: parent; active: win.active; z: 20 }
    Connections { target: ThemeManager; function onWallpaperChanged() { win.wallpaperDraft = ThemeManager.userWallpaper } }
    onVisibleChanged: if (visible) list.forceActiveFocus()
}
