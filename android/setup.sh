#!/usr/bin/env bash
# MIN OS — Termux 원클릭 설치·실행
#
#   curl -fsSL https://raw.githubusercontent.com/Geroroy/MIN-OS/ccr-0dc4d66d-j60c3m/android/setup.sh | bash
#
# 하는 일 (사용자가 이 명령을 직접 실행했을 때만):
#   1. Termux 패키지 설치: qemu-system-aarch64-headless qemu-utils socat zstd
#   2. GitHub Release(android-latest)에서 MIN OS ARM64 번들(≈ 450 MB) 다운로드, sha256 확인, ~/minos-arm64 에 풀기
#   3. 'minos' 명령 설치 ($PREFIX/bin/minos)
#   4. MIN OS 실행 → VNC 앱 자동 열기 (vnc://127.0.0.1:5900)
# 이미 설치되어 있으면 다운로드를 건너뛰고 바로 실행한다. 새 이미지로 바꾸려면: bash setup.sh --update (가상 디스크 변경 사항이 사라짐)
# Android 설정이나 다른 앱의 파일은 변경하지 않는다. 설치 위치는 Termux 홈 디렉터리뿐이다.
set -euo pipefail

REPO=${MINOS_REPO:-Geroroy/MIN-OS}
TAG=${MINOS_TAG:-android-latest}
URL=${MINOS_URL:-https://github.com/$REPO/releases/download/$TAG/minos-android-arm64.tar.zst}
DEST=${MINOS_HOME:-$HOME/minos-arm64}
UPDATE=0; RUN=1; RUN_ARGS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --update) UPDATE=1; shift ;;
    --no-run) RUN=0; shift ;;
    --) shift; RUN_ARGS=("$@"); break ;;
    *) RUN_ARGS+=("$1"); shift ;;
  esac
done

say() { printf '\033[1m[minos]\033[0m %s\n' "$*"; }
die() { printf '\033[1;31m[minos] %s\033[0m\n' "$*" >&2; exit 1; }

# ---- 환경 확인 ----
[ -n "${PREFIX:-}" ] && [ -d "$PREFIX" ] || die "Termux 안에서 실행하십시오 (PREFIX 없음)."
case "$(uname -m)" in aarch64|arm64) ;; *) say "경고: 이 기기는 $(uname -m) 입니다. ARM64 기기를 권장합니다." ;; esac

# ---- 1. 패키지 ----
NEED=""
command -v qemu-system-aarch64 >/dev/null || NEED="$NEED qemu-system-aarch64-headless"
command -v qemu-img >/dev/null || NEED="$NEED qemu-utils"
command -v socat >/dev/null || NEED="$NEED socat"
command -v zstd >/dev/null || NEED="$NEED zstd"
command -v curl >/dev/null || NEED="$NEED curl"
if [ -n "$NEED" ]; then
  say "패키지 설치:$NEED"
  pkg update -y </dev/null || die "pkg update 실패. F-Droid/GitHub 판 Termux 인지 확인하십시오 (Play 스토어 판은 지원되지 않음)."
  # shellcheck disable=SC2086
  pkg install -y $NEED </dev/null || die "패키지 설치 실패:$NEED"
fi
qemu-system-aarch64 --version | head -1

# ---- 2. 이미지 ----
if [ -f "$DEST/minos-image.conf" ] && [ "$UPDATE" = 0 ]; then
  say "이미 설치됨: $DEST (새 이미지로 교체: --update)"
else
  FREE_MB=$(df -Pm "$HOME" | awk 'NR==2 {print $4}')
  [ "$FREE_MB" -ge 2500 ] || die "저장 공간이 부족합니다: ${FREE_MB}MB (필요 ≈ 2500MB)"
  TARBALL=$HOME/.minos-download.tar.zst
  say "다운로드: $URL"
  say "(약 450MB — 모바일 데이터 대신 Wi-Fi 를 권장합니다. 끊기면 다시 실행하면 이어받습니다.)"
  curl -fL --retry 3 -C - -o "$TARBALL" "$URL" || die "다운로드 실패. 네트워크를 확인하고 다시 실행하십시오."
  if SUM=$(curl -fsL "$URL.sha256" 2>/dev/null); then
    EXPECTED=${SUM%% *}
    ACTUAL=$(sha256sum "$TARBALL" | cut -d' ' -f1)
    [ "$EXPECTED" = "$ACTUAL" ] || { rm -f "$TARBALL"; die "체크섬 불일치 — 파일이 손상되었습니다. 다시 실행하십시오."; }
    say "체크섬 확인 완료"
  else
    say "경고: 체크섬 파일을 받지 못해 무결성 확인을 건너뜁니다."
  fi
  if [ -d "$DEST" ]; then
    [ -f "$DEST/minos-image.conf" ] || die "$DEST 가 MIN OS 번들이 아닙니다. 다른 위치를 MINOS_HOME 으로 지정하십시오."
    say "기존 설치 교체: $DEST"
    rm -rf "$DEST"
  fi
  say "압축 해제 중…"
  mkdir -p "$DEST"
  tar --zstd -xf "$TARBALL" -C "$DEST" --strip-components=1
  rm -f "$TARBALL"
  [ -f "$DEST/minos-image.conf" ] || die "번들 구조가 올바르지 않습니다."
fi

# ---- 3. 'minos' 명령 ----
cat > "$PREFIX/bin/minos" <<M
#!/usr/bin/env bash
# MIN OS 실행: minos [--res 960x540] [--mem 1536] [--smp 3] | minos --stop | minos --status
exec bash "$DEST/start-minos.sh" "\$@"
M
chmod +x "$PREFIX/bin/minos"
say "설치 완료. 다음부터는 'minos' 만 입력하면 실행됩니다 (종료: minos --stop)."

# ---- 4. 실행 ----
[ "$RUN" = 1 ] || exit 0
exec bash "$DEST/start-minos.sh" "${RUN_ARGS[@]}" </dev/null
