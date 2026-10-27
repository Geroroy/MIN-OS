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
# 사용자 설정 디렉터리 골격. 중간 디렉터리(.local 등)도 하나씩 만들어 소유자를 hagra 로 둔다
# (install -d 가 만드는 상위 디렉터리는 root 소유가 되어 ~/.local/share 를 만들 수 없게 된다)
for d in .config .config/hagra .local .local/share .local/state .local/state/hagra .cache; do
  install -d -o hagra -g hagra -m 755 "/home/hagra/$d"
done
