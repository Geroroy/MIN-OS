#!/usr/bin/env python3
"""영어 번역 사전 → .ts 채우기. 원문(한국어) 이 바뀌면 lupdate 뒤 이 스크립트를 다시 돌린다.
사용: python3 tools/i18n/en.py   (shell/i18n/hagra-shell_en.ts, settings/i18n/hagra-settings_en.ts 갱신)"""
import os, sys
import xml.etree.ElementTree as ET
REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
EN = {
"모양 설정 — ": "Appearance — ", "테마": "Themes",
"선택하면 바로 저장되고 셸·배경·창 장식에 적용됩니다. 재로그인 후에도 유지됩니다.": "Selecting a theme saves it immediately and applies it to the shell, wallpaper and window decorations. It persists across logins.",
"기본": "Default", "✓ 현재": "✓ Current", "선택": "Choose", "기본 테마로": "Reset to default theme",
"창 장식(labwc)은 재구성 명령으로 즉시 갱신됩니다. 이미 실행 중인 다른 앱은 다음 실행부터 새 테마를 씁니다.": "Window decorations (labwc) are reloaded immediately. Other applications already running pick up the new theme on their next start.",
"세션 밖에서 실행 중: 창 장식·배경은 다음 로그인부터 적용됩니다.": "Running outside the session: window decorations and wallpaper apply at the next login.",
"배경": "Wallpaper", "테마 기본 배경 사용": "Use the theme's wallpaper", "사용자 배경 이미지 경로 (PNG/JPG)": "Custom wallpaper path (PNG/JPG)", "적용": "Apply", "현재 배경: ": "Current wallpaper: ",
"테마를 바꿔도 사용자 지정 배경은 유지됩니다. 키보드·패널·소리 등 다른 설정은 바뀌지 않습니다.": "A custom wallpaper is kept when you change themes. Keyboard, panel and sound settings are not affected.",
"앱": "Apps", "즐겨찾기": "Favorites", "시스템": "System",
"즐겨찾기가 비어 있습니다 — 앱 목록에서 오른쪽 클릭 → 즐겨찾기에 추가": "No favorites yet — right-click an app in the Apps tab → Add to favorites",
"최근 실행": "Recently used", "최근 실행한 앱이 없습니다": "No recently used apps",
"앱 검색 — 이름·설명·초성(ㅌㅁ)": "Search apps — name, description, Hangul initials", "응용 프로그램 검색": "Search applications", "실행 메뉴 구역": "Launcher sections",
"설치된 응용 프로그램이 없습니다": "No applications are installed", "' 과 일치하는 앱이 없습니다": "' matches no apps",
"applications/ 디렉터리에 .desktop 항목이 없습니다. 앱을 설치하면 여기에 나타납니다.": "No .desktop entries were found in the applications/ directories. Installed apps will appear here.",
"다른 검색어를 써 보세요. 영문 이름이나 초성(예: ㅌㅁ)으로도 찾을 수 있습니다.": "Try another search term. English names and Hangul initial consonants (e.g. ㅌㅁ) also match.",
"설정": "Settings", "모든 설정 (hagra-settings)": "All settings (hagra-settings)", "모양과 테마": "Appearance & Themes", "테마 · 포인트 색 · 글자 크기 · 커서": "Themes · accent color · text size · cursor",
"배경 바꾸기": "Change Wallpaper", "바탕 화면 배경 이미지": "Desktop background image", "디스플레이 설정": "Display Settings", "해상도 · 배율 · 화면 배치": "Resolution · scale · arrangement",
"터미널": "Terminal", "시스템 정보": "System Information", "하그라 버전 · 하드웨어 · 로그": "HAGRA version · hardware · logs", "전원": "Power", "종료 · 다시 시작 · 로그아웃": "Shut down · restart · log out",
"설정 열기": "Open Settings", "설정 — 모양과 테마, 디스플레이, 소리, 입력, 정보": "Settings — appearance & themes, display, sound, input, about", "개": "", "앱 ": "Apps: ", "전원 메뉴": "Power menu",
"실행": "Launch", "즐겨찾기에서 제거": "Remove from favorites", "즐겨찾기에 추가": "Add to favorites", "실행 메뉴 (": "Launcher (",
"yyyy년 M월 d일 (ddd) AP h:mm:ss": "ddd, MMM d yyyy h:mm:ss AP", "M월 d일 (ddd) AP h:mm": "ddd, MMM d h:mm AP",
"시스템 종료": "Shut down", "다시 시작": "Restart", "로그아웃": "Log out", "취소": "Cancel", "창 닫기": "Close window",
" 정보": " About", " · 기반 ": " · based on ", " · 라이브 매체 (설정이 재부팅 후 남지 않음)": " · live medium (settings do not survive a reboot)", "시간 ": "h ", "분": "min",
"운영체제": "Operating system", "커널": "Kernel", "호스트 이름": "Host name", " · 사용자 ": " · user ", "프로세서": "Processor", "메모리": "Memory", " (사용 가능 ": " (available ",
"디스크 (/)": "Disk (/)", " (남음 ": " (free ", "가동 시간": "Uptime", "컴포지터": "Compositor", "세션": "Session", " · 렌더링 ": " · rendering ", "화면": "Screens", " · 포인트 ": " · accent ",
"빌드": "Build", "개발 호스트 빌드": "development host build",
"한국의 미감과 생활에 대한 이해를 바탕으로 만드는 데스크톱 운영체제": "A desktop operating system built on Korean aesthetics and everyday life",
"진단": "Diagnostics", "세션 로그": "Session log", "셸 로그": "Shell log", "테마 설정 파일": "Theme config file", "새로 고침": "Refresh",
"저장소: github.com/Geroroy/MIN-OS · 라이선스 GPL-3.0-or-later. 문제 보고 시 위 로그와 '정보' 항목을 함께 보내 주세요.": "Repository: github.com/Geroroy/MIN-OS · License GPL-3.0-or-later. When reporting a problem, include the logs above and this About page.",
"접근성": "Accessibility", "하그라 셸·설정·HagraUI 앱에 즉시 적용됩니다. 외부 앱은 각자의 설정을 따릅니다.": "Applied immediately to the HAGRA shell, Settings and HagraUI apps. Third-party apps follow their own settings.",
"보기": "Vision", "글자 크기": "Text size", "기본 15px 기준 배율. 현재 ": "Scale relative to the default 15px. Currently ", "포커스 표시 강조": "Stronger focus indicator",
"키보드 포커스 링과 선택 막대를 더 굵게 (2px → 3px).": "Thicker keyboard focus ring and selection bar (2px → 3px).", "켜짐": "On", "꺼짐": "Off", "움직임 줄이기": "Reduce motion",
"하그라는 전환 애니메이션을 쓰지 않습니다 (motionDuration 0). 별도 설정이 필요 없습니다.": "HAGRA uses no transition animations (motionDuration 0), so no extra setting is needed.", "항상 최소": "Always minimal",
"커서 크기": "Cursor size", "다음 로그인부터 적용됩니다.": "Applies at the next login.", "미리보기": "Preview",
"한글 가나다라 · Latin AaBbCc 0123 — 제목 크기": "한글 가나다라 · Latin AaBbCc 0123 — title size", "본문: 다람쥐 헌 쳇바퀴에 타고파. The quick brown fox jumps over the lazy dog.": "Body: 다람쥐 헌 쳇바퀴에 타고파. The quick brown fox jumps over the lazy dog.",
"버튼": "Button", "입력란": "Text field", "확인": "Check", "지원 범위": "What is supported",
"키보드: 모든 하그라 UI 는 Tab/Shift+Tab, 방향키, Space/Enter, Esc 로 조작할 수 있고 포커스 링이 보입니다. 화면 읽기: HagraUI 부품에 접근성 역할·이름이 있으나 이 이미지에는 AT-SPI 화면 읽기 프로그램(orca)이 포함되어 있지 않습니다. 고정 키·느린 키: labwc 는 아직 지원하지 않습니다.": "Keyboard: every HAGRA UI can be operated with Tab/Shift+Tab, arrow keys, Space/Enter and Esc, and the focus ring is visible. Screen reading: HagraUI components expose accessibility roles and names, but this image does not ship an AT-SPI screen reader (orca). Sticky/slow keys: not yet supported by labwc.",
"글자 크기와 포커스 강조는 ": "Text size and focus emphasis are stored in ", " 에 저장되며 테마 관리자가 감시해 실행 중인 하그라 앱에 바로 반영합니다.": ", which the theme manager watches so running HAGRA apps update immediately.",
"선택하면 바로 저장되고 셸·창 장식·배경에 적용됩니다. 재로그인 후에도 유지됩니다.": "Selecting a theme saves it immediately and applies it to the shell, window decorations and wallpaper. It persists across logins.",
"밝기": "Brightness", "같은 계열의 밝은/어두운 테마로 바꿉니다. 해당 밝기의 테마가 없으면 비활성.": "Switches to the light or dark theme of the same family. Disabled when no theme of that brightness exists.", "밝게": "Light", "어둡게": "Dark",
"포인트 색": "Accent color", "테마가 정의한 대비 검증된 변형만 제공합니다. 강조·포커스 링·선택 표시에 쓰입니다.": "Only contrast-verified variants defined by the theme are offered. Used for emphasis, focus rings and selection markers.",
"테마 기본": "Theme default", " (선택됨)": " (selected)", "기본 테마로 되돌리기": "Restore the default theme", "기본 테마(": "Returns to the default theme (", ")와 테마 기본 포인트 색으로 돌아갑니다. 사용자 배경은 유지됩니다.": ") and its default accent color. A custom wallpaper is kept.",
"커서": "Cursor", "커서 테마": "Cursor theme", "설치된 커서 테마(/usr/share/icons/*/cursors). 다음 로그인부터 적용됩니다.": "Installed cursor themes (/usr/share/icons/*/cursors). Applies at the next login.",
"24(기본) · 32 · 48. HiDPI 화면에서는 큰 값을 권합니다. 다음 로그인부터 적용됩니다.": "24 (default) · 32 · 48. Larger sizes are recommended on HiDPI screens. Applies at the next login.",
"접근성 페이지에서 바꿉니다 (현재 배율 ": "Changed on the Accessibility page (current scale ", "접근성으로": "Go to Accessibility",
"Wayland 세션 밖에서 실행 중입니다 (WAYLAND_DISPLAY 없음).": "Running outside a Wayland session (WAYLAND_DISPLAY is not set).",
"wlr-randr 가 설치되어 있지 않습니다. 디스플레이 설정은 wlr-output-management 클라이언트가 필요합니다.": "wlr-randr is not installed. Display settings need a wlr-output-management client.",
"wlr-randr 실행 실패: ": "wlr-randr failed: ", "컴포지터가 출력 정보를 주지 않았습니다.": "The compositor returned no output information.", "wlr-randr 종료 코드 %1": "wlr-randr exit code %1",
"디스플레이": "Display", "wlr-output-management 로 즉시 적용됩니다. 적용한 값은 저장되어 로그인할 때 복원됩니다.": "Applied immediately through wlr-output-management. Applied values are saved and restored at login.",
"디스플레이 설정을 쓸 수 없습니다": "Display settings are unavailable", "적용 실패": "Apply failed", "출력 ": "Output ", " · 위치 ": " · position ", " · 저장된 설정 있음": " · has saved settings",
"켜기": "Enabled", "출력이 하나뿐이면 끌 수 없습니다": "The only output cannot be turned off", "해상도 · 주사율": "Resolution · refresh rate", " (권장)": " (preferred)", "배율": "Scale",
"HiDPI 화면은 1.5 또는 2. 논리 해상도 = 물리 해상도 ÷ 배율.": "Use 1.5 or 2 on HiDPI screens. Logical resolution = physical resolution ÷ scale.", "회전": "Rotation", "없음": "None",
"좌우 반전": "Flipped", "반전 90°": "Flipped 90°", "반전 180°": "Flipped 180°", "반전 270°": "Flipped 270°", "저장된 설정 지우기": "Forget saved settings",
"다음 로그인부터 컴포지터 기본값(권장 모드, 배율 1)을 씁니다. 현재 화면은 바뀌지 않습니다.": "From the next login the compositor defaults (preferred mode, scale 1) are used. The current screen is not changed.",
"첫 출력 오른쪽에": "Right of first output", "첫 출력 왼쪽에": "Left of first output", "다시 읽기": "Reload",
"배율을 바꾸면 하그라 셸·설정 창은 컴포지터 출력 배율을 따라 즉시 다시 그려집니다. 다중 모니터 배치는 '첫 출력 왼쪽/오른쪽에' 버튼으로 가로로 나란히 놓습니다.": "After a scale change the HAGRA shell and Settings redraw immediately at the new output scale. Arrange multiple monitors side by side with the 'Left/Right of first output' buttons.",
"# hagra-settings: 키보드 배치 (input.conf)": "# hagra-settings: keyboard layout (input.conf)", "키보드와 마우스": "Keyboard & Mouse",
"포인터·반복 설정은 즉시, 키보드 배치는 labwc 가 환경 파일을 다시 읽을 때(재구성 또는 다음 로그인) 적용됩니다.": "Pointer and repeat settings apply immediately; the keyboard layout applies when labwc re-reads its environment file (reconfigure or next login).",
"세션 밖에서 실행 중: 다음 로그인부터 적용됩니다.": "Running outside the session: applies at the next login.", "오른쪽 Ctrl": "Right Ctrl", "키보드": "Keyboard", "기본 배치": "Primary layout", "첫 배치. 현재: ": "First layout. Currently: ",
"두 번째 배치 (전환용)": "Second layout (for switching)", "한국어 + 영어처럼 두 배치를 번갈아 쓰려면 지정합니다.": "Set this to alternate between two layouts, e.g. Korean and English.", "배치 전환 키": "Layout switch key",
"한/영 키가 없는 키보드용. 한글 입력기(fcitx5)를 쓰면 입력기의 전환 키를 씁니다.": "For keyboards without a Han/Eng key. With the Korean input method (fcitx5) the input method's own switch key is used.",
"키 반복 속도": "Key repeat rate", "초당 반복 횟수": "Repeats per second", "반복 시작 지연": "Repeat delay", "키를 누르고 반복이 시작되기까지 (ms)": "Time before a held key starts repeating (ms)",
"마우스와 터치패드": "Mouse & touchpad", "포인터 속도": "Pointer speed", "탭으로 클릭 (터치패드)": "Tap to click (touchpad)", "사용": "On", "사용 안 함": "Off", "자연스러운 스크롤": "Natural scrolling",
"손가락 방향으로 내용이 움직입니다.": "Content follows the direction of your fingers.", "왼손잡이 (버튼 바꿈)": "Left-handed (swap buttons)", "가운데 버튼 에뮬레이션": "Middle-button emulation",
"왼쪽+오른쪽 동시 클릭 = 가운데 클릭": "Left + right click together = middle click", "모두 기본값으로": "Reset all to defaults", "세션에 다시 적용": "Re-apply to session", "저장 위치: ": "Stored in: ",
". 사용자가 ~/.config/hagra/labwc/rc.xml 또는 environment 를 직접 두면 이 설정은 그 파일을 덮지 않습니다.": ". If you keep your own ~/.config/hagra/labwc/rc.xml or environment, these settings do not overwrite it.",
"기본 (C.UTF-8)": "Default (C.UTF-8)", "언어와 지역": "Language & Region", "현재 세션: ": "Current session: ", " · 시간대 ": " · time zone ", "표시 언어": "Display language", "언어 (LANG)": "Language (LANG)",
"하그라 셸·설정과 앱의 표시 언어. 다음 로그인부터 적용됩니다.": "Display language of the HAGRA shell, Settings and apps. Applies at the next login.", " 저장됨: ": " Saved: ", "시간·숫자 형식 (LC_TIME)": "Time & number format (LC_TIME)",
"비우면 언어와 같은 로케일을 씁니다.": "When empty, the language locale is used.", "언어와 같음": "Same as language",
"설치된 UTF-8 로케일이 거의 없습니다. 이미지에 locales 패키지와 ko_KR.UTF-8/en_US.UTF-8 생성이 필요합니다 (image/config/hooks/10-base-config.sh).": "Almost no UTF-8 locales are installed. The image needs the locales package with ko_KR.UTF-8/en_US.UTF-8 generated (image/config/hooks/10-base-config.sh).",
"시간대": "Time zone", "시간대 변경은 관리자 권한(timedatectl set-timezone)이 필요해 이 앱에서는 바꾸지 않습니다.": "Changing the time zone needs administrator rights (timedatectl set-timezone) and is not done from this app.",
"한글 입력기": "Korean input method", "입력기가 설치되어 있지 않습니다": "No input method is installed",
"한글 입력에는 fcitx5 + fcitx5-hangul 이 필요합니다. 설치 후 세션이 자동으로 시작합니다 (session/labwc/autostart). 하그라 이미지 패키지 목록: image/config/packages.desktop.": "Korean input needs fcitx5 + fcitx5-hangul. Once installed the session starts it automatically (session/labwc/autostart). HAGRA image package list: image/config/packages.desktop.",
"실행 중": "running", "실행되지 않음": "not running", " · 한글 엔진 있음": " · Hangul engine present", " · 한글 엔진(fcitx5-hangul) 없음": " · Hangul engine (fcitx5-hangul) missing",
"입력 모듈 환경(QT_IM_MODULE=fcitx) 이 설정되어 있습니다. 한/영 전환: Shift+Space (fcitx5 기본).": "The input module environment (QT_IM_MODULE=fcitx) is set. Korean/English switch: Shift+Space (fcitx5 default).",
"QT_IM_MODULE/XMODIFIERS 가 fcitx 로 설정되어 있지 않아 이 앱은 입력기를 쓰지 않습니다. 세션 환경 파일을 확인하세요.": "QT_IM_MODULE/XMODIFIERS are not set to fcitx, so this app is not using the input method. Check the session environment file.",
"입력기 다시 시작": "Restart input method", "입력기 시작": "Start input method", "입력기 설정 열기": "Open input method settings", "설정 — ": "Settings — ",
"테마 · 밝게/어둡게 · 포인트 색 · 커서": "Themes · light/dark · accent color · cursor", "테마 theme 밝기 dark light 포인트 accent 커서 cursor": "theme appearance dark light accent cursor",
"바탕 화면 이미지": "Desktop image", "배경 wallpaper 이미지": "wallpaper background image", "해상도 · 배율 · 배치": "Resolution · scale · arrangement", "해상도 resolution 배율 scale hidpi 모니터 monitor": "resolution scale hidpi monitor",
"소리": "Sound", "볼륨 · 출력 장치": "Volume · output device", "볼륨 volume 음소거 mute 오디오 audio": "volume mute audio", "배치 · 한/영 전환 · 반복 · 포인터": "Layout · Korean/English switch · repeat · pointer",
"키보드 keyboard 마우스 mouse 터치패드 touchpad 배치 layout 한영": "keyboard mouse touchpad layout", "표시 언어 · 시간 형식 · 한글 입력기": "Display language · time format · Korean input",
"언어 language 로케일 locale 시간 time 입력기 ime fcitx 한글": "language locale time ime fcitx hangul", "네트워크": "Network", "연결 상태 · Wi-Fi": "Connection status · Wi-Fi", "네트워크 network wifi 와이파이 유선 ethernet ip": "network wifi ethernet ip",
"알림": "Notifications", "방해 금지 · 알림 서버": "Do not disturb · notification server", "알림 notification 방해 dnd": "notification dnd", "배터리 · 절전 · 종료": "Battery · suspend · shut down", "전원 power 배터리 battery 절전 suspend 종료": "power battery suspend shutdown",
"글자 크기 · 포커스 표시 · 커서 크기": "Text size · focus indicator · cursor size", "접근성 accessibility 글자 크기 font size 포커스 focus 대비 contrast": "accessibility font size focus contrast", "정보": "About", "정보 about 버전 version 로그 log 하드웨어": "about version log hardware",
"설정 검색": "Search settings", "일치하는 설정이 없습니다": "No matching settings", "무선": "Wireless", "유선": "Wired", "가상": "Virtual", "기타": "Other",
"nmcli 가 NetworkManager 에 연결하지 못했습니다 (서비스 미실행?). ": "nmcli could not reach NetworkManager (service not running?). ",
"NetworkManager 가 설치되어 있지 않아 Wi-Fi 검색·연결 설정은 제공하지 않습니다. 아래는 커널이 보고하는 인터페이스 상태입니다 (읽기 전용). 설치: network-manager.": "NetworkManager is not installed, so Wi-Fi scanning and connection settings are not offered. Below is the interface state reported by the kernel (read-only). Install: network-manager.",
"연결됨 — 기본 경로: ": "Connected — default route: ", "기본 경로가 없습니다 (오프라인)": "No default route (offline)", "네트워크 관리자 없음": "No network manager", "인터페이스": "Interfaces", "  (기본)": "  (default)",
"네트워크 인터페이스가 없습니다": "No network interfaces", "검색": "Scan", "개 네트워크": " networks", "신호 ": "Signal ", "열림": "open", " · 연결됨": " · connected", "Wi-Fi 이름": "Wi-Fi name",
"비밀번호 (열린 망이면 비움)": "Password (leave empty for open networks)", "Wi-Fi 비밀번호": "Wi-Fi password", "연결": "Connect", "알림 서버: ": "Notification server: ",
"세션에 알림 서버(org.freedesktop.Notifications)가 없습니다": "No notification server (org.freedesktop.Notifications) in this session", "세션 D-Bus 없음": "No session D-Bus",
"알림은 세션 버스가 필요합니다. hagra-session 은 dbus-run-session 또는 systemd --user 버스를 사용합니다.": "Notifications need a session bus. hagra-session uses dbus-run-session or the systemd --user bus.",
"알림 서버가 실행 중이 아닙니다": "The notification server is not running",
"하그라 셸이 알림 서버를 제공합니다. 셸이 실행 중인지 확인하세요 (hagra-shell). 설정은 저장되며 서버가 뜨면 반영됩니다.": "The HAGRA shell provides the notification server. Check that the shell is running (hagra-shell). Settings are saved and take effect once the server is up.",
"방해 금지": "Do not disturb", "켜면 팝업을 띄우지 않고 알림 센터에만 쌓습니다 (긴급 알림 제외).": "When on, popups are suppressed and notifications only collect in the notification center (except urgent ones).",
"팝업 표시 시간": "Popup duration", "초": " s", "팝업 위치": "Popup position", "오른쪽 위": "Top right", "왼쪽 위": "Top left", "오른쪽 아래": "Bottom right",
"알림 소리는 아직 제공하지 않습니다 (소리 서버·효과음 파일 미포함).": "Notification sounds are not provided yet (no sound server or sound files shipped).", "테스트 알림 보내기": "Send test notification",
"하그라 알림 테스트": "HAGRA notification test", "이 알림이 보이면 서버가 정상입니다.": "If you can see this, the server works.", "다시 확인": "Check again",
"유휴 시 화면 끄기·자동 절전은 swayidle 이 필요합니다. 이 이미지에는 포함되어 있지 않아 설정을 제공하지 않습니다 (설치: swayidle).": "Idle screen-off and automatic suspend need swayidle. It is not included in this image, so no settings are offered (install: swayidle).",
"logind 에 연결할 수 없습니다": "Cannot connect to logind", "배터리 사용 중": "On battery", "전원 연결됨": "Plugged in", "배터리가 없는 장치입니다": "This device has no battery", "배터리": "Battery", " · 수명 ": " · health ",
"지금 실행": "Act now", "종료·절전은 systemd-logind D-Bus 가 필요합니다.": "Shutdown and suspend need the systemd-logind D-Bus service.", "절전": "Suspend", "이 장치는 절전을 지원하지 않습니다": "This device does not support suspend",
"최대 절전": "Hibernate", "스왑이 없어 최대 절전을 지원하지 않습니다": "Hibernation is unavailable without swap", "유휴 동작": "Idle behaviour", "자동 화면 끄기·절전 미지원": "Automatic screen-off/suspend unsupported",
"swayidle 이 설치되어 있습니다. 유휴 시간 설정 UI는 아직 없습니다 — ~/.config/hagra/labwc/autostart 에서 swayidle 을 직접 실행하세요.": "swayidle is installed. There is no idle-timeout UI yet — run swayidle from ~/.config/hagra/labwc/autostart.",
"덮개 닫힘·전원 단추 동작은 /etc/systemd/logind.conf 의 HandleLidSwitch/HandlePowerKey 로 정해지며 관리자 권한이 필요합니다. 하그라 기본: 전원 단추 = 종료 메뉴 표시가 아니라 logind 기본(poweroff).": "Lid-close and power-button actions are set by HandleLidSwitch/HandlePowerKey in /etc/systemd/logind.conf and need administrator rights. HAGRA default: the power button follows the logind default (poweroff) rather than showing a menu.",
"wpctl 는 있지만 PipeWire 세션에 연결하지 못했습니다 (pipewire/wireplumber 사용자 서비스가 실행 중인지 확인). ": "wpctl is present but could not connect to a PipeWire session (check that the pipewire/wireplumber user services are running). ",
"pactl 가 오디오 서버에 연결하지 못했습니다. ": "pactl could not connect to the audio server. ",
"오디오 서버 제어 도구가 없습니다. 이 이미지에는 PipeWire(wireplumber) 가 포함되어 있지 않아 볼륨·장치 설정을 제공할 수 없습니다. 설치: pipewire pipewire-pulse wireplumber (명령 wpctl).": "No audio server control tool is available. This image does not include PipeWire (wireplumber), so volume and device settings cannot be offered. Install: pipewire pipewire-pulse wireplumber (command wpctl).",
"도구: ": "Tool: ", "소리 설정을 쓸 수 없습니다": "Sound settings are unavailable", "출력 볼륨": "Output volume", "100% 를 넘기면 소리가 왜곡될 수 있습니다.": "Above 100% the sound may distort.", "음소거": "Mute", "마이크": "Microphone",
"기본 입력 장치 (볼륨 ": "Default input device (volume ", "출력 장치": "Output devices", "장치 목록은 pactl (pipewire-pulse) 이 있을 때 표시됩니다.": "The device list is shown when pactl (pipewire-pulse) is available.",
"하그라": "HAGRA", " (개발 호스트)": " (development host)", "알 수 없음": "unknown", "labwc (버전 확인 불가)": "labwc (version unavailable)", "소프트웨어 (": "software (", "(파일 없음: %1)": "(no such file: %1)",
" (현재)": " (current)", " (기본)": " (default)", "미리보기 없음": "No preview", "어두움": "Dark", "밝음": "Light", "현재: ": "Current: ",
"테마 기본 배경 사용 (테마를 바꾸면 배경도 함께 바뀜)": "Use the theme's wallpaper (changes with the theme)", "이미지 고르기": "Pick an image", " (현재 배경)": " (current wallpaper)", "내 이미지": "My image",
"배경 이미지를 찾지 못했습니다. 아래 경로에 PNG/JPG 를 넣거나 경로를 직접 지정하세요.": "No wallpaper images were found. Put PNG/JPG files in one of the folders below or enter a path directly.", "직접 지정": "Enter a path",
"이미지 파일 경로 (PNG/JPG/WebP)": "Image file path (PNG/JPG/WebP)", "배경 이미지 경로": "Wallpaper image path", "이미지 파일을 읽을 수 없습니다: ": "Cannot read image file: ", "검색 폴더: ": "Search folders: ",
"내 이미지는 ": "Your own images placed in ", "\n내 이미지는 ": "\nYour own images placed in ", " 에 넣으면 목록에 나타납니다. 테마를 바꿔도 사용자 지정 배경은 유지됩니다.": " appear in this list. A custom wallpaper is kept when you change themes.", "목록 새로 고침": "Refresh list",
"/배경": "/Wallpapers", " 테마 배경": " theme wallpaper",
}

def fill(ts):
    tree = ET.parse(ts)
    root = tree.getroot()
    root.set("language", "en_US"); root.set("sourcelanguage", "ko_KR")
    n = missing = 0
    for m in root.iter("message"):
        src = m.find("source").text or ""
        t = m.find("translation")
        if t is None:
            t = ET.SubElement(m, "translation")
        if src in EN:
            t.text = EN[src]
            if "type" in t.attrib: del t.attrib["type"]
            n += 1
        else:
            t.set("type", "unfinished"); missing += 1
            print("  missing:", repr(src))
    tree.write(ts, encoding="utf-8", xml_declaration=True)
    print(f"{ts}: {n} translated, {missing} missing")
    return missing

if __name__ == "__main__":
    miss = 0
    for ts in ("shell/i18n/hagra-shell_en.ts", "settings/i18n/hagra-settings_en.ts"):
        miss += fill(os.path.join(REPO, ts))
    sys.exit(1 if miss else 0)
