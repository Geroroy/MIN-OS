# 하그라 디자인 전달용 기술 명세

> 이 문서는 디자인 담당에게 그대로 전달하기 위한 독립 문서다. 구현 측 저장소: https://github.com/Geroroy/MIN-OS (브랜치 `ccr-0dc4d66d-j60c3m`).
> 작성일 2026-10-24. 현재 화면·값은 모두 **임시**이며, 아래 형식으로 전달된 디자인을 구현 측이 적용·검증한다.

## 1. 제품과 범위

- 하그라(영문 임시 HAGRA): Debian 기반 Linux 데스크톱 OS. x86-64 PC 와 ARM64(Android/Termux 안의 QEMU) 를 같은 UI 코드로 지원.
- 첫 검증 장면: **바탕화면에서 파일 관리자를 열고 문서 폴더의 파일을 선택하는 장면**. 파일 관리자는 아직 예제 데이터 미리보기다.
- 디자인 철학과 우선순위: `docs/HAGRA_PHILOSOPHY.md`.

## 2. UI 기술과 버전

| 층 | 기술 | 버전 (현재 검증 환경 / 공식 대상) |
|---|---|---|
| 디스플레이 | Wayland | — |
| 컴포지터·창 장식 | labwc (wlroots) 서버 측 장식(SSD), Openbox 호환 themerc | 0.7.1 / 0.8.x (Debian trixie) |
| 앱·셸 UI | Qt 6 Quick/QML, C++ | **6.4.2** (Ubuntu 24.04) / 6.8 (Debian trixie). 6.4 에 없는 기능은 쓰지 않는다 |
| 공통 부품 | MinUI (직접 작성한 QML 부품, Qt Quick Controls 미사용) | `libs/minui/qml/MinUI/` |
| 셸 | minos-shell (패널·실행 메뉴·전원 메뉴, wlr-layer-shell) | `shell/qml/` |
| 터미널 | foot | 1.16 |
| 렌더링 | GPU 가 없는 환경(QEMU, 휴대폰)은 **소프트웨어 렌더링**(labwc pixman, Qt Quick software) | — |

## 3. 테마와 창 장식의 구현 방식

- **QML 내부 UI**: 모든 색·치수·글꼴은 `Theme` 싱글톤(생성 파일)에서 읽는다. 디자인이 토큰을 주면 생성기가 Theme 을 다시 만든다.
- **창 장식(제목 표시줄·테두리·창 버튼)**: labwc 가 그린다. 조절 가능한 것은 themerc 키뿐이다:
  테두리 두께, 활성/비활성 테두리색, 제목 배경색, 제목 글자색, 제목 정렬, 제목 글꼴(pt), 제목 패딩(상하/좌우), 창 버튼 아이콘 색·호버 배경,
  창 버튼 아이콘 이미지(테마 디렉터리의 xbm/png 로 교체 가능), 모서리 반경(현재 2). **그림자·블러·투명·그라디언트·애니메이션·문양 이미지는 불가.**
  → 문양(연화 띠·모서리 결구)은 하그라 앱이 창 안에서 직접 그린다 (`MOrnamentBand`, `MOrnamentFrame`). 외부 앱 창에는 적용되지 않는다. 범위: `docs/UI_FOUNDATION.md` §2.2
  제목 표시줄 높이 = 글꼴 높이 + 2×패딩 (직접 지정 불가, labwc 0.8 부터 `titlebar.height` 지정 가능).
- **루트 메뉴(바탕 우클릭)·Alt+Tab 목록**: labwc 가 그린다 (themerc 의 menu.*, osd.* 키).
- **패널·실행 메뉴·전원 메뉴**: 셸(QML)이 그린다. 화면 가장자리 고정, 높이 토큰(`panelHeight`).
- **대화상자**: 별도 창이므로 창 장식은 labwc, 내용은 QML.
- **툴팁·드롭다운·앱 내 메뉴**: 창 안에서만 표시된다(창 밖으로 못 나감).
- **외부 앱**: 창 장식만 동일. 앱 내부는 각자 스타일이라 강제 불가.

## 4. 토큰 파일 형식

`design/tokens/hagra.tokens.json` (JSON). 그룹: `brand`, `color`, `window`, `menu`, `osd`, `size`, `font`, `motion`, `terminal`.
현재 파일을 그대로 복사해 값만 바꿔 보내면 된다. 규칙:

