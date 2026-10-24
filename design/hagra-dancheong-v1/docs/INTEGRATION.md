# MIN-OS 통합 지도

## 확인한 구조

2026-10-24 GitHub에서 기본 브랜치 파일을 읽었다. 최상위 CMake는 C++17, Qt 6.4+를 요구한다. libs/minui는 QML 파일 목록과 디렉터리 설치 방식이며 shell은 별도 QML 리소스 구성이 있다. 아래는 확인한 구조에 대한 지침이며 실제 실행은 검증하지 않았다.

| 기존 경로 | 적용 |
|---|---|
| libs/minui/qml/MinUI/Theme.qml | 제공 Theme의 색·치수 병합. API 유지 |
| libs/minui/qml/MinUI/MButton.qml | 상태·기호·패딩·한글 폰트 확인 |
| MLabel.qml / MTextField.qml / MListRow.qml | 대비·IME·포커스·선택 연결 |
| libs/minui/qml/MinUI/qmldir | 새 부품 export 등록 |
| libs/minui/CMakeLists.txt | SOURCES와 설치 자산 포함 확인 |
| shell/qml/Panel.qml | 높이·exclusiveZone·여백·실행 이름·문양 띠 |
| shell/qml/Launcher.qml / PowerMenu.qml | 밝은 팝업과 초점·실행 동작 |
| shell/qml/TaskButton.qml | 선택/활성/포커스의 구분 |
| shell/qml/qml.qrc | qrc 경로로 편입 시 새 파일 포함 |
| session/labwc/themerc-override | 밝은 제목·경계·메뉴·OSD |
| session/labwc/rc.xml | 테마 활성화·폰트·창 제어 설정 확인 |
| session/wallpaper/ | 사전 렌더링 PNG와 생성 원본 관리 |
| session/bin/minos-session | 배경 경로 변경 시 실행 연결만 수정 |
| files/ | 아직 M3 예정이면 디자인 예제로 한정 |
| tests/shell/ | 기존 픽셀 검사가 옛 색을 가정하는지 확인 |

## 매우 중요한 구현 경계

Qt/QML Theme를 바꾸면 앱 내부가 바뀌지만, labwc가 그리는 모든 창 제목줄에 QML 장식이 자동 적용되지는 않는다. 제공 themerc는 저장소에서 이미 사용하던 키에 맞춰 색·간격을 제안한다. 실제 labwc 버전에서 해석되는지는 실행 확인이 필요하다.

첫 적용은 다음으로 나눈다.

1. labwc SSD: 청자빛 밝은 제목, 짙은 글자, 명확한 활성 경계.
2. 하그라가 직접 그리는 앱/셸: 연화 띠와 모서리, 아이콘, 패널 장식을 완전 적용.
3. 앱이 CSD를 선택할 경우: QML 제목줄을 앱이 직접 그리며 move/resize/maximize/close를 실제 Window 동작에 연결. 이중 제목줄과 이중 프레임을 제거하고 클리핑·리사이즈·터치·키보드를 검증.
4. GTK/외부 앱: 강제 동일 외형을 약속하지 않고 범위를 기록. 콘텐츠 테마는 별도 정책.

단청 무늬의 전역 SSD가 필수라면 지원되는 테마 형식과 버전부터 조사한다. 비표준 설정 키 추가, 컴포지터 교체, 입력을 가로채는 오버레이는 이번 통합의 해결책으로 사용하지 않는다.

## 초안 코드 사용법

qml/Theme.qml은 기존 프로퍼티를 모두 포함한다. 추가 토큰이 있으며 기존 치수를 변경하므로 전체 레이아웃 회귀를 확인해야 한다. qmldir는 이 패키지의 로컬 갤러리용이며 저장소의 기존 qmldir를 덮어쓰는 파일이 아니다.

MotifBand와 OrnamentFrame은 패키지의 ../assets 상대 경로를 사용한다. 저장소에 복사할 때 모듈 내 assets/ 배치 또는 qrc URL로 변경하고 설치·실행 상태에서 해석되는지 확인한다. 개발 폴더에서만 보이는 절대 경로를 넣지 않는다.

Gallery는 자산과 장식 오버레이를 점검하는 창이다. 일반 Button/TextField가 기본 Qt 스킨인 것은 의도된 미완성 영역이며 최종 시안으로 보고하면 안 된다.

## SVG와 배경

작은 SVG는 path·rect·circle만으로 작성했고 외부 폰트·필터를 사용하지 않는다. wallpaper.svg는 SVG pattern을 사용하므로 Qt 렌더러 차이를 피하려면 함께 제공하는 wallpaper.png를 우선 사용한다. 작은 SVG도 대상 Qt SVG 런타임에서 확인한다. 매 프레임 Canvas로 다시 그리지 않는다.

## 검증 순서

1. `python3 tools/validate.py` (이 패키지의 구조·대비 검사)
2. 대상 호스트의 Qt 6 도구로 qmllint·갤러리 실행. 경고를 무시하지 않음.
3. 저장소에서 `make shell`, `make test-shell`.
4. 실제 셸 캡처와 시각 비교. 기존 픽셀 검사는 새 토큰과 의미를 반영하되 삭제하여 통과시키지 않음.
5. 부팅·세션·이미지 의존성 변경 시 기존 QEMU 검증. ARM64와 실기기 결과는 별도로 기록.

날짜는 실제 로케일과 런타임 시계에서 읽는다. 검증 화면 고정 시각이 필요하면 명시적인 테스트 전용 주입 경로를 사용하고 기본 제품 동작으로 남기지 않는다.
