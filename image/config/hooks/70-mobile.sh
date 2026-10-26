#!/bin/bash
# 모바일(Termux QEMU, TCG) 프로필: 불필요한 서비스·타이머 제거, 저널 메모리 상주, 부팅 대기 단축
set -euo pipefail
[ "${HAGRA_PROFILE:-default}" = mobile ] || exit 0
echo "== applying mobile profile"
for u in apt-daily.timer apt-daily-upgrade.timer man-db.timer e2scrub_all.timer fstrim.timer motd-news.timer \
         dpkg-db-backup.timer systemd-tmpfiles-clean.timer logrotate.timer ua-timer.timer \
         NetworkManager-wait-online.service systemd-networkd-wait-online.service ModemManager.service \
         e2scrub_reap.service; do
  systemctl mask "$u" >/dev/null 2>&1 || true
done
mkdir -p /etc/systemd/journald.conf.d
cat > /etc/systemd/journald.conf.d/hagra-mobile.conf <<'J'
[Journal]
Storage=volatile
RuntimeMaxUse=16M
J
mkdir -p /etc/systemd/system.conf.d
cat > /etc/systemd/system.conf.d/hagra-mobile.conf <<'S'
[Manager]
DefaultTimeoutStopSec=10s
S
# 세션에서 XWayland 자동 시작 안 함 (labwc는 필요 시 lazy 시작) — 메모리 절약
mkdir -p /etc/hagra
echo 'HAGRA_PROFILE=mobile' > /etc/hagra/profile
