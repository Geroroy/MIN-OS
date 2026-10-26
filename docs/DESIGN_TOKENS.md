# 하그라 디자인 토큰 시스템 (Design System 2.0)

> 단일 원본: `design/tokens/hagra.tokens.json`(기본 테마 "연한 단청") + `design/themes/<id>/tokens.json`(추가 테마).
> 생성기 `design/tools/gen_tokens.py` 가 `libs/hagraui/qml/HagraUI/Theme.qml`, `session/labwc/themerc-override`, `session/foot/foot.ini` 를 만들고,
> `design/tools/build_themes.py` 가 테마 팩(`build/themes/<id>/`)을 조립한다. `make tokens-check` 가 드리프트와 대비(`contrast_check.py`)를 검사한다.

## 1. 원칙

| 원칙 | 적용 |
|---|---|
| 토큰과 로직 분리 | 앱 코드는 색·치수를 직접 쓰지 않고 `Theme.*` 만 참조한다. 테마 전환은 `Theme.applyTokens()` 하나로 끝난다. |
| 역할 토큰 우선 | `text/surface/accent/danger/selection` 등 의미별 토큰을 쓴다. `coral/celadon/blue/ochre/ivory` 는 장식 전용이다. |
| 어두운 면 | 패널·사이드바처럼 어두울 수 있는 면은 `panel/panelText/panelMuted`, `sidebar/sidebarText`, `focusRingOnDark` 를 쓴다. `Theme.isDark(c)` 로 판정한다. |
| 색 이외의 단서 | 선택 = 3px 막대 + 굵은 글씨, 포커스 = 2px 바깥 링, 오류 = `!` 배지. 색맹 사용자도 상태를 읽을 수 있다. |
| 최소 움직임 | `motionDuration` 0. 전환 애니메이션을 쓰지 않는다. (접근성 '움직임 줄이기' 가 별도 설정이 필요 없는 이유) |
| 대비 | `contrast_check.py` 가 모든 테마·포인트 색 변형에 대해 본문 4.5:1, UI 경계 3:1 이상을 강제한다 (WCAG 2.x). |

## 2. 토큰 그룹

### 2.1 색 (`color`)

| 토큰 | 역할 | 연한 단청 | 깊은 단청 | 밤 단청 |
|---|---|---|---|---|
| `bg` | 바탕(배경 밖, 사이드바 기본) | `#E3ECE6` | `#183C35` | `#0F2622` |
| `surface` | 창 본문 | `#FAF6EA` | `#F2EADB` | `#16302B` |
| `surfaceRaised` | 올린 면(호버·입력 비활성) | `#F0EBDD` | `#E4DAC6` | `#1F3D37` |
| `border` / `borderStrong` | 약한/강한 경계 | `#90A99E` / `#4F756D` | `#728D78` / `#28574A` | `#3E5E55` / `#7FB3A3` |
| `text` / `textMuted` / `textDisabled` | 글자 | `#203F42` / `#536963` / `#79867E` | `#20352E` / `#4D6055` / `#788178` | `#F2EADB` / `#C9D3C6` / `#8A9A92` |
| `accent` / `accentText` | 강조(기본 버튼 테두리, 선택 막대, 체크) | `#28717B` / `#FFFFFF` | `#28574A` / `#F2EADB` | `#7FB3A3` / `#0F2622` |
| `focusRing` / `focusRingOnDark` | 키보드 포커스 링 | `#28717B` / `#FAF6EA` | `#203C7A` / `#F2EADB` | `#EDC486` / `#EDC486` |
| `selection` / `selectionText` | 선택 배경·글자 | `#F8E7B8` / `#203F42` | `#BDD7C6` / `#20352E` | `#2E5A4E` / `#F2EADB` |
| `warning` / `danger` / `success` | 상태 | `#91631D` / `#A54042` / `#3E746D` | `#79541B` / `#A52E20` / `#2FA58F` | `#E4B860` / `#E8907A` / `#7FD1BB` |
| `panel` / `panelText` / `panelMuted` | 작업 표시줄 | `#FAF6EA` / `#203F42` / `#536963` | `#183C35` / `#F2EADB` / `#C9D3C6` | `#0F2622` / `#F2EADB` / `#C9D3C6` |
| `sidebar` / `sidebarText` | 설정·파일 사이드바 | `#E3ECE6` / `#203F42` | `#28574A` / `#F2EADB` | `#122B26` / `#F2EADB` |
| `titleActive` / `titleInactive` (+Text) | 창 제목줄 (labwc 와 공유) | `#D2E2D5` / `#E5EBE0` | `#28574A` / `#52695A` | `#1F3D37` / `#16302B` |
| 장식: `coral celadon blue ochre ivory patternInk redBrown` | 오방색 계열 장식 전용 | 산호·청자·군청·황토·분백 | v2 값 | 밝은 변형 |

### 2.2 창 장식 (`window`) — labwc themerc 와 공유

`activeBorder inactiveBorder activeTitleBg inactiveTitleBg activeTitleText inactiveTitleText buttonHoverBg inactiveButtonHoverBg borderWidth(2) titlePaddingX/Y cornerRadius(2) titleFontPt(12) titleJustify`.
labwc 0.7 이 지원하는 스칼라 키만 쓴다. 연화 제목 띠는 전역 장식으로 만들 수 없어 앱 내부 `MOrnamentBand` 로 구현한다 (`docs/UI_FOUNDATION.md` §2.2).

