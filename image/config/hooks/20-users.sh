#!/bin/bash
# 사용자 계정. 개발 이미지: min/min (sudo), root/minos
set -euo pipefail
if ! id min >/dev/null 2>&1; then
  useradd -m -u 1000 -s /bin/bash -c "MIN User" min
fi
for g in sudo video audio input render plugdev netdev; do
  getent group "$g" >/dev/null && usermod -aG "$g" min || true
done
echo 'min:min' | chpasswd
echo 'root:minos' | chpasswd
# 사용자 설정 디렉터리 골격
install -d -o min -g min /home/min/.config/minos /home/min/.local/state/minos
