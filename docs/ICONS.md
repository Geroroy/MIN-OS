# 하그라 아이콘 시스템

두 계층을 구분한다 (DESIGN_SPEC "장식과 조작 기호를 구분한다").

| 계층 | 위치 | 격자 | 획 | 색 | 예 |
|---|---|---|---|---|---|
| **장식·대상 아이콘** (완성 색) | 테마 팩 `assets/` (`design/hagra-dancheong-v*/assets`) | 48·72 | 면 + 윤곽 | 테마별 오방색 | lotus, lotus-band, corner-rosette, folder-*, document, settings, cloud/lattice/bojagi 타일 |
| **조작 기호** (단색) | `libs/hagraui/qml/HagraUI/assets/<name>.svg` (+ `<name>-light.svg`) | 24×24, 안쪽 여백 2.5 (실제 그림 19×19 안) | 1.8px, 둥근 끝·모서리 | 잉크 `#203F42` / 분백 `#F2EADB` | 아래 목록 |

## 조작 기호 목록 (24×24)

| 그룹 | 이름 |
|---|---|
| 탐색 | back, forward, up, home, search, menu, refresh, reset |
| 파일 | file, folder, document(장식), image, download, trash, drive, usb |
| 보기 | view-grid, view-list, window, display, workspace, apps |
| 상태 | check, error, info, star, lock, clock, calendar |
| 시스템 | power, terminal, settings(장식), keyboard, mouse, cursor, text-size, accessibility |
| 소리·연결 | speaker, speaker-muted, network, network-off, ethernet, bell, bell-off, battery, battery-charging |
| 언어·테마 | globe, language, sun, moon, palette |

규칙:
- **인식이 먼저, 장식은 나중**: 조작 기호는 한국적 문양을 넣지 않는다. 문양은 장식 계층(연화·결구·띠)에서만 쓴다.
- **광학 정렬**: 원형은 반지름 8.5, 사각은 3.5~20.5 범위, 작은 점은 `h.01` 경로 + 둥근 끝으로 찍는다.
- **어두운 면**: `MIcon { light: true }` 가 `-light` 변형을 찾는다. `Theme.lightIcons` 는 생성 시 모듈 자산을 스캔해 채워진다 (`gen_tokens.py`).
- **대체**: 자산이 없으면 `MIcon` 이 1px 테두리 + 머리글자 자리 표시자를 그린다. 앱 아이콘(`AppIcon`)은 아이콘 테마(hicolor 등)에서 찾고 없으면 머리글자 타일을 그린다.
- Qt 6.4 에는 SVG 재착색이 없어 색은 파일에 고정한다. 새 아이콘은 두 변형을 함께 추가한다.
