# 하그라 설치·빌드 안내

## 1. 라이브 ISO / ARM64 번들

- **x86-64 PC**: `sudo make image` → `out/hagra-dev-<suite>-amd64.iso` (hybrid ISO, UEFI+BIOS). USB 에 `dd` 하거나 `make run` 으로 QEMU 에서 실행.
  라이브 매체는 홈 디렉터리가 휘발성이라 설정이 재부팅 후 남지 않는다. 설치기(M6)는 아직 없다.
- **Android/Termux (ARM64)**: `android/install-termux.sh` 가 GitHub Release `android-latest` 의 `hagra-android-arm64.tar.zst` 를 받아 QEMU 로 실행한다 (`docs/ANDROID_EMULATION.md`). 설정은 qcow2 디스크에 남는다.
- 기본 계정 `hagra` / 비밀번호 `hagra` (개발 이미지, 자동 로그인). root `hagra`.

## 1.1 Windows 에서 실행 (VirtualBox 또는 Hyper-V)

GitHub Actions 가 x86-64 ISO 를 빌드하고 QEMU 부팅 테스트를 통과하면 Release **`pc-latest`** 에 `hagra-pc-amd64.iso` 를 올린다.
https://github.com/Geroroy/MIN-OS/releases/tag/pc-latest 에서 ISO 를 내려받는다 (≈ 550 MB). 라이브 ISO 라 가상 디스크는 필요 없고, 끄면 변경이 사라진다.

> VirtualBox·Hyper-V·VMware 에서는 아직 직접 시험하지 않았다 (CI 는 QEMU 의 virtio·표준 VGA 그래픽으로만 시험). 이미지에는 각 가상 머신의
> 디스플레이 드라이버(VirtualBox/VMware: `vmwgfx`, Hyper-V: `hyperv_drm`)가 들어 있다.

**A. VirtualBox (권장)** — https://www.virtualbox.org 에서 Windows hosts 설치 (관리자 권한 필요)
1. 새로 만들기 → 이름 `HAGRA`, ISO 이미지 = 내려받은 ISO, 종류 Linux / 버전 Ubuntu (64-bit), **무인 설치 건너뛰기** 체크.
2. 하드웨어: 메모리 **4096 MB** (최소 2048), 프로세서 **2개 이상**, **EFI 사용** 체크.
3. 하드 디스크: **가상 하드 디스크를 추가하지 않음**.
4. 만든 뒤 설정 → 디스플레이: 그래픽 컨트롤러 **VMSVGA**, 비디오 메모리 **128 MB**, 3D 가속 끔.
5. 시작 → GRUB 메뉴에서 첫 항목(기본) → 1~2분 뒤 하그라 바탕 화면 (자동 로그인).
- 화면이 검게 남으면: 디스플레이 그래픽 컨트롤러를 VBoxSVGA → VBoxVGA 순으로 바꿔 본다. EFI 를 끄고(BIOS) 부팅해 본다.
- Windows 에서 Hyper-V·WSL2 가 켜져 있으면 VirtualBox 가 느린 모드(상태 표시줄의 거북이 아이콘)로 돈다. 동작은 한다.

**B. Hyper-V (Windows Education/Pro 에 내장, 별도 설치 없음)**
1. "Windows 기능 켜기/끄기" → **Hyper-V** 체크 → 재부팅 (관리자 권한 필요).
2. Hyper-V 관리자 → 새로 만들기 → 가상 컴퓨터: **2세대**, 메모리 4096 MB (**동적 메모리 끔**), 네트워크 Default Switch,
   **가상 하드 디스크를 나중에 연결**, 설치 옵션 = **부팅 가능한 이미지 파일(ISO)** 에 내려받은 ISO.
3. 만든 가상 머신의 설정 → 보안 → **보안 부팅 사용 해제** (하그라의 GRUB 은 서명되지 않았다). 프로세서 2개 이상.
4. 연결 → 시작.

**키보드**: Super(Windows) 키 조합은 Windows 가 먼저 가로챌 수 있다. 실행 메뉴는 왼쪽 아래 **하그라** 단추, 보그라는 실행 메뉴 즐겨찾기 첫 칸으로 연다.

## 2. 호스트에서 빌드 (Ubuntu 24.04 / Debian 13)

```sh
sudo scripts/install-deps.sh      # Qt 6, labwc, wayland, cmake/ninja, python3-pil, grim, wlr-randr …
make shell                        # build/ 에 hagra-shell · hagra-settings · hagra-theme · hagra-preview · 테마 팩 · 번역
make test                         # 토큰·대비 검사 + ctest(5 묶음) + 헤드리스 셸 통합 테스트
```

설치 (패키지 없이): `sudo cmake --install build` 는 바이너리·QML 모듈·테마·번역·설정 .desktop 을 `/usr` 에 넣는다. 세션 파일은 `image/config/hooks/30-hagra-install.sh` 와 같은 배치로 직접 복사한다 (`debian/rules` 참고).

## 3. Debian 패키지 (`hagra-desktop`)

```sh
sudo apt install debhelper dh-cmake   # + Build-Depends (debian/control)
dpkg-buildpackage -us -uc -b          # ../hagra-desktop_0.1.0~rc1_<arch>.deb
sudo apt install ../hagra-desktop_*.deb
```

패키지는 바이너리·QML·테마·번역·세션 스크립트·labwc 설정·foot 설정·wayland-sessions 항목을 설치한다. greetd 설정(`session/greetd/config.toml`)은 자동 로그인 개발용이라 패키지에 포함하지 않는다.

## 4. 되돌리기 (rollback)

| 범위 | 방법 |
|---|---|
| 사용자 설정 전체 | `rm -rf ~/.config/hagra ~/.local/state/hagra` → 다음 로그인에 기본값 |
| 테마만 | `hagra-theme reset` |
| labwc 재정의 | `~/.config/hagra/labwc/` 삭제 후 Super+Shift+R |
| 패키지 | `sudo apt remove hagra-desktop` (설정 파일은 `/etc/hagra` 에 남음; `purge` 로 제거). 이전 .deb 가 있으면 `sudo apt install ./hagra-desktop_<old>.deb` |
| 라이브 ISO | 재부팅하면 모든 변경이 사라진다 |

## 5. 이미지 안에서 바뀌는 것 (이번 릴리스)

`image/config/packages.desktop` 에 fcitx5(+hangul, qt6/gtk3 프런트엔드)와 `locales` 가, `packages.build` 에 `qt6-tools-dev qt6-l10n-tools` (번역 빌드)가 추가됐다. 전체 이미지 재빌드가 필요하다.
