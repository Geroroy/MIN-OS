#!/bin/sh
# MIN OS 호스트 개발 의존성 설치 (Debian 12/13, Ubuntu 24.04)
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

# Qt 6 (MIN Shell / MinUI 호스트 빌드 및 헤드리스 테스트)
PKGS="$PKGS qt6-base-dev qt6-base-dev-tools qt6-declarative-dev qt6-declarative-dev-tools
      qt6-wayland qt6-wayland-dev qt6-wayland-dev-tools qt6-svg-dev
      qml6-module-qtquick qml6-module-qtquick-controls qml6-module-qtquick-layouts
      qml6-module-qtquick-window qml6-module-qtqml qml6-module-qtqml-workerscript
      qml6-module-qtquick-templates qml6-module-qtquick-shapes qml6-module-qtcore
      libwayland-dev wayland-protocols libxkbcommon-dev libgl1-mesa-dri libegl-mesa0"

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

# shellcheck disable=SC2086
apt-get install -y --no-install-recommends $PKGS

if [ -e /dev/kvm ]; then
  echo "== KVM 사용 가능 (/dev/kvm)"
else
  echo "== 경고: /dev/kvm 없음 — QEMU는 TCG(소프트웨어 에뮬레이션)로 동작하며 느립니다."
fi
echo "== 완료"
