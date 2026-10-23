#!/bin/bash
# 커널 설치 및 live-boot initramfs 생성 (KERNEL_PKGS 는 build.sh 가 환경으로 전달)
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
echo "== installing kernel: $MINOS_KERNEL_PKGS"
[ -n "$(ls /var/lib/apt/lists 2>/dev/null)" ] || apt-get update >/tmp/minos-apt-update.log 2>&1
apt-get install -y --no-install-recommends $MINOS_KERNEL_PKGS >/tmp/minos-kernel.log 2>&1 || { tail -30 /tmp/minos-kernel.log; exit 1; }

KVER=$(ls /lib/modules | sort -V | tail -1)
echo "   kernel $KVER"

# Ubuntu: linux-image-virtual 에는 가상 GPU(virtio-gpu, bochs) DRM 모듈이 빠져 있을 수 있다 → modules-extra 보충
if [ "${MINOS_SUITE:-}" = "noble" ]; then
  if ! find /lib/modules/"$KVER" -name 'virtio-gpu.ko*' | grep -q .; then
    echo "   adding linux-modules-extra-$KVER (virtio-gpu/bochs drm)"
    apt-get install -y --no-install-recommends "linux-modules-extra-$KVER" >>/tmp/minos-kernel.log 2>&1 || { tail -20 /tmp/minos-kernel.log; exit 1; }
  fi
fi

# live-boot 이 initramfs 에 포함되도록 재생성
update-initramfs -u -k "$KVER" >/tmp/minos-initramfs.log 2>&1 || { tail -30 /tmp/minos-initramfs.log; exit 1; }
ls -la /boot/vmlinuz-"$KVER" /boot/initrd.img-"$KVER"
# ISO 조립 단계에서 쓰기 쉽게 고정 이름 링크
ln -sf vmlinuz-"$KVER" /boot/vmlinuz
ln -sf initrd.img-"$KVER" /boot/initrd.img
