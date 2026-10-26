// 설정 → 언어와 지역: 표시 언어(LANG)·시간 형식 → locale.conf (다음 로그인), 시간대 표시, 한글 입력기 상태.
import QtQuick
import HagraUI 1.0
import HagraSettings 1.0
import ".."

SPage {
    id: page
    title: qsTr("언어와 지역")
    subtitle: qsTr("현재 세션: ") + LocaleSettings.currentLang + qsTr(" · 시간대 ") + LocaleSettings.timezone
    readonly property var codes: LocaleSettings.locales.map((l) => l.code)

    SSection { title: qsTr("표시 언어"); divider: false }
    SRow { label: qsTr("언어 (LANG)"); description: qsTr("하그라 셸·설정과 앱의 표시 언어. 다음 로그인부터 적용됩니다.") + (LocaleSettings.savedLang.length ? qsTr(" 저장됨: ") + LocaleSettings.savedLang : "")
        MComboBox { model: LocaleSettings.locales.map((l) => l.name + " — " + l.code); width: 320
                    currentIndex: Math.max(0, codes.indexOf(LocaleSettings.savedLang.length ? LocaleSettings.savedLang : LocaleSettings.currentLang))
                    onActivated: (i) => LocaleSettings.setLang(codes[i]) } }
    SRow { label: qsTr("시간·숫자 형식 (LC_TIME)"); description: qsTr("비우면 언어와 같은 로케일을 씁니다.")
        MComboBox { property var c2: [""].concat(codes); model: [qsTr("언어와 같음")].concat(LocaleSettings.locales.map((l) => l.name)); width: 320
                    currentIndex: Math.max(0, c2.indexOf(LocaleSettings.savedTime))
                    onActivated: (i) => LocaleSettings.setTimeFormatLocale(c2[i]) } }
    SNote { visible: LocaleSettings.locales.length <= 1; kind: "warn"; text: qsTr("설치된 UTF-8 로케일이 거의 없습니다. 이미지에 locales 패키지와 ko_KR.UTF-8/en_US.UTF-8 생성이 필요합니다 (image/config/hooks/10-base-config.sh).") }
    SRow { label: qsTr("시간대"); description: qsTr("시간대 변경은 관리자 권한(timedatectl set-timezone)이 필요해 이 앱에서는 바꾸지 않습니다.")
        MLabel { text: LocaleSettings.timezone; font.family: Theme.monoFamily } }

    SSection { title: qsTr("한글 입력기") }
    SNote { visible: !LocaleSettings.ime.installed; kind: "unavailable"; title: qsTr("입력기가 설치되어 있지 않습니다")
            text: qsTr("한글 입력에는 fcitx5 + fcitx5-hangul 이 필요합니다. 설치 후 세션이 자동으로 시작합니다 (session/labwc/autostart). 하그라 이미지 패키지 목록: image/config/packages.desktop.") }
    SNote { visible: LocaleSettings.ime.installed; kind: LocaleSettings.ime.running ? "info" : "warn"
            title: "fcitx5 " + (LocaleSettings.ime.running ? qsTr("실행 중") : qsTr("실행되지 않음")) + (LocaleSettings.ime.hangul ? qsTr(" · 한글 엔진 있음") : qsTr(" · 한글 엔진(fcitx5-hangul) 없음"))
            text: LocaleSettings.ime.envOk ? qsTr("입력 모듈 환경(QT_IM_MODULE=fcitx) 이 설정되어 있습니다. 한/영 전환: Shift+Space (fcitx5 기본).") : qsTr("QT_IM_MODULE/XMODIFIERS 가 fcitx 로 설정되어 있지 않아 이 앱은 입력기를 쓰지 않습니다. 세션 환경 파일을 확인하세요.") }
    Row { spacing: Theme.padding
        MButton { visible: LocaleSettings.ime.installed; text: LocaleSettings.ime.running ? qsTr("입력기 다시 시작") : qsTr("입력기 시작"); icon: "language"; onClicked: LocaleSettings.startIme() }
        MButton { visible: LocaleSettings.ime.installed && Proc.have("fcitx5-configtool"); text: qsTr("입력기 설정 열기"); onClicked: Proc.launch("fcitx5-configtool") }
        MButton { text: qsTr("다시 읽기"); icon: "refresh"; onClicked: LocaleSettings.refresh() }
    }
}
