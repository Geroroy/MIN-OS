# 하그라 아키텍처

## 1. 계층 구조

```
┌──────────────────────────────────────────────────────────────────────┐
│ 애플리케이션   하그라 파일 · 하그라 설정 · 하그라 터미널 · 하그라 설치기 │
│               + APT로 설치되는 모든 Linux 애플리케이션 (Wayland/XWayland)│
├──────────────────────────────────────────────────────────────────────┤
│ 하그라 셸     hagra-shell: 패널 · 실행 메뉴 · 트레이 · 알림 · 창 전환   │
│ 공용 라이브러리 libhagraui (QML 디자인 시스템) · libhagralayershell (layer-shell)│
├──────────────────────────────────────────────────────────────────────┤
│ 세션          greetd → hagra-session → labwc(컴포지터) + hagra-shell   │
│               systemd --user, dbus-user-session, xdg-desktop-portal(후순위)│
├──────────────────────────────────────────────────────────────────────┤
│ 시스템 서비스  systemd · logind · D-Bus · NetworkManager · PipeWire     │
│               polkit · udisks2 · UPower · hagra-settingsd (Rust, M4)   │
├──────────────────────────────────────────────────────────────────────┤
│ 기반          Debian Stable 패키지 · Linux 커널 · Mesa · APT           │
└──────────────────────────────────────────────────────────────────────┘
```

하그라는 Debian의 패키지·커널·드라이버·보안 업데이트를 그대로 사용하고, **세션 계층 위**를
독자적으로 구현한다. 커널이나 glibc를 포크하지 않으며, Debian과의 바이너리 호환을 유지한다.

## 2. 컴포넌트

### 2.1 세션 계층

| 컴포넌트 | 구현 | 역할 |
|---|---|---|
| `greetd` | Debian 패키지 | 로그인 관리자. 개발 이미지에서는 `hagra` 사용자로 자동 로그인. M8에서 하그라 그리터(greetd IPC 클라이언트)로 프런트엔드 교체. |
| `hagra-session` | POSIX sh (`session/bin/`) | 세션 환경변수 설정(`XDG_CURRENT_DESKTOP=HAGRA`, `QT_QPA_PLATFORM=wayland`), 세션 D-Bus 확보, `labwc` 실행. 종료 시 정리. |
| `labwc` | Debian 패키지 (wlroots) | 컴포지터·창 관리자. 설정은 `/etc/hagra/labwc/`(시스템) → `~/.config/hagra/labwc/`(사용자) 순으로 적용. 하그라 테마(각진 창, 1px 테두리) 적용. |
| `hagra-shell` | C++/Qt6/QML (`shell/`) | 데스크톱 셸. labwc의 `autostart`에서 실행. 패널은 `wlr-layer-shell`로 화면 하단에 고정되고 exclusive zone을 확보한다. |

**왜 labwc인가.** wlroots 기반으로 작고(≈ 10 MB RSS), Openbox 호환 XML 설정으로 창 동작을 세밀하게
제어할 수 있으며, 셸 구현에 필요한 프로토콜(layer-shell, foreign-toplevel-management, output-management,
screencopy, virtual-keyboard)을 모두 노출한다. 서버 측 창 장식(SSD)을 제공하므로 각진 하그라 스타일 창 테두리를
컴포지터 테마만으로 일관되게 적용할 수 있다. 자체 컴포지터는 M8 이후 wlroots 또는 smithay 기반으로 평가한다.

### 2.2 하그라 셸 (`shell/`)

단일 프로세스 `hagra-shell`. QML 엔진 하나에 여러 최상위 창(layer-shell)을 둔다. (2026-10-26 P1~P4 기준)

```
hagra-shell
├── Panel ×N (layer-shell bottom|top, exclusive, 출력마다 하나)  ─ 시작 · 창 목록(우클릭 메뉴) · 표시기(네트워크·소리·배터리·알림) · 시계 · 전원
├── Launcher (overlay, keyboard)                 ─ 검색(초성·영문) · 앱/즐겨찾기/시스템 탭 · 설정·전원 버튼
├── PowerMenu · CalendarPopup · AudioPopup · TaskMenu · NotificationCenter (overlay)
├── NotificationPopups (overlay, 위치 설정)       ─ 알림 카드 최대 3장
├── AppearanceWindow (일반 창; hagra-settings 가 없을 때만 대체)
└── C++ 백엔드
    ├── AppIndex            .desktop 스캔·검색·실행 (foot 는 테마 팔레트 foot.ini 로)
    ├── AppIconProvider     image://appicon/<Icon=> (아이콘 테마·pixmaps)
    ├── LauncherState       즐겨찾기(launcher.conf)·최근(launcher-recent.conf)
    ├── ToplevelModel       wlr-foreign-toplevel-management → 창 목록·활성화·최소화·최대화·닫기
    ├── NotificationServer  org.freedesktop.Notifications (D-Bus) + 알림 모델, notifications.conf 감시
    ├── SystemStatus        /proc·/sys 폴링(5 s): 기본 경로·Wi-Fi 신호·배터리, wpctl/pactl 볼륨
    ├── Power               org.freedesktop.login1 → PowerOff/Reboot/Suspend, labwc --exit
    ├── ShellIpc            단일 인스턴스 소켓: --toggle-launcher --power --settings [page] --notifications --calendar --audio --quit
    └── ThemeManager(libs/hagratheme) · ConfFile(settings/src 공유: panel.conf)
```

