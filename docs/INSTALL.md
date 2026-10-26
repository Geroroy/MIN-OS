# 하그라 설치·빌드 안내

## 1. 라이브 ISO / ARM64 번들

- **x86-64 PC**: `sudo make image` → `out/hagra-dev-<suite>-amd64.iso` (hybrid ISO, UEFI+BIOS). USB 에 `dd` 하거나 `make run` 으로 QEMU 에서 실행.
  라이브 매체는 홈 디렉터리가 휘발성이라 설정이 재부팅 후 남지 않는다. 설치기(M6)는 아직 없다.
- **Android/Termux (ARM64)**: `android/install-termux.sh` 가 GitHub Release `android-latest` 의 `hagra-android-arm64.tar.zst` 를 받아 QEMU 로 실행한다 (`docs/ANDROID_EMULATION.md`). 설정은 qcow2 디스크에 남는다.
- 기본 계정 `hagra` / 비밀번호 `hagra` (개발 이미지, 자동 로그인). root `hagra`.

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
