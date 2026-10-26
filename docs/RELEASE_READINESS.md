# 하그라 0.1.0 RC1 — 릴리스 준비 보고 (2026-10-26)

> 표기: **PASS**(실행·확인) · **FAIL** · **BLOCKED**(환경 때문에 실행 불가) · **NOT TESTED**(실행하지 않음). 실행하지 않은 검사는 PASS 로 적지 않았다.
> 자동 검사 로그: `out/qa/report.md` (`tests/qa/run-all.sh`). 검증 호스트: Ubuntu 24.04 컨테이너, Qt 6.4.2, labwc 0.7.1, 헤드리스 wlroots(pixman), KVM 없음.

## 1. 요약

- 자동 검사 12건 **모두 PASS** (빌드·토큰·단위 5묶음·셸 통합·설정 11페이지·영어 UI·팝업·유휴·갤러리·.deb·ISO·부팅). 수락 기준 10항 중 **8항 충족**, 2항은 부분(설치기 없음 → 라이브 매체 비영속; 실기기 미검증). 상세는 §4.
- **x86-64 라이브 ISO**(ubuntu-noble 프로필, 477 MB)를 이 세션에서 빌드하고 QEMU(TCG, KVM 없음)에서 부팅 테스트 **PASS**: 부팅→세션→실행 메뉴(새 구조, 앱 아이콘)→터미널→깊은 단청 적용·패널 검사→재부팅→(라이브라 기본 테마)→종료. 셸까지 131 s(TCG), 메모리 301 MB, 셸 RSS 74 MB. 이미지 안에 fcitx5·NetworkManager 가 떠 있음(`docs/screenshots/p5/`). Debian trixie 미러는 이 환경에서 차단되어 trixie 프로필은 NOT TESTED.
- `.deb`(hagra-desktop 0.1.0~rc1, 743 KB) 빌드 PASS. 호스트 유휴: 셸 CPU 0.0~0.03 %, RSS 70 MB.
- 남은 차단 요소: 설치기 부재(라이브 매체에서는 설정이 남지 않음), PipeWire·NetworkManager·swayidle 미포함(해당 설정은 이유를 표시하고 비활성), 실기기(PC·Galaxy S25 Ultra) 미검증, fcitx5 실제 조합 미검증.

## 2. 하위 시스템 상태

| 하위 시스템 | 상태 | 근거 |
|---|---|---|
| 테마 발견성 (3 경로) | **PASS** | 실행 메뉴 설정 버튼·시스템 탭, 바탕 화면 개인 설정 메뉴, 설정 앱. 헤드리스 캡처 `docs/screenshots/p1/` |
| 실행 메뉴 | **PASS** | 탭·검색(초성·영문)·즐겨찾기·최근·빈 상태·아이콘. 단위 `shell.appindex`·`shell.launcherstate`, 통합 02/07/10/11 |
| 설정 앱 (11 페이지) | **PASS** (호스트) | QML 경고 0, 영어·밤 단청 캡처. 소리·네트워크·전원 백엔드는 도구가 있을 때만 활성 — 호스트에 없어 **NOT TESTED**(파서는 단위 테스트) |
| 테마 시스템 (3 팩 + 포인트 색 + 밝기) | **PASS** | `theme.manager` 10 케이스, 통합 테마 왕복 light→deep→night→deep→light, 대비 203 검사, foot 팔레트 |
| 디자인 토큰·HagraUI | **PASS** | `hagraui.qml` 12 케이스, 갤러리 캡처, 접근성 역할 부여 |
| 영어/한국어 UI | **PASS** | 번역 98+334, 영어 셸·설정 캡처 (`docs/screenshots/p2/`) |
| 패널 표시기·알림·달력·창 메뉴 | **PASS** (호스트) | 알림 서버 D-Bus 왕복(통합 12/13), 달력·센터 캡처 `docs/screenshots/p3/`. 소리·배터리 표시기는 호스트에 백엔드 없어 **NOT TESTED** |
| 다중 모니터 | **PASS** (헤드리스 2출력) | 통합 14: 출력마다 패널, wl_output 고정. 실제 두 모니터·배율 차이 **NOT TESTED** |
| 창 관리 (labwc) | **PASS** (설정) | 작업 공간 4·스냅·단축키 rc.xml 검증(XML), 키 동작은 실기기 **NOT TESTED** |
| 세션 신뢰성 | **PASS** (호스트) | 종료 프로토콜 오류 0, 셸 감시 루프(스크립트 검증), 유휴 CPU 0.03 % / RSS 68 MiB (`out/metrics/idle.json`). 크래시 재시작은 이미지 안 **NOT TESTED** |
| 설정 영속성 | **PASS** (호스트) | theme/launcher/panel/notifications/accessibility/display/input/locale/cursor .conf, 재시작 복원(단위·통합). 이미지 재부팅 복원은 §3 |
| 한글 입력 | **NOT TESTED** | fcitx5 패키지·환경·자동 시작 추가. 호스트에 fcitx5 없음; 이미지 재빌드 후 수동 검사 필요 |
| 패키징 (.deb) | **PASS** | `dpkg-buildpackage -b` → hagra-desktop_0.1.0~rc1_amd64.deb (설치 테스트는 NOT TESTED) |
| 이미지·부팅 (x86-64 ISO, QEMU) | **PASS** | §3 image/boot 행, `docs/screenshots/p5/` (ARM64 번들은 CI 가 빌드·부팅 테스트: `.github/workflows/android-image.yml`) |
| 실기기 | **NOT TESTED** | `docs/RELEASE_CHECKLIST.md` §3 |

