#!/bin/bash
# 사용자 계정. 개발 이미지: hagra/hagra (sudo), root/hagra
set -euo pipefail
if ! id hagra >/dev/null 2>&1; then
  useradd -m -u 1000 -s /bin/bash -c "HAGRA User" hagra
fi
for g in sudo video audio input render plugdev netdev; do
  getent group "$g" >/dev/null && usermod -aG "$g" hagra || true
done
echo 'hagra:hagra' | chpasswd
echo 'root:hagra' | chpasswd
# 사용자 설정 디렉터리 골격
install -d -o hagra -g hagra /home/hagra/.config/hagra /home/hagra/.local/state/hagra