### 2.3 치수 (`size`, 논리 px @ 배율 1)

| 토큰 | 값 | 비고 |
|---|---|---|
| `unit` | 4 | 간격 격자 |
| `padding` / `paddingLarge` | 8 / 16 | |
| `controlHeight` / `rowHeight` | 36 / 40 | 모든 버튼·입력란은 36, 목록 행 40 (두 줄 행은 52) |
| `panelHeight` / `panelBandHeight` | 52 / 8 | 띠 8 + 경계 1 + 콘텐츠 43 |
| `titleBarHeight` | 40 | labwc 는 글꼴 높이 + 2×titlePaddingY 로 계산 |
| `borderWidth` / `focusRingWidth` / `selectionMarkerWidth` | 1 / 2 / 3 | 접근성 '포커스 강조' 켜면 +1 |
| `radius` | 2 | 각진 인상. 원형은 라디오·슬라이더 손잡이·포인트 색 견본만 |
| `iconSize` / `iconSizeLarge` / `folderIconSize` | 24 / 32 / 72 | |
| `ornamentBandHeight` / `ornamentFrameWidth` / `cornerSize` | 18 / 6 / 24 | |
| `scrollBarWidth` / `dialogMinWidth` / `tooltipMaxWidth` / `railWidth` | 12 / 360 / 360 / 72 | |

### 2.4 글꼴 (`font`)

`family`·`familyKo` = Noto Sans CJK KR (한글·라틴 메트릭 일치), `monoFamily` = DejaVu Sans Mono, `size` 15 / `sizeSmall` 13 / `sizeTitle` 16, `lineHeight` 1.4.
접근성 글자 배율(`~/.config/hagra/accessibility.conf` `[text] scale=1.0~1.6`)은 `ThemeManager::tokensFor()` 가 세 크기에 곱해 모든 HagraUI 앱에 즉시 반영한다.

### 2.5 터미널 (`terminal`) · 메뉴 (`menu`) · OSD (`osd`)

foot 팔레트(16색·선택·글꼴), labwc 메뉴·창 전환 OSD 색. 테마 팩마다 `foot/foot.ini` 가 생성되고 셸이 `foot -c <state>/foot.ini` 로 띄운다 (열려 있는 터미널은 바뀌지 않는다).

## 3. 테마 팩과 변형

```
/usr/share/hagra/themes/<id>/
  theme.json     id, displayName, description, default, appearance(light|dark), accents[], wallpaperFill, 경로들
  tokens.json    위 그룹 전체
  assets/*.svg   장식·폴더·문서 (완성 색)
  wallpaper.png  preview.png  labwc/themerc  foot/foot.ini
```

- **포인트 색 변형 (`accents`)**: 테마가 정의한 `{id, name, accent, accentText, focusRing}` 만 선택할 수 있다. 임의 색은 받지 않는다 — 대비 검증을 거친 조합만 제공한다는 원칙.
- **밝기 (`appearance`)**: `light` = 밝은 본문(연한·깊은 단청), `dark` = 어두운 본문(밤 단청). 설정 → 모양 → 밝기 버튼은 같은 계열의 다른 밝기 테마로 전환한다.
- 선택은 `~/.config/hagra/theme.conf` `[appearance] theme= accent= useThemeWallpaper= wallpaper=` 에 저장되고, `~/.local/state/hagra/theme/` 에 세션용 상태(themerc-override, wallpaper, foot.ini)가 생긴다.

## 4. 부품 상태 모델 (HagraUI)

모든 조작 부품은 8상태(기본·호버·눌림·선택·포커스·비활성·오류·진행 중)를 같은 규칙으로 그린다:

| 상태 | 시각 규칙 |
|---|---|
| 호버 | `surfaceRaised` (어두운 면에서는 전경 14% 반투명) |
| 눌림 | `selection` 배경 + 1px 아래 오프셋 |
| 선택/활성 | `selection` 배경 + 3px `accent` 막대 + 굵은 글씨 |
| 포커스 | 바깥 2px `focusRing`(어두운 면 `focusRingOnDark`) — 장식보다 앞(z 5) |
| 비활성 | 투명 배경, `textDisabled`, 아이콘 opacity 0.45 |
| 오류 | `danger` 테두리 + `!` 배지 (+ 아래 메시지) |
| 진행 중 | 하단 이동 막대 (`MBusyBar`) |

접근성: 모든 부품에 `Accessible.role/name` 과 press/toggle 동작이 있다 (`MButton MCheckBox MRadioButton MTextField MListRow MTabBar MSlider MProgressBar MLabel`).

## 5. 새 테마 만들기

1. `design/themes/<id>/theme.json` + `tokens.json` (저장소 스키마; `_meta.themeId` = `<id>`). 자산은 다른 팩을 상대 경로로 가리켜도 된다.
2. `python3 design/tools/contrast_check.py` 통과.
3. `make shell` (팩 조립) → `HAGRA_THEME=<id> tests/design/capture-scene.sh` → `python3 design/tools/make_previews.py` 로 `preview.png` 생성 → 커밋.
4. `tests/shell/run.sh` 의 테마 왕복과 `hagraui.qml` 테스트는 토큰 키 집합이 같으면 그대로 통과한다.