## 3. 검사 결과 (자동)

`out/qa/report.md` 의 표를 그대로 옮긴다 (실행 시각·시간 포함). 이미지 빌드·부팅 행은 이 세션에서의 실행 결과다.

| ID | 검사 | 결과 | 시간 | 로그/비고 |
|---|---|---|---|---|
| build | 빌드 (cmake + ninja, 테마 팩, 번역) | **PASS** | 1 s | `out/qa/build.log` |
| tokens | 토큰 드리프트·테마 팩·대비 검사 | **PASS** | 0 s | `out/qa/tokens.log` |
| unit | 단위 테스트 (ctest: hagraui.qml, theme.manager, shell.appindex, shell.launcherstate, settings.backends) | **PASS** | 1 s | `out/qa/unit.log` |
| shell | 헤드리스 셸 통합 (패널·실행 메뉴·전원·exclusive zone·테마 왕복 3종·영어 UI·FHD·알림 서버·2출력) | **PASS** | 38 s | `out/qa/shell.log` |
| settings | 설정 앱 11 페이지 렌더링 (QML 경고 0) | **PASS** | 36 s | `out/qa/settings.log` |
| settings_en | 설정 앱 영어 UI | **PASS** | 9 s | `out/qa/settings_en.log` |
| popups | 셸 팝업 (달력·알림·알림 센터·위쪽 패널) | **PASS** | 14 s | `out/qa/popups.log` |
| idle | 유휴 CPU·메모리 측정 (30 s) | **PASS** | 35 s | `out/qa/idle.log` |
| gallery | HagraUI 갤러리 캡처 (3배율) | **PASS** | 92 s | `out/qa/gallery.log` |
| deb | Debian 패키지 빌드 (dpkg-buildpackage -b) | **PASS** | 84 s | `out/qa/deb.log` |
| image | x86-64 ISO 빌드 (ubuntu-noble; Debian 미러 차단) | **PASS** | 235 s | 이 세션 실행 · ISO 477 MB |
| boot | QEMU TCG 부팅 테스트 (부팅→세션→실행 메뉴→터미널→테마→재부팅→종료) | **PASS** | 382 s | `out/boot-test-x86/` |
| device | 실기기 (PC UEFI/BIOS · Galaxy S25 Ultra Termux) | NOT TESTED | — | 수동 체크리스트: docs/RELEASE_CHECKLIST.md |
| ime | 한글 입력(fcitx5) 실제 조합 | NOT TESTED | — | 이미지 재빌드 후 수동 (호스트에 fcitx5 없음) |
| audio | 소리 백엔드 (wpctl/pactl) | NOT TESTED | — | 호스트에 PipeWire 없음 — 파서는 단위 테스트로 검증 |
| net | NetworkManager Wi-Fi 연결 | NOT TESTED | — | 호스트에 nmcli 없음 — 파서는 단위 테스트로 검증 |

## 4. 수락 기준 대조

| 기준 | 판정 | 비고 |
|---|---|---|
| 안내 없이 테마를 찾아 바꿀 수 있다 | PASS | 세 경로, 즉시 적용·되돌리기 |
| 핵심 데스크톱 조작이 기대대로 동작한다 | PASS (호스트) | 실행·전환·닫기·메뉴·알림·달력. 실기기 미검증 |
| 기존 테마가 남아 있다 | PASS | 연한·깊은 단청 그대로, 기본값 유지 |
| 설정이 세션 사이에 유지된다 | PASS (설치/qcow2) · 라이브 ISO 는 매체 특성상 아님 | |
| 알려진 치명적 시작·종료 실패 없음 | PASS | 헤드리스 + QEMU 부팅·재부팅·종료 PASS, 종료 프로토콜 오류 0 |
| 한국어 타이포그래피·입력 | 타이포 PASS · 입력 부분 | Noto Sans CJK, 말줄임·배율 검사; 이미지에서 fcitx5 가 자동 시작됨(프로세스 확인), 실제 한글 조합은 NOT TESTED |
| 일반 해상도에서 사용 가능 | PASS | 1280×720·1920×1080·2560×1440@200 % 캡처 |
| 설치·되돌리기 절차 문서화 | PASS (문서) · 설치기 없음 | `docs/INSTALL.md` |
| 주요 접근성·사용성 문제 해결 | PASS (부분) | 역할·포커스·글자 배율·대비; 화면 읽기 미검증 |
| 핵심 릴리스 검사에 검증 가능한 결과 | PASS | 이 문서 + `out/qa/report.md` + 스크린샷 |

## 5. 다음 마일스톤

1. 설치기(M6) — 라이브 매체 한계 해소. 2. PipeWire·NetworkManager·swayidle 포함 이미지 + 실기기 검증. 3. SNI 트레이 호스트. 4. 화면 읽기(at-spi/orca) 검증. 5. labwc 0.8 로 올려 키보드 배치 즉시 적용·작업 공간 표시기.
