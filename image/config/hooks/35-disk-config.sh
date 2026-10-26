#!/bin/bash
# 디스크 이미지(--format disk) 전용 설정: fstab, 루트 파일시스템 레이블 기반 부팅
set -euo pipefail
[ "${HAGRA_FORMAT:-iso}" = disk ] || exit 0
cat > /etc/fstab <<'F'
# 하그라 — 루트는 레이블로 식별 (QEMU virtio: /dev/vda2, 실제 PC: 설치기가 갱신)
LABEL=hagra-root  /          ext4  defaults,noatime,errors=remount-ro  0  1
# ESP는 필요할 때만 수동 마운트
LABEL=HAGRA-ESP   /boot/efi  vfat  defaults,noauto                      0  0
F
mkdir -p /boot/efi
