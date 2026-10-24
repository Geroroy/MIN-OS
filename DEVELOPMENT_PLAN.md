# 하그라(HAGRA) 개발 계획

> 2026-10-24 프로젝트명 변경: MIN OS → 하그라. 아래 M0/M1/M1-A 기록은 변경 전 이름으로 검증된 결과이며 그대로 유효하다.

> 상태 표기: ☐ 예정 · ◐ 진행 중 · ☑ 완료 · 각 마일스톤은 "검증 방법"이 통과해야 완료로 간주한다.

## 전체 로드맵

| 단계 | 마일스톤 | 핵심 산출물 | 검증 |
|---|---|---|---|
| M0 | 프로젝트 기반 | 아키텍처·디자인 문서, 저장소 구조, 빌드 파이프라인 골격 | 문서 리뷰, `make shell` 빌드 |
| M1 | QEMU 부팅 개발 이미지 | Debian 기반 hybrid ISO, Wayland + labwc 세션, MIN Shell 패널, 앱 실행, 터미널, 종료/재부팅 | `make test-shell`, `make test-image` |
| M2 | MIN Shell 완성 | 창 목록·창 전환, 시스템 트레이(SNI), 알림 데몬, 시계/캘린더, 볼륨·네트워크 표시 | 헤드리스 통합 테스트 |
| M3 | MIN Files | 탐색, 복사/이동/삭제(undo), 속성, 드라이브 마운트(udisks2) | 단위 테스트 + UI 테스트 |
| M4 | MIN Settings + minos-settingsd | 디스플레이(wlr-output-management), 사운드(PipeWire), 네트워크(NetworkManager), 테마, 시스템 정보 | D-Bus 모의 테스트 |
| M5 | MIN Terminal | VT 에뮬레이션(libvterm), 탭, MIN 테마 | vttest 호환성 |
| M6 | MIN Installer | 디스크 파티셔닝, rootfs 복사, 사용자 생성, GRUB(UEFI/BIOS), 첫 부팅 | QEMU 가상 디스크에 설치 후 재부팅 |
| M7 | 릴리스 품질 | 컴포넌트 .deb 패키징, APT 저장소, 재현 가능한 ISO, 실제 PC 검증 | 실기기 체크리스트 |
| M8+ | 확장 | MIN Greeter(greetd 프런트엔드), 자체 컴포지터 평가, 전원 관리, 접근성 | — |

## M0 — 프로젝트 기반  ☑

- [x] 개발 환경 조사 (`docs/BUILD_ENVIRONMENT.md`)
- [x] 아키텍처 설계 (`docs/ARCHITECTURE.md`)
- [x] 디자인 언어 정의 (`docs/DESIGN_LANGUAGE.md`)
- [x] 저장소 구조 생성
- [x] 호스트 의존성 스크립트 (`scripts/install-deps.sh`)
- [x] 이미지 빌드 파이프라인 1차 동작 (ubuntu-noble 프로필, 431 MB ISO)

## M1 — QEMU에서 부팅되는 MIN OS 개발용 이미지  ◐ (ubuntu-noble 프로필로 전 항목 검증 완료, debian-trixie 빌드 검증 대기)

요구사항과 구현 방법은 `docs/MILESTONE_1.md`에 상세히 기술한다.

