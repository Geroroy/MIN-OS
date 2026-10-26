#!/bin/bash
# 커널 설치 및 live-boot initramfs 생성 (KERNEL_PKGS 는 build.sh 가 환경으로 전달)
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
echo "== installing kernel: $HAGRA_KERNEL_PKGS"
[ -n "$(ls /var/lib/apt/lists 2>/dev/null)" ] || apt-get update >/tmp/hagra-apt-update.log 2>&1
apt-get install -y --no-install-recommends $HAGRA_KERNEL_PKGS >/tmp/hagra-kernel.log 2>&1 || { tail -30 /tmp/hagra-kernel.log; exit 1; }

KVER=$(ls /lib/modules | sort -V | tail -1)
echo "   kernel $KVER"

# Ubuntu: linux-image-virtual 에는 가상 GPU(virtio-gpu, bochs)·virtio 입력 DRM/HID 모듈이 빠져 있을 수 있다 → modules-extra 보충
if [ "${HAGRA_SUITE:-}" = "noble" ]; then
  if ! find /lib/modules/"$KVER" \( -name 'virtio-gpu.ko*' -o -name 'virtio_input.ko*' \) | wc -l | grep -q '^2$'; then
    echo "   adding linux-modules-extra-$KVER (virtio-gpu/bochs drm, virtio-input)"
    apt-get install -y --no-install-recommends "linux-modules-extra-$KVER" >>/tmp/hagra-kernel.log 2>&1 || { tail -20 /tmp/hagra-kernel.log; exit 1; }
  fi
fi
for m in virtio-gpu virtio_input virtio_blk virtio_net; do
  find /lib/modules/"$KVER" -name "$m.ko*" | grep -q . && echo "   module ok: $m" || echo "   module MISSING (may be built-in): $m"
done

# live-boot 이 initramfs 에 포함되도록 재생성
update-initramfs -u -k "$KVER" >/tmp/hagra-initramfs.log 2>&1 || { tail -30 /tmp/hagra-initramfs.log; exit 1; }
ls -la /boot/vmlinuz-"$KVER" /boot/initrd.img-"$KVER"
# ISO 조립 단계에서 쓰기 쉽게 고정 이름 링크
ln -sf vmlinuz-"$KVER" /boot/vmlinuz
ln -sf initrd.img-"$KVER" /boot/initrd.img