- 색: `#RRGGBB` 또는 `#AARRGGBB`(QML)·`#RRGGBBAA`(labwc 전용 키). 터미널 색은 `RRGGBB`(# 없음).
- 치수: **논리 픽셀**(배율 1.0), 정수. 글꼴 크기 px(QML), 제목 글꼴은 pt(labwc).
- `color.focusRing`/`color.selection` 은 `accent` 와 분리되어 있다. 포커스와 선택을 다른 색으로 줄 수 있다.
- 새 토큰이 필요하면 키를 추가하고 용도를 `_note` 에 적는다. 생성기(`design/tools/gen_tokens.py`)에 매핑을 추가하는 것은 구현 측 일이다.
- 밝은 테마/어두운 테마는 토큰 파일 두 벌로 보낸다 (현재: 밝은 연한 단청 v1 하나. `status: design-v1`).

## 5. 아이콘 형식과 크기 규칙

- 형식: **SVG**(Qt SVG 렌더러: SVG Tiny 1.2 수준. 필터·마스크·CSS 변수·`currentColor` 미지원). 단색 아이콘은 색을 SVG 안에 직접 지정한다.
  상태별(기본/비활성/선택 위) 색이 다르면 **파일을 따로** 준다: `name.svg`, `name-disabled.svg`, `name-onselection.svg`.
- 크기: 16px 격자(목록·메뉴·버튼), 24px 격자(실행 메뉴·도구 막대). 선 굵기 1px 또는 1.5px(1× 기준). 2× 에서 2px/3px 로 보인다.
- 경로: `design/assets/icons/<name>.svg` → 설치 `/usr/share/hagra/icons/`. 코드는 `MIcon { name: "folder" }` 로 참조한다.
- 첫 장면에 필요한 이름: `folder`, `file`, `home`, `download`, `image`, `trash`, `drive`, `usb`, `search`, `back`, `forward`, `up`, `menu`, `close`, `check`, `warning`, `error`, `info`, `power`.
- 창 버튼(최소화/최대화/닫기)은 labwc 테마 디렉터리용 이미지로 별도 제공(선택).
- 앱 아이콘(실행 메뉴용)은 freedesktop 아이콘 테마 규격(48px SVG) — 후속.
- 로고·워드마크: 미확정. 배경은 현재 임시 단색(`#1a1a1a`).

## 6. 글꼴·배율·좌표 단위

- 글꼴: 본문 Inter(한글 없음) + 한글 폴백 Noto Sans CJK KR, 고정폭 DejaVu Sans Mono. **한글·라틴 혼합 문자열은 두 글꼴이 섞인다** —
  디자인에서 본문 글꼴을 한글 포함 글꼴(예: Pretendard, Noto Sans KR)로 지정하면 토큰 `font.family` 로 반영한다(라이선스 확인 필요).
- 크기: 본문 12px, 작은 글씨 11px, 제목 13px (논리 px). 행 높이 1.4.
- 배율: 100%·200% 는 정수 배율로 정확히 재현. **150% 는 Qt 6.4 에서 분수 배율 미지원**(컴포지터 확대로 흐림). 디자인은 1× 격자로 주고
  2× 에서 선 굵기가 짝수로 떨어지는지 확인한다.
- 좌표: QML 논리 px, 원점 좌상단. labwc 치수도 논리 px. 캡처 PNG 는 실제 px.

## 7. 대표 화면 기준 해상도

- 기준: **1280×720 논리**(1× 캡처 1280×720, 2× 캡처 2560×1440). 패널 높이 28, 파일 창 880×560(임시), 보조 창 420×300(임시).
- 추가 검토 해상도(후속): 1920×1080@1×, 1366×768@1×, 휴대폰 VNC 1280×720(터치 조작 고려).

## 8. 지원 가능한 효과와 제약

| 가능 | 불가/제한 |
|---|---|
| 단색 면, 1px 선, 사각 모서리, 반경(QML 내부만) | 창 장식의 그림자·블러·투명 |
| 2px 강조 막대, 포커스 링, 상태별 색 | 전역 블러·반투명 패널(소프트웨어 렌더링 비용) |
| 진행 표시기 애니메이션 | 전환 애니메이션(원칙상 0ms; 디자인 요청 시 비용 검토) |
| 아이콘 SVG(정적 색) | SVG 재착색, 필터, 그라디언트 메쉬 |
| 2× 정수 배율 | 1.5× 선명 렌더링(Qt 6.8 에서 재검증) |

## 9. 디자인 자산이 들어갈 경로

| 자산 | 경로 |
|---|---|
| 토큰 JSON | `design/tokens/hagra.tokens.json` |
| 디자인 패키지 v1 (받은 그대로) | `design/hagra-dancheong-v1/` — 다음 버전은 `design/hagra-dancheong-v2/` 처럼 나란히 둔다 |
| 실행용 SVG | `libs/minui/qml/MinUI/assets/` (구현 측이 패키지에서 복사·보강) |
| 배경·로고 | `design/assets/wallpaper/`, `design/assets/brand/` |
| 기준 이미지(대표 화면) | 패키지 `reference/` (현재 `hagra-dancheong-concept.png` 1672×941). 1×·2× 정확 배율본이 있으면 더 좋다 |
| 부품 규격·상태 명세 | `design/reference/components.md` 또는 PDF |

## 10. 기준 화면을 실행·캡처하는 방법 (구현 측)

```sh
make shell                           # Qt 6.4+, labwc, grim 필요 (scripts/install-deps.sh)
tests/design/capture-gallery.sh      # 부품 갤러리 9섹션 × 100/150/200% → out/design/gallery/
tests/design/capture-scene.sh        # 대표 장면 1280×720(기본/메뉴/대화상자), 1920×1080, 200% → out/design/scene/
```
캡처는 실제 세션(헤드리스 labwc + 셸 + 창 장식)에서 만들어지므로 기준 이미지와 1:1 비교할 수 있다.
비교 결과와 충돌(기준 이미지 ↔ 수치 명세)은 구현 측이 `docs/UI_FOUNDATION.md` 에 기록한다.

## 11. 디자인 담당이 결정해야 할 사항

v1 패키지(2026-10-24)로 1~5, 7~10 의 1차 결정이 들어왔다. 구현 후 남은 확인 사항:

1. 사이드바 선택 행: 시안은 산호 배경+흰 글자, 명세는 "연한 색 위 흰 글자 금지" → 구현은 선택 토큰(연살구+짙은 글자). 어느 쪽인지.
2. 매듭(술) 자산: 시안의 사이드바 하단·폴더 술 장식 SVG 가 패키지에 없다. 반복 단위로 제공 가능한지.
3. 폴더·문서 아이콘의 큰 크기(96 이상)용 상세 버전 여부. 현재 72px 에서 패키지 SVG 그대로.
4. 창 제목 아이콘: labwc SSD 로는 불가. 앱 내부 띠 왼쪽에 작은 연꽃을 둘지(선택).
5. 좌측 레일: 실제 기능(실행·키보드 탐색·예약 영역)을 M2 에서 구현할 때의 항목 목록과 터치 타깃 크기.
6. 워드마크(바탕 오른쪽 아래)와 로고 — 브랜드 확정 후.
7. 어두운 테마 여부.

## 12. 테마 팩 형식 (H2, 2026-10-26)

디자인은 "테마 팩" 단위로 전달·추가된다. 기존 테마를 대체하지 않고 선택지로 들어간다.

| 파일 | 내용 |
|---|---|
| `theme.json` | `id`(영문 소문자·하이픈), `displayName`, `description`, `default`(하나만 true), `tokens`, `assets`, `wallpaper`, `preview` 경로 |
| `tokens.json` | 저장소 토큰 스키마 (`design/tokens/hagra.tokens.json` 복사 후 값 변경). 역할 전경 토큰 `panel/panelText/sidebar/sidebarText/titleText/titleInactiveText/focusRing/focusRingOnDark` 를 반드시 채운다 |
| `assets/*.svg` | lotus, lotus-band(108×18 가로 반복), corner-rosette, cloud-tile, lattice-tile, bojagi-tile, folder-{writing,translation,reference,project}, document, settings — 이름은 고정 |
| `wallpaper.png` | 1920×1080 사전 렌더링 |
| `preview.png` | 480×270 (구현 측이 실제 캡처로 만든다) |

대비: 본문·패널·사이드바·선택·제목의 글자/바탕이 4.5:1 이상. 어두운 면 위 조작 아이콘은 분백 잉크 변형을 자동으로 쓴다. 주홍·황토 같은 장식색은 작은 글자색으로 쓰지 않는다.
