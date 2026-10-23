#!/bin/bash
# 개발 이미지 전용: 시리얼 콘솔(ttyS0) root 자동 로그인 — 디버깅/자동 테스트용. 릴리스 이미지에서는 제외.
set -euo pipefail
[ "${MINOS_DEV:-0}" = 1 ] || exit 0
mkdir -p /etc/systemd/system/serial-getty@ttyS0.service.d
cat > /etc/systemd/system/serial-getty@ttyS0.service.d/autologin.conf <<'U'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin root --keep-baud 115200,57600,38400,9600 - $TERM
U
# 자동 테스트가 프롬프트를 식별하기 쉽도록
echo 'PS1="minos# "' >> /root/.bashrc