| 요구사항 | 구현 | 상태 |
|---|---|---|
| Debian 기반 부팅 | mmdebstrap rootfs → squashfs → live-boot initramfs → GRUB hybrid ISO | ◐ UEFI 부팅·live-boot 검증(ubuntu-noble). Debian trixie 빌드는 미러 접근 가능한 PC에서 수행 필요 |
| Wayland 세션 실행 | greetd 자동 로그인 → `minos-session` | ☑ logind 세션 seat0/tty7, `wayland-0` 소켓 확인 |
| Labwc 실행 | `/etc/minos/labwc/` 전용 rc.xml, MIN 테마 | ☑ |
| MIN OS 전용 데스크톱 화면 | 배경(swaybg, 단색/MIN 로고) + MIN Shell 패널 | ☑ `docs/screenshots/m1-desktop.png` |
| 기본 작업 표시줄 | `minos-shell` (Qt6/QML + wlr-layer-shell) 하단 패널: 시작 버튼, 창 목록, 시계, 전원 | ☑ 픽셀 검사 통과 |
| 애플리케이션 실행 기능 | `.desktop` 파일 스캔 → 실행 메뉴 | ☑ `docs/screenshots/m1-launcher.png` |
| 터미널 실행 | foot (MIN 테마 적용), 패널 버튼 및 Super+Enter | ☑ `docs/screenshots/m1-terminal.png` |
| 정상적인 종료 및 재부팅 | 패널 전원 메뉴 → logind D-Bus(PowerOff/Reboot) | ☑ Reboot → 2차 부팅 세션 확인, PowerOff → QEMU 종료 |

### M1 완료 기준
1. `sudo make image` 가 Debian trixie(또는 미러가 막힌 환경에서 ubuntu-noble)로 ISO를 생성한다. — ubuntu-noble ☑ / debian-trixie ☐
2. `make test-shell` 이 헤드리스 labwc에서 MIN Shell을 띄우고 스크린샷에서 패널을 확인한다. — ☑
3. `sudo make test-image` 가 QEMU에서 부팅 → 세션 시작 로그 확인 → `poweroff` → 재부팅 시나리오를 통과한다. — ☑ (2026-10-23, TCG 기준 1회 부팅 ≈ 3분)

### M1 잔여 작업
- [ ] Debian trixie 프로필로 `sudo make image` 및 `sudo make test-image` 실행 (Debian 미러 접근 가능한 PC)
- [ ] 이미지 APT 소스에 updates/security 포켓 추가 (현재 release 포켓만: Ubuntu 커널 6.8.0-31)
- [ ] 실행 메뉴/전원 메뉴 한국어 번역 (Qt Linguist, M2 i18n과 함께)

## M1-A — Android(ARM64) 에뮬레이션 트랙  ◐

목표: Galaxy S25 Ultra 의 Termux QEMU(ARM64, TCG, 루트 없음)에서 MIN OS 전체를 부팅한다. 문서: `docs/ANDROID_EMULATION.md`,
`docs/ARM64_ARCHITECTURE.md`, `docs/ANDROID_PERFORMANCE.md`.

| 단계 | 내용 | 상태 |
|---|---|---|
| A | 기존 빌드 시스템 분석, 아키텍처 의존 부분 분리 | ☑ |
| B | ARM64 이미지 빌드: 교차 rootfs(qemu-user binfmt), 디스크 이미지(GPT/ESP/ext4 → qcow2), in-target GRUB arm64-efi, mobile 프로필 | ☑ `sudo make image-arm64` |
| C | PC QEMU 에서 ARM64 부팅 검증 (직접 커널 부팅) | ☑ root 셸 98 s, systemd running |
| C' | UEFI(AAVMF/edk2 → GRUB arm64-efi) 경로 | ☑ 부팅·세션·패널·터미널·종료 통과 (`gzio` 모듈, 소프트웨어 렌더링 자동 감지 수정 후) |
| D | ARM64 그래픽 세션 검증: greetd → labwc → MIN Shell → 터미널 → 재부팅 → 종료, 스크린샷 | ☑ `docs/screenshots/arm64-*.png` |
| E | Termux 실행 스크립트 `android/start-minos.sh`, 설치 스크립트 `android/install-termux.sh`, VNC 127.0.0.1 | ☑ (스크립트 문법·PC 장치 모델 동일성 확인, Termux 실행은 미검증) |
| F | 실기기 테스트 절차 (`docs/ANDROID_EMULATION.md` §8 체크리스트) | ☑ 절차 제공 / ☐ 실기기 수행 |
| G | 성능 최적화(mobile 프로필)·회귀 테스트(x86-64 M1 재실행) | ☑ x86-64 ISO 재빌드 후 M1 테스트 PASS, ARM64 직접/UEFI 부팅 PASS |