- 상태 관리: QML은 뷰만 담당하고 상태는 C++ 모델에 둔다. 설정 파일은 `~/.config/hagra/*.conf` 를 감시해 다른 프로세스(설정 앱·CLI)의 변경을 따라간다.
- 측정(헤드리스 소프트웨어 렌더링, 2026-10-26): 유휴 CPU 0.03 %, RSS 68 MiB (`tests/shell/measure_idle.sh`). 목표 60 MB 는 소프트웨어 렌더러에서 약간 넘는다.
- 렌더링: Qt Quick RHI(OpenGL ES) 기본, GPU가 없는 환경(QEMU TCG)은 `QT_QUICK_BACKEND=software`.
- 설정 앱 `hagra-settings` (`settings/`): 목차 + 11 페이지, 백엔드(Display=wlr-randr, Sound=wpctl/pactl, Input=rc.xml 렌더링, Locale, Network=nmcli/QNetworkInterface, Power=logind, Notify=D-Bus, Wallpapers, SystemInfo). `--apply` 는 autostart 가, `--render-session` 은 hagra-session 이 호출한다.

### 2.3 libhagralayershell (`libs/hagralayershell/`)

Qt 6 창을 `zwlr_layer_shell_v1` 표면으로 만드는 작은 라이브러리.

- Qt 공개 API만 사용: `QWaylandClientExtensionTemplate`로 `zwlr_layer_shell_v1` 글로벌을 바인딩하고,
  `QT_WAYLAND_USE_BYPASSWINDOWMANAGERHINT=1` + `Qt::BypassWindowManagerHint`로 Qt가 xdg_toplevel 역할을
  부여하지 않도록 한 뒤 `wl_surface`에 layer_surface 역할을 직접 부여한다.
- `configure` 이벤트 → `ack_configure` → `QWindow::resize` 순서로 Qt 렌더링 전에 크기를 확정한다.
- QML API: `LayerSurface { layer: Bottom; anchors: Left|Right|Bottom; exclusiveZone: 28; keyboardInteractivity: ... }`
- KDE layer-shell-qt를 쓰지 않는 이유: Qt6 버전이 Ubuntu 24.04에 없고(Qt5판만), Plasma 릴리스 주기에 종속된다.
  대신 이 라이브러리는 ≈400줄로 유지보수 가능하고 Qt 비공개 헤더를 쓰지 않아 Qt 6.4~6.8에서 동일하게 동작한다.
  (대안: Qt 비공개 shell-integration 플러그인. 비공개 ABI에 묶이므로 채택하지 않음.)

### 2.4 HagraUI (`libs/hagraui/`)

QML 모듈 `HagraUI`. 모든 하그라 애플리케이션이 공유하는 디자인 시스템.

- `Theme` 싱글톤: 색상 토큰(`bg`, `surface`, `border`, `text`, `accent` …), 치수(`unit=4px`, `panelHeight=28`), 폰트.
- 컨트롤: `MButton`, `MMenu`, `MListView`, `MTextField`, `MTitleBar`, `MSeparator` — 각진 모서리, 1px 테두리, 애니메이션 없음.
- 테마 소스: `/etc/hagra/theme.conf` → `~/.config/hagra/theme.conf` (M4부터 `hagra-settingsd`가 D-Bus로 변경 알림).
  H2(2026-10-26): `libs/hagratheme` `ThemeManager` 가 이 파일(`[appearance] theme=`)을 읽고 쓰며, 테마 팩은 `/usr/share/hagra/themes/<id>/`. 변경 알림은 D-Bus 전까지 파일 감시. `docs/UI_FOUNDATION.md` §7.

### 2.5 시스템 애플리케이션

