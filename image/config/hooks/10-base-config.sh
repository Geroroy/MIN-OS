#!/bin/bash
# 기본 시스템 설정 (chroot 안에서 실행)
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

echo "hagra" > /etc/hostname
cat > /etc/hosts <<'H'
127.0.0.1   localhost
127.0.1.1   hagra
::1         localhost ip6-localhost ip6-loopback
H

# 로케일: 영어 기본 + 한국어
sed -i 's/^# *en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/; s/^# *ko_KR.UTF-8 UTF-8/ko_KR.UTF-8 UTF-8/' /etc/locale.gen
grep -q '^en_US.UTF-8' /etc/locale.gen || echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen
grep -q '^ko_KR.UTF-8' /etc/locale.gen || echo 'ko_KR.UTF-8 UTF-8' >> /etc/locale.gen
locale-gen >/dev/null
echo 'LANG=ko_KR.UTF-8' > /etc/default/locale   # 하그라 기본 UI 언어는 한국어; 설정 → 언어와 지역에서 바꾼다
ln -sf /usr/share/zoneinfo/UTC /etc/localtime
echo UTC > /etc/timezone

# 그래픽 타깃, 세션 관련 서비스
systemctl set-default graphical.target
systemctl enable greetd.service NetworkManager.service >/dev/null 2>&1 || true
# 커널 메시지로 콘솔이 어지럽혀지지 않도록
mkdir -p /etc/sysctl.d
echo 'kernel.printk = 3 3 3 3' > /etc/sysctl.d/20-hagra-quiet.conf
# live-boot 이 /etc/network/interfaces 를 쓰려고 한다 (ifupdown 없음) — 경고 방지용 빈 디렉터리
mkdir -p /etc/network
