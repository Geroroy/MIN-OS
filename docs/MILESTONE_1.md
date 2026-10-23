# M1 — QEMU에서 부팅되는 MIN OS 개발용 이미지

## 1. 목표

| 요구사항 | 구현 방식 | 검증 |
|---|---|---|
| Debian 기반 부팅 | `mmdebstrap`으로 Debian trixie minbase rootfs → squashfs → `live-boot` initramfs → GRUB hybrid ISO(BIOS+UEFI) | QEMU(OVMF)에서 GRUB 메뉴 → systemd 부팅 완료(`systemctl is-system-running`) |
| Wayland 세션 실행 | `greetd` 자동 로그인 → `minos-session` | `loginctl` 세션 Type=wayland, `$WAYLAND_DISPLAY` 소켓 존재 |
| Labwc 실행 | `/etc/minos/labwc/rc.xml` + MIN 테마 | `pgrep labwc`, 로그에 backend/renderer 기록 |
| MIN OS 전용 데스크톱 화면 | swaybg(단색 Graphite + MIN 워드마크) + MIN Shell 패널 | QEMU `screendump` → 하단 28px 패널 영역 픽셀 검사 |
| 기본 작업 표시줄 | `minos-shell` 패널(layer-shell bottom, exclusive zone 28): `MIN` 시작 버튼 · 창 목록 · 시계 · 전원 | 헤드리스 labwc 통합 테스트 + 스크린샷 |
| 애플리케이션 실행 기능 | `.desktop` 스캔(AppIndex) → 실행 메뉴(검색·Enter) → `QProcess::startDetached` | 테스트: 실행 메뉴에서 foot 실행 후 `pgrep foot` |
| 터미널 실행 | foot + `/etc/xdg/foot/foot.ini`(MIN 테마), 패널 버튼·`Super+Enter` | 위와 동일 |
| 정상적인 종료 및 재부팅 | 패널 전원 메뉴 → `org.freedesktop.login1.Manager.PowerOff/Reboot` | 시리얼 콘솔에서 `systemctl poweroff` → QEMU 종료; `reboot` → 두 번째 부팅 확인 |

## 2. 구성 요소와 파일

```
session/
  bin/minos-session          세션 진입점 (환경 설정 → labwc)
  labwc/rc.xml               키바인드, 창 동작, 테마 이름(MIN)
  labwc/menu.xml             우클릭 메뉴 (터미널, 실행 메뉴, 종료)
  labwc/autostart            swaybg, minos-shell
  labwc/environment          XDG_CURRENT_DESKTOP 등
  themes/MIN/openbox-3/themerc   각진 창 테두리 테마
  greetd/config.toml         자동 로그인(min) → minos-session
  foot/foot.ini              MIN Graphite 색상
  wallpaper/min-graphite.png 배경
  minos.desktop              /usr/share/wayland-sessions/ 세션 항목
libs/minlayershell/          Qt6 layer-shell (LayerWindow QML 타입)
libs/minui/                  MinUI QML 모듈 (Theme, MButton …)
shell/                       minos-shell (Panel.qml, Launcher.qml, AppIndex, Power, 단일 인스턴스 IPC)
image/                       빌드 파이프라인 · GRUB 설정 · QEMU 스크립트
tests/shell/run.sh           헤드리스 labwc + minos-shell + grim 스크린샷 검사
tests/image/boot_test.py     pexpect로 QEMU 시리얼 콘솔 구동
```

## 3. 구현 순서

1. **libminlayershell** — `zwlr_layer_shell_v1` 바인딩, `LayerWindow`(QQuickWindow 파생) 구현. 헤드리스 labwc에서 단색 패널이 하단에 고정되는지 확인.
2. **MinUI** — Theme 싱글톤 + 최소 컨트롤.
3. **minos-shell** — Panel, Launcher, AppIndex, Power, Clock, 단일 인스턴스 IPC(`--toggle-launcher`). 헤드리스 테스트 통과.
4. **session/** — labwc 설정·테마·greetd·foot 설정. 호스트에서 헤드리스로 `minos-session` 실행 검증.
5. **image/build.sh** — rootfs → 오버레이 → in-target 빌드 → squashfs → ISO. `ubuntu-noble` 프로필로 샌드박스에서 검증, `debian-trixie` 프로필은 Debian 미러가 있는 PC에서 검증.
6. **tests/image/boot_test.py** — 부팅 → 세션 확인 → 종료 → 재부팅.
7. 결과를 DEVELOPMENT_PLAN.md의 M1 표에 기록.

## 4. 빌드 및 실행

```sh
sudo scripts/install-deps.sh          # 1회
make shell && make test-shell         # 셸 호스트 빌드 + 헤드리스 통합 테스트
sudo make image                       # Debian trixie ISO → out/minos-dev-debian-trixie-amd64.iso
sudo make image SUITE=ubuntu-noble    # Debian 미러가 없는 환경
make run                              # QEMU GUI (KVM 있으면 자동)
make run-serial                       # 시리얼 콘솔(GRUB 메뉴도 시리얼로 출력)
sudo make test-image                  # 자동 부팅/종료/재부팅 테스트
```

QEMU 안의 세션에서는 `Super+Enter`로 터미널, `Super`로 실행 메뉴, 패널 오른쪽 `⏻`로 종료/재부팅.
시리얼 콘솔(`ttyS0`)에는 `root` 자동 로그인 셸이 열려 있어 디버깅에 사용한다(개발 이미지 한정).

## 5. 소프트웨어 렌더링

GPU가 없는 QEMU(TCG) 환경에서는 `minos-session`이 다음을 적용한다.

- 커널 명령행에 `minos.render=software`가 있거나 `/dev/dri/renderD*`가 없으면 `WLR_RENDERER=pixman`, `QT_QUICK_BACKEND=software`.
- GRUB 메뉴의 두 번째 항목 "MIN OS (software rendering)"이 이 옵션을 켠다. 세 번째 항목은 시리얼 디버그용.

## 6. 알려진 제약 (M1 범위)

- 시스템 트레이·알림·창 전환 오버레이는 M2. M1 패널의 창 목록은 `wlr-foreign-toplevel-management`로 표시·활성화만 지원한다.
- 터미널은 foot. MIN Terminal은 M5.
- 로그인 화면 없음(자동 로그인). MIN Greeter는 M8.
- 네트워크 설정 UI 없음. NetworkManager가 DHCP로 자동 연결한다.