### M1-A 잔여 작업
- [ ] **Galaxy S25 Ultra 실기기 검증** (Termux 패키지 설치 → 부팅 → VNC 조작 → 측정값 기록)
- [ ] Debian trixie ARM64 빌드 (Debian 미러 접근 가능한 PC)
- [ ] 실기기 측정 후 기본 vCPU/해상도 재조정
- [ ] 터치 UX 개선: 패널 높이/버튼 크기 모바일 프로필 옵션 (디자인 언어 유지 범위 안에서)

## H0 — 하그라 전환 기반 (디자인 적용 준비)  ◐  (2026-10-24)

| 항목 | 내용 | 상태 |
|---|---|---|
| 토큰 단일 원본 | `design/tokens/hagra.tokens.json` → Theme.qml / labwc themerc / foot.ini 생성, `--check` 드리프트 검사 (`make tokens-check`) | ☑ 값 동일성 확인 |
| 공통 부품 | MinUI 20종(버튼·입력·검색·체크·라디오·선택목록·탭·목록행·스크롤바·툴팁·메뉴·대화상자·알림·진행·아이콘·창프레임 모형) + 8상태 모델, 선택/포커스 분리 | ☑ 갤러리에서 확인 |
| 미리보기 실행기 | `tools/preview/minui-preview` (`--state`, `--scale`, `--icons`) | ☑ |
| 갤러리 | `libs/minui/gallery/Gallery.qml`, 7섹션 × 100/150/200% 캡처 (`tests/design/capture-gallery.sh`) | ☑ 21장 캡처 |
| 대표 장면 | `design/scenes/FilesScene.qml`(예제 데이터, 실제 파일 작업 없음) + 비활성 창 + 셸 + labwc 장식, 100%(기본/메뉴/대화상자)·200% 캡처 | ☑ 4장 캡처 |
| 이름 변경 | 사용자 노출 문자열(GRUB, issue, 세션 항목, 패널 라벨, Android 안내) → 하그라/HAGRA. 내부 식별자 유지 | ☑ |
| 디자인 문서 | `docs/HAGRA_PHILOSOPHY.md`, `docs/UI_FOUNDATION.md`, `docs/DESIGN_HANDOFF.md` | ☑ |
| 회귀 검증 | 단위 테스트, 헤드리스 셸 테스트, x86-64 ISO·ARM64 번들 부팅 테스트 재실행 | ☑ 2026-10-24: 단위 12/12, 셸 통합 PASS, x86-64 ISO 부팅→세션→실행 메뉴→터미널→재부팅→종료 PASS(셸 121 s), ARM64 번들 동일 시나리오 PASS |
| 디자인 자산 적용 | 디자인 담당의 토큰·아이콘·기준 이미지 수신 후 적용·비교 | ☑ H1 에서 수행 (`design/hagra-dancheong-v1/`) |
| 한글 입력 | fcitx5-hangul 통합 | ☐ (M2) |
| 접근성 역할 | MinUI 부품에 `Accessible.*` 부여 | ☐ |

## H1 — 하그라 연한 단청 UI 적용  ◐  (2026-10-24; 적용·검증 완료, 레일·트레이·실기기는 후속)

입력: 디자인 패키지 `design/hagra-dancheong-v1/` (CLAUDE_TASK.md, DESIGN_SPEC.md, tokens.json, SVG 12종, wallpaper.png, 기준 PNG 1672×941).
원칙: 기존 M0/M1·Android 트랙 보존, MinUI API 유지, 내부 식별자(`minos-*`) 유지, 비표준 labwc 키 금지, 매 프레임 재그리기·블러·셰이더 금지.