| 앱 | 언어 | 핵심 백엔드 |
|---|---|---|
| 하그라 파일 | C++/Qt6/QML | QAbstractItemModel, 작업 큐 스레드, udisks2(D-Bus), 휴지통 spec |
| 하그라 브라우저 (`browser/`) | C++/Qt6/QML + Qt WebEngine | WebEngineView(탭마다 하나)·WebEngineProfile(영구 쿠키·디스크 캐시 `~/.local/share/hagra/browser`), 단일 인스턴스 소켓, `org.freedesktop.Notifications`, `hagra-mimeapps.list`(기본 http/https 처리기) |
| 하그라 설정 | C++/Qt6/QML + `hagra-settingsd`(Rust) | wlr-output-management, PipeWire, NetworkManager, logind |
| 하그라 터미널 | C++/Qt6 | libvterm, QQuickPaintedItem, pty(forkpty) |
| 하그라 설치기 | Rust 백엔드 + Qt6/QML 프런트엔드 | sfdisk/libparted, mkfs, unsquashfs, grub-install, systemd-firstboot |

### 2.6 설정 시스템

- 시스템 기본값 `/etc/hagra/*.conf`, 사용자 재정의 `~/.config/hagra/*.conf` (INI, QSettings 호환).
- M4부터 `hagra-settingsd`(Rust, `org.hagra.Settings` D-Bus)가 읽기/쓰기/변경 알림의 단일 진입점.
  Qt 앱은 `HagraUI.Theme`를 통해 자동 반영.

## 3. 부팅 경험

```
펌웨어 → GRUB(UEFI/BIOS, 하그라 테마) → 커널 + initramfs
  ├─ 개발/라이브 ISO: live-boot → squashfs + overlay(tmpfs) → systemd
  └─ 설치된 시스템:  ext4 루트 → systemd
systemd → (plymouth 없음, 조용한 콘솔) → greetd.service → hagra-session → labwc → hagra-shell
```

- 부팅 중 커널 메시지는 `quiet loglevel=3`, 콘솔 로고 없음. 부팅 애니메이션은 넣지 않는다(최소 애니메이션 원칙).
- 종료/재부팅: 셸 → logind D-Bus. logind가 세션을 종료하고 systemd가 전원 상태를 바꾼다.

## 3.1 아키텍처

x86-64(PC)와 ARM64(Android/Termux QEMU)를 같은 코드로 지원한다. 차이는 이미지 빌드와 QEMU 실행 옵션에만 있다.
`docs/ARM64_ARCHITECTURE.md` 참고.

## 4. 이미지 빌드 파이프라인 (`image/`)

```
build.sh
 1. mmdebstrap  --variant=minbase  SUITE  rootfs/  MIRROR   (packages.base + packages.desktop)
 2. overlay     session/ , 설정 파일, 사용자 hagra 생성, greetd 자동 로그인, 호스트명
 3. in-target   하그라 컴포넌트 빌드: chroot에 소스 bind-mount → build-deps 설치 → cmake → install → build-deps 제거
 4. cleanup     apt 캐시·로그·machine-id 제거
 5. squashfs    rootfs → live/filesystem.squashfs (zstd)
 6. ISO         GRUB(BIOS: i386-pc, UEFI: x86_64-efi) + live/vmlinuz, initrd → xorriso hybrid ISO
```

- 대상 프로필(`image/config/suites/*.conf`)로 미러·스위트·커널 패키지 이름을 분리하므로 Debian trixie와
  Ubuntu noble을 같은 파이프라인으로 빌드할 수 있다 (후자는 Debian 미러가 차단된 CI 환경을 위한 검증 경로).
- 모든 단계는 호스트의 디스크·부트로더를 건드리지 않는다. loop 장치도 쓰지 않는다 (squashfs + xorriso만 사용).

## 5. 테스트 전략

| 수준 | 대상 | 방법 |
|---|---|---|
| 단위 | C++ 모델(AppIndex, .desktop 파서), Rust 데몬 | Qt Test / cargo test |
| 통합(셸) | 하그라 셸 + labwc | 헤드리스 labwc(`WLR_BACKENDS=headless`, `WLR_RENDERER=pixman`)에서 셸 실행 → `grim` 스크린샷 → 패널 픽셀 검사, layer-shell 로그 확인 |
| 시스템 | 부팅 이미지 | QEMU 시리얼 콘솔을 `pexpect`로 구동: 부팅 → greetd/labwc/hagra-shell 유닛·프로세스 확인 → `systemctl poweroff` → 재부팅 |
| 설치 | 하그라 설치기 | QEMU 가상 디스크에 설치 → 디스크에서 재부팅 → 세션 확인 |

## 6. 보안·권한 모델 (요약)

- 일반 사용자 세션, `sudo` 그룹. 전원·마운트·네트워크 변경은 polkit 규칙으로 로컬 활성 세션에 허용.
- 설치기 백엔드만 root로 동작하며 프런트엔드와 분리된다.
- 개발 이미지에만 비밀번호 없는 자동 로그인을 둔다. 설치된 시스템은 greetd 로그인 필수.
