#!/usr/bin/env bash
# MIN OS — Termux 에 QEMU(ARM64 시스템 에뮬레이터)와 필요한 도구를 설치한다.
#   bash install-termux.sh [-y]
# 이 스크립트는 사용자가 직접 실행할 때만 패키지를 설치하며, Android 설정이나 다른 앱의 파일은 건드리지 않는다.
set -euo pipefail
YES=0; [ "${1:-}" = "-y" ] && YES=1
[ -n "${PREFIX:-}" ] && [ -d "$PREFIX" ] || { echo "Termux 환경이 아닌 것 같습니다 (PREFIX 없음). Termux 앱 안에서 실행하십시오." >&2; exit 1; }
command -v pkg >/dev/null || { echo "pkg 명령이 없습니다." >&2; exit 1; }

PKGS="qemu-system-aarch64-headless qemu-utils socat"
OPTIONAL="ovmf"   # UEFI 펌웨어 (선택: --uefi 부팅에만 필요)
echo "설치할 패키지: $PKGS"
echo "선택 패키지:   $OPTIONAL (UEFI 부팅용)"
if [ "$YES" != 1 ]; then
  printf '계속할까요? [y/N] '; read -r a; [ "$a" = y ] || [ "$a" = Y ] || { echo "취소"; exit 0; }
fi
pkg update -y
# shellcheck disable=SC2086
pkg install -y $PKGS
pkg install -y $OPTIONAL || echo "(ovmf 설치 실패 — UEFI 부팅은 사용할 수 없지만 직접 커널 부팅은 가능합니다)"
echo
echo "== 설치 확인"
qemu-system-aarch64 --version | head -1
qemu-img --version | head -1
echo "== 다음 단계"
echo "1. PC 에서 만든 번들 디렉터리(out/minos-arm64/)를 휴대폰으로 복사합니다 (docs/ANDROID_EMULATION.md 참고)."
echo "2. cd <번들 디렉터리> && bash start-minos.sh"
echo "3. Android VNC 클라이언트로 127.0.0.1:5900 에 연결합니다."
