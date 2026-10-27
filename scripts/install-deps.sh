#!/bin/sh
# 하그라 호스트 개발 의존성 설치 (Debian 12/13, Ubuntu 24.04)
# 사용: sudo scripts/install-deps.sh [--no-qemu]
set -eu

[ "$(id -u)" -eq 0 ] || { echo "root 권한이 필요합니다: sudo $0" >&2; exit 1; }

WITH_QEMU=1
[ "${1:-}" = "--no-qemu" ] && WITH_QEMU=0

. /etc/os-release
echo "== 호스트: $PRETTY_NAME"

export DEBIAN_FRONTEND=noninteractive
apt-get update

# 공통: 빌드 도구
PKGS="build-essential cmake ninja-build pkg-config git"

# Qt 6 (하그라 셸 / HagraUI 호스트 빌드 및 헤드리스 테스트)
PKGS="$PKGS qt6-base-dev qt6-base-dev-tools qt6-declarative-dev qt6-declarative-dev-tools
      qt6-wayland qt6-wayland-dev qt6-wayland-dev-tools qt6-svg-dev qt6-tools-dev qt6-l10n-tools dbus
      qml6-module-qtquick qml6-module-qtquick-controls qml6-module-qtquick-layouts qml6-module-qttest qt6-declarative-dev-tools
      qml6-module-qtquick-window qml6-module-qtqml qml6-module-qtqml-workerscript
      qml6-module-qtquick-templates qml6-module-qtquick-shapes qml6-module-qtcore
      libwayland-dev wayland-protocols libxkbcommon-dev libgl1-mesa-dri libegl-mesa0"

# 보그라 (Qt WebEngine)
PKGS="$PKGS qt6-webengine-dev qml6-module-qtwebengine qml6-module-qtwebengine-controlsdelegates
      qml6-module-qtquick-dialogs qml6-module-qt-labs-folderlistmodel"

# Wayland 세션 컴포넌트 (헤드리스 테스트용)
PKGS="$PKGS labwc foot swaybg grim wlr-randr wl-clipboard fonts-dejavu fonts-inter
      dbus dbus-user-session"

# 이미지 빌드
PKGS="$PKGS mmdebstrap debootstrap squashfs-tools xorriso grub-pc-bin grub-efi-amd64-bin
      grub-common mtools dosfstools e2fsprogs parted rsync debian-archive-keyring ubuntu-keyring"

# 테스트
PKGS="$PKGS expect socat python3-pexpect python3-pil"

if [ "$WITH_QEMU" = 1 ]; then
  PKGS="$PKGS qemu-system-x86 qemu-utils ovmf"
fi

# ARM64 이미지(Android/Termux 대상) 교차 빌드 및 PC 에뮬레이션
PKGS="$PKGS qemu-system-arm qemu-efi-aarch64 qemu-user-static binfmt-support arch-test fdisk"

# shellcheck disable=SC2086
apt-get install -y --no-install-recommends $PKGS

# 교차 아키텍처 chroot 를 위한 binfmt_misc 등록 (컨테이너에서는 update-binfmts 가 실패할 수 있어 직접 등록)
if ! [ -e /proc/sys/fs/binfmt_misc/qemu-aarch64 ]; then
  mountpoint -q /proc/sys/fs/binfmt_misc || mount -t binfmt_misc binfmt_misc /proc/sys/fs/binfmt_misc 2>/dev/null || true
  update-binfmts --import qemu-aarch64 2>/dev/null || update-binfmts --enable qemu-aarch64 2>/dev/null || \
  printf ':qemu-aarch64:M::\\x7fELF\\x02\\x01\\x01\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x02\\x00\\xb7\\x00:\\xff\\xff\\xff\\xff\\xff\\xff\\xff\\x00\\xff\\xff\\xff\\xff\\xff\\xff\\xff\\xff\\xfe\\xff\\xff\\xff:/usr/bin/qemu-aarch64-static:POCF\n' > /proc/sys/fs/binfmt_misc/register 2>/dev/null || true
fi
[ -e /proc/sys/fs/binfmt_misc/qemu-aarch64 ] && echo "== binfmt: qemu-aarch64 등록됨 (ARM64 chroot 가능)" || echo "== 경고: qemu-aarch64 binfmt 미등록 — ARM64 이미지 빌드 불가"

if [ -e /dev/kvm ]; then
  echo "== KVM 사용 가능 (/dev/kvm)"
else
  echo "== 경고: /dev/kvm 없음 — QEMU는 TCG(소프트웨어 에뮬레이션)로 동작하며 느립니다."
fi
echo "== 완료"