| 항목 | 내용 | 상태 |
|---|---|---|
| 토큰 | `hagra.tokens.json` 을 dancheong-v1 값으로 교체(status `design-v1`), 생성기에 window/asset 토큰 추가, Theme/themerc/foot.ini 재생성 (`make tokens-check` OK) | ☑ |
| 패널 52px | 8px 축소 연화 띠 + 1px 경계 + 43px 콘텐츠(컨트롤 36). exclusiveZone=52. 실행·전원 팝업은 exclusive zone 위에 바로 붙음(이전엔 패널 높이를 두 번 더하던 버그 수정) | ☑ 셸 테스트 PASS |
| 셸 | 시작 버튼 "하그라"+연꽃, 창 항목(아이콘·제목·닫기, 활성=선택 배경+굵게+3px 막대), 로케일 시계(`M월 d일 (ddd) AP h:mm`), 전원 버튼; 실행 메뉴·전원 메뉴 밝은 테마+띠, 한국어 라벨 | ☑ |
| MinUI 밝은 테마 | 버튼·입력·목록행·체크·라디오·메뉴·탭·스크롤바·대화상자 8상태 재조정, 포커스 링 z:5(장식보다 앞), 눌림 1px 오프셋, 비활성 아이콘 흐림 | ☑ 갤러리 + QML 동작 테스트 11/11 |
| 장식 부품 | `MOrnamentBand`(가로 타일, compact), `MOrnamentFrame`(겹선+모서리 결구, 앱 내부), `MOrnamentDivider`; 자산은 모듈 `assets/` 에서 로드(설치 경로 동일) | ☑ 갤러리 ornament 섹션 |
| 아이콘 | 장식·폴더·문서 12종(패키지 사본) + 조작 기호 21종(단색, 저장소 작성). 누락 시 자리 표시자, 갤러리 icons 섹션에서 로드 여부 표시 | ☑ 누락 0 |
| labwc 장식 | 지원 키만 사용: 밝은 청자 제목(활성 #D2E2D5 굵게 / 비활성 #E5EBE0 보통), 2px 경계(활성 #4F756D / 비활성 #90A99E), cornerRadius 2, Noto Sans CJK KR 12pt. 전역 문양 제목줄은 불가 → 앱 내부 띠로 구현 (범위는 UI_FOUNDATION §2.2) | ☑ labwc 로그에서 themerc 읽힘 확인 |
| 대표 장면 | `FilesScene.qml` 재작성(띠·도구막대·사이드바 창살·폴더 격자·선택/포커스·상태줄, 예제 데이터), `SettingsScene.qml` 추가(비활성 창), 1280×720 기본/메뉴/대화상자 + 1920×1080 + 200% 캡처 | ☑ 5장 |
| 배경 | `session/wallpaper/hagra-dancheong.png`(사전 렌더링 PNG, swaybg 고정 텍스처), `MINOS_WALLPAPER` 로 교체 가능 | ☑ |
| 1920×1080 | 셸이 첫 configure 크기 ≠ QML 초기 폭일 때 segfault(생성 중 resize→Expose) → `LayerWindow` 가 생성 대기 후 크기 적용. 셸 테스트에 FHD 회귀 추가 | ☑ |
| 키보드·접근성 | `libs/minui/tests/tst_minui.qml` (qmltestrunner, ctest `minui.qml`): Tab/Shift+Tab 체인, Enter/Space, 비활성 차단, 포커스 링, 오류 표시, 입력란 Tab(수정), 메뉴 키 탐색·창 내 고정, 자산 로드 | ☑ |
| 한글 조합·긴 경로 | 갤러리 inputs/text, 장면의 긴 파일명 말줄임(ElideMiddle) 확인. IME 자체는 미통합(M2) | ◐ |
| Qt SVG | `libqt6svg6` 가 `packages.desktop` 에 포함; x86-64·ARM64 이미지 안에서 연꽃·띠 SVG 가 그려짐(부팅 테스트 스크린샷) | ☑ |
| 회귀 검증 | 단위(ctest 2/2), 셸 통합(5 장면), 토큰 검사; x86-64 ISO(hook 30,40,90 재실행)·ARM64 번들(hook 30,40,55,90) 부팅 테스트 | ☑ 모두 PASS (아래 "H1 검증 기록") |
| 좌측 레일 | 실제 실행·키보드 탐색·화면 예약 영역을 아직 구현하지 않음 → 추가하지 않음(기준 시안과의 차이로 기록) | ☐ |
| 트레이(네트워크·볼륨·배터리) | M2 범위. 패널에 자리만 비워 둠 | ☐ (M2) |
| 파일 관리자 | M3. 장면은 예제 데이터이며 복사·삭제·마운트 없음 | ☐ (M3) |

### H1 검증 기록

- 2026-10-24 호스트(Ubuntu 24.04, Qt 6.4.2, labwc 0.7.1): `make tokens-check` OK · ctest 2/2 (`shell.appindex`, `minui.qml` 11 케이스) · `tests/shell/run.sh` PASS (패널·실행 메뉴·전원 메뉴·foot exclusive zone·1920×1080) · 갤러리 9섹션×3배율 27장 · 장면 5장.
- 부팅 회귀 x86-64 (2026-10-24, TCG 2 vCPU): hook 30,40,90 재실행 → ISO 431 MB → `tests/image/boot_test.py` PASS (부팅→로그인→세션→실행 메뉴→터미널→재부팅→종료; 셸까지 120.5 s). 이미지 안에서 단청 배경·52px 패널·밝은 실행 메뉴·밝은 foot·청자 제목줄 확인 (`docs/screenshots/h1/boot-x86-*.png`). libqt6svg6·MinUI assets 34개·배경 PNG 가 rootfs 에 설치됨.
- 부팅 회귀 ARM64 (2026-10-24, x86 호스트 TCG, qemu-user binfmt 로 chroot 빌드): hook 30,40,55,90 재실행 → 번들 1.2 GB → `boot_test.py out/minos-arm64` PASS (같은 시나리오; 셸까지 98.8 s). 이미지 안에서 단청 배경·패널·실행 메뉴 확인 (`docs/screenshots/h1/boot-arm64-*.png`). 게스트 시계는 RTC 기본값(4월 19일)이라 실제 날짜가 아니다. Galaxy S25 Ultra 실기기 검증은 수행하지 않았다.
- 주의: binfmt 등록 시 매직의 NUL 바이트가 잘리면 모든 x86-64 ELF 가 qemu-aarch64 로 보내져 프로세스를 실행할 수 없게 된다(이번 작업에서 1회 발생, `-1` 쓰기로 복구). 등록은 `scripts/install-deps.sh` 의 리터럴 `\\x..` 문자열 방식만 사용한다.

## M2 — MIN Shell 완성  ☐

- 창 목록/전환: `wlr-foreign-toplevel-management-unstable-v1` (labwc 지원) — Alt+Tab 오버레이 포함
- 시스템 트레이: StatusNotifierItem/StatusNotifierWatcher (D-Bus) 호스트 구현
- 알림: `org.freedesktop.Notifications` 서버 내장, 알림 센터 패널
- 인디케이터: 볼륨(PipeWire/wireplumber), 네트워크(NetworkManager D-Bus), 배터리(UPower)
- MinUI 디자인 시스템 모듈 안정화 (`libs/minui`)
- 키보드 중심 조작: Super 키 실행 메뉴, 타입-투-서치, 방향키 탐색

## M3 — MIN Files  ☐
- Qt6/QML, 모델은 C++ (QAbstractItemModel), 파일 작업은 별도 작업 큐 스레드
- 복사/이동/삭제(휴지통 freedesktop spec), 속성(권한·크기·MIME)
- udisks2 연동 드라이브 목록, 북마크, 키보드 단축키 중심 UI

## M4 — MIN Settings  ☐
- `minos-settingsd` (Rust, D-Bus `org.minos.Settings`): 테마·폰트·입력 설정의 단일 소스
- 디스플레이: `wlr-output-management` 로 해상도/배치 적용 + labwc 설정 저장
- 사운드: PipeWire(wireplumber) 기본 장치/볼륨
- 네트워크: NetworkManager D-Bus
- 시스템 정보: 커널, CPU, 메모리, 디스크, MIN OS 버전

## M5 — MIN Terminal  ☐
- libvterm 기반 Qt6 터미널 위젯(QQuickPaintedItem), 탭, 복사/붙여넣기, MIN 테마
- foot 는 M5 완료 시 기본 터미널에서 대체

## M6 — MIN Installer  ☐
- 백엔드(Rust, root 권한, D-Bus 또는 pipe 프로토콜): 파티션(sfdisk/libparted), 포맷, squashfs 복사(unsquashfs), fstab, 사용자/호스트명/로케일, GRUB(UEFI+BIOS), initramfs
- 프런트엔드(Qt6/QML): 언어 → 디스크 → 사용자 → 요약 → 진행 → 완료(재부팅)
- 안전 장치: 가상 디스크 외에는 명시적 확인 없이 쓰지 않음, dry-run 모드

## M7 — 릴리스 품질  ☐
- 컴포넌트별 debian/ 디렉터리, `dpkg-buildpackage`, 자체 APT 저장소(reprepro)
- 재현 가능한 ISO(SOURCE_DATE_EPOCH), 버전 체계 `MIN OS <YY.MM>`
- 실기기 체크리스트: UEFI/BIOS, Intel/AMD GPU, Wi-Fi, 노트북 전원

## 기술 결정 기록 (ADR 요약)

| # | 결정 | 이유 |
|---|---|---|
| 1 | 이미지 빌드에 live-build 대신 mmdebstrap + 자체 스크립트 | live-build는 Debian 전용·대형 프레임워크이고 Ubuntu 패키지는 구버전(3.0~a57). mmdebstrap은 양쪽에서 동작하고 재현성·투명성이 높다. 산출물(squashfs+live-boot+GRUB ISO)은 live-build와 동일한 형식이다. |
| 2 | Debian 13 "trixie" 기본 대상 | 현재 Debian Stable. Qt 6.8, labwc 0.8, greetd, pipewire 1.2 등 필요한 버전을 포함한다. |
| 3 | 세션 시작은 greetd | 경량, 자동 로그인 지원, 이후 MIN Greeter(greetd IPC 프런트엔드)로 자연스럽게 확장. |
| 4 | 패널 고정에 자체 `minlayershell` 구현 | KDE layer-shell-qt의 Qt6 버전이 모든 대상 배포판에 없음(Ubuntu 24.04는 Qt5판만). Qt 공개 API(`QWaylandClientExtension`)만 사용해 버전 의존을 피한다. |
| 5 | M1 터미널은 foot 재사용 | 원칙 4(초기에는 안정 컴포넌트 재사용). MIN Terminal은 M5. |
| 6 | MIN 컴포넌트는 대상 chroot 안에서 빌드 | 호스트 Qt 버전과 대상 이미지 Qt 버전 불일치를 피하고, 결과 바이너리가 실제 설치 환경과 동일하다. |
| 7 | Rust는 시스템 데몬·설치기 백엔드, C++는 Qt UI | Qt/QML 바인딩 성숙도와 메모리 안전성의 균형. |
| 8 | ARM64 는 디스크 이미지(qcow2) + 직접 커널 부팅을 기본으로 | Termux QEMU 에 펌웨어 의존 없음, 영속 저장, 커널 명령행 제어. UEFI/GRUB 은 같은 이미지의 ESP 로 병행 지원. |
| 9 | 교차 빌드 대신 qemu-user binfmt 로 대상 chroot 안에서 네이티브 빌드 | 교차 컴파일 툴체인·sysroot 관리 불필요, 결과물이 대상과 동일. 빌드 시간(≈ 20분)은 허용 범위. |
