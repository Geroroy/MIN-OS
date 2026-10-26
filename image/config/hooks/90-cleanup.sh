#!/bin/bash
set -euo pipefail
apt-get clean
rm -rf /var/lib/apt/lists/* /var/cache/apt/*.bin /tmp/hagra-* /var/log/*.log /var/log/apt/* 
find /var/log -type f -exec truncate -s0 {} +
# machine-id 는 첫 부팅 때 생성
truncate -s0 /etc/machine-id
rm -f /var/lib/dbus/machine-id
ln -sf /etc/machine-id /var/lib/dbus/machine-id
# 빌드 중 쓴 resolv.conf 제거 (NetworkManager 가 관리)
rm -f /etc/resolv.conf
echo "== rootfs size: $(du -sh / 2>/dev/null | cut -f1)"
