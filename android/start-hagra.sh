#!/usr/bin/env bash
# 하그라(HAGRA) — Android(Termux) 에서 QEMU ARM64 가상 머신으로 하그라를 부팅한다.
#
#   bash start-hagra.sh [옵션]
#   --mem MB        게스트 메모리 (기본 2048)
#   --smp N         vCPU 수 (기본 2)
#   --res WxH       가상 디스플레이 해상도 (기본 1280x720; 느리면 960x540 / 800x600)
#   --vnc N         VNC 디스플레이 번호 (기본 0 → 127.0.0.1:5900)
#   --cpu MODEL     QEMU CPU 모델 (기본 cortex-a76)
#   --uefi          직접 커널 부팅 대신 UEFI 펌웨어(ovmf 패키지)로 부팅
#   --serial        시리얼 콘솔을 이 터미널에 연결 (디버깅; 기본은 로그 파일)
#   --no-open       VNC 앱을 자동으로 열지 않음 (기본: termux-open-url 로 vnc://127.0.0.1:5900 열기)
#   --force         메모리 부족 경고를 무시하고 실행
#   --status / --stop   실행 상태 확인 / 실행 중인 하그라 종료
#
# 이 스크립트는 번들 디렉터리(hagra-arm64.qcow2, vmlinuz, initrd.img, hagra-image.conf)와 같은 위치에서 실행한다.
# 루트 권한, KVM 을 사용하지 않는다. VNC 는 127.0.0.1 에만 바인딩된다.
set -euo pipefail

DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
MEM=2048; SMP=2; RES=1280x720; VNC=0; CPU=cortex-a76; UEFI=0; SERIAL=0; FORCE=0; OPEN=1; ACTION=run
while [ $# -gt 0 ]; do
  case "$1" in
    --mem) MEM=$2; shift 2 ;;
    --smp) SMP=$2; shift 2 ;;
    --res) RES=$2; shift 2 ;;
    --vnc) VNC=$2; shift 2 ;;
    --cpu) CPU=$2; shift 2 ;;
    --uefi) UEFI=1; shift ;;
    --serial) SERIAL=1; shift ;;
    --force) FORCE=1; shift ;;
    --no-open) OPEN=0; shift ;;
    --status) ACTION=status; shift ;;
    --stop) ACTION=stop; shift ;;
    -h|--help) sed -n 2,19p "$0"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done

PREFIX=${PREFIX:-/data/data/com.termux/files/usr}
TMP=${TMPDIR:-$PREFIX/tmp}; mkdir -p "$TMP"
LOGDIR=$DIR/logs; mkdir -p "$LOGDIR"
PIDFILE=$TMP/hagra-qemu.pid
MONITOR=$TMP/hagra-monitor.sock
# Unix 소켓 경로는 108 바이트 미만이어야 한다. 너무 길면 모니터를 끈다 (--stop 은 SIGTERM 으로 대체).
[ "${#MONITOR}" -lt 100 ] || MONITOR=""

say() { printf '\033[1m[hagra]\033[0m %s\n' "$*"; }
die() { printf '\033[1;31m[hagra] %s\033[0m\n' "$*" >&2; exit 1; }

running_pid() { [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null && cat "$PIDFILE"; }

if [ "$ACTION" = status ]; then
  if pid=$(running_pid); then say "running (pid $pid), VNC 127.0.0.1:$((5900 + VNC))"; else say "not running"; fi
  if command -v pgrep >/dev/null; then
    for p in $(pgrep -f "qemu-system-aarch64" 2>/dev/null); do [ -f "$PIDFILE" ] && [ "$p" = "$(cat "$PIDFILE")" ] && continue; say "other qemu-system-aarch64 running: pid $p (hagra --stop 으로 정리 가능)"; done
  fi
  exit 0
fi
if [ "$ACTION" = stop ]; then
  # 이전 버전(minos) pid 파일과 하그라 디렉터리에서 띄운 떠돌이 qemu-system-aarch64 도 함께 정리
  if [ -f "$TMP/minos-qemu.pid" ] && kill -0 "$(cat "$TMP/minos-qemu.pid")" 2>/dev/null; then kill "$(cat "$TMP/minos-qemu.pid")" 2>/dev/null; say "stopped legacy minos QEMU"; fi
  rm -f "$TMP/minos-qemu.pid"
  if command -v pgrep >/dev/null; then
    for p in $(pgrep -f "qemu-system-aarch64.*(hagra|minos)-arm64" 2>/dev/null); do
      [ -f "$PIDFILE" ] && [ "$p" = "$(cat "$PIDFILE")" ] && continue
      kill "$p" 2>/dev/null && say "stopped stray QEMU (pid $p)"
    done
  fi
  if pid=$(running_pid); then
    say "sending ACPI/PSCI power-down to guest (pid $pid)…"
    if command -v socat >/dev/null && [ -n "$MONITOR" ] && [ -S "$MONITOR" ]; then echo system_powerdown | socat - "UNIX-CONNECT:$MONITOR" >/dev/null 2>&1 || true; fi
    for i in $(seq 1 30); do kill -0 "$pid" 2>/dev/null || break; sleep 1; done
    kill -0 "$pid" 2>/dev/null && { say "forcing stop"; kill "$pid"; }
    rm -f "$PIDFILE"; say "stopped"
  else say "not running"; fi; exit 0
fi

# ---- 1. QEMU 확인 ----
QEMU=$(command -v qemu-system-aarch64 || true)
[ -n "$QEMU" ] || die "qemu-system-aarch64 가 없습니다. 실행:  pkg install qemu-system-aarch64-headless   (또는 bash install-termux.sh)"
QEMU_VER=$("$QEMU" --version | head -1)
"$QEMU" -device help 2>/dev/null | grep -q virtio-gpu-pci || die "이 QEMU 에는 virtio-gpu-pci 가 없습니다: $QEMU_VER"

# ---- 2. 이미지/펌웨어 확인 ----
CONF=$DIR/hagra-image.conf
[ -f "$CONF" ] || die "hagra-image.conf 가 없습니다. 번들 디렉터리에서 실행하십시오: $DIR"
# shellcheck disable=SC1090
. "$CONF"
DISK=$DIR/${HAGRA_DISK:-hagra-arm64.qcow2}; KERNEL=$DIR/${HAGRA_KERNEL:-vmlinuz}; INITRD=$DIR/${HAGRA_INITRD:-initrd.img}
[ "${HAGRA_ARCH:-arm64}" = arm64 ] || die "이 번들은 ${HAGRA_ARCH} 용입니다. Android 에는 arm64 번들이 필요합니다."
for f in "$DISK" "$KERNEL" "$INITRD"; do [ -f "$f" ] || die "파일 없음: $f"; done
FW=""
if [ "$UEFI" = 1 ]; then
  for c in "$PREFIX/share/edk2/aarch64/QEMU_EFI-pflash.raw" "$PREFIX/share/edk2/aarch64/QEMU_EFI.fd" "$PREFIX/share/qemu/edk2-aarch64-code.fd"; do
    [ -f "$c" ] && { FW=$c; break; }
  done
  [ -n "$FW" ] || die "UEFI 펌웨어가 없습니다 (pkg install ovmf). --uefi 없이 직접 커널 부팅을 사용하십시오."
fi

# ---- 3. 메모리/공간 확인 ----
if pid=$(running_pid); then die "이미 실행 중입니다 (pid $pid). --stop 으로 종료하십시오."; fi
# 이전 설치(minos-arm64, 이름 정리 전)가 남긴 QEMU 는 pid 파일 이름이 달라 위에서 잡히지 않는다 → 종료한다
LEGACY_PIDFILE=$TMP/minos-qemu.pid
if [ -f "$LEGACY_PIDFILE" ] && kill -0 "$(cat "$LEGACY_PIDFILE")" 2>/dev/null; then
  say "이전 버전(minos) QEMU 가 아직 실행 중입니다 (pid $(cat "$LEGACY_PIDFILE")) — 종료합니다"
  kill "$(cat "$LEGACY_PIDFILE")" 2>/dev/null; for i in $(seq 1 10); do kill -0 "$(cat "$LEGACY_PIDFILE")" 2>/dev/null || break; sleep 1; done
  rm -f "$LEGACY_PIDFILE"
fi
# VNC 포트가 다른 프로그램(또는 떠돌이 QEMU)에 잡혀 있으면 다음 빈 디스플레이를 고른다 ("Address already in use" 방지)
port_busy() { (exec 3<>"/dev/tcp/127.0.0.1/$1") 2>/dev/null; }
if port_busy $((5900 + VNC)); then
  WANTED=$VNC
  for d in $(seq $((VNC + 1)) $((VNC + 10))); do port_busy $((5900 + d)) || { VNC=$d; break; }; done
  if [ "$VNC" = "$WANTED" ]; then
    die "VNC 포트 $((5900 + WANTED))~$((5910 + WANTED)) 가 모두 사용 중입니다. 'hagra --stop' 또는 다른 VNC/QEMU 프로그램을 종료하십시오."
  fi
  say "VNC 포트 $((5900 + WANTED)) 가 사용 중이라 :$VNC (127.0.0.1:$((5900 + VNC))) 를 씁니다. 떠돌이 QEMU 가 있으면 'hagra --stop' 으로 정리할 수 있습니다."
fi
AVAIL_MB=$(awk '/MemAvailable/ {print int($2/1024)}' /proc/meminfo 2>/dev/null || true); AVAIL_MB=${AVAIL_MB:-0}
NEED_MB=$(( MEM + 384 ))
if [ "$AVAIL_MB" -gt 0 ] && [ "$AVAIL_MB" -lt "$NEED_MB" ]; then
  if [ "$FORCE" = 1 ]; then say "경고: 사용 가능한 메모리 ${AVAIL_MB}MB < 필요 ${NEED_MB}MB (계속)"; 
  else die "사용 가능한 메모리 ${AVAIL_MB}MB 가 부족합니다 (필요 ≈ ${NEED_MB}MB). 다른 앱을 종료하거나 --mem 1536 또는 --force 를 사용하십시오."; fi
fi
# Android 의 df(toybox)는 -m 을 지원하지 않으므로 -k 사용. 실패해도 실행은 계속한다.
FREE_MB=$(df -Pk "$DIR" 2>/dev/null | awk 'NR==2 && $4 ~ /^[0-9]+$/ {print int($4/1024)}' || true)
if [ -n "$FREE_MB" ] && [ "$FREE_MB" -lt 1024 ]; then
  say "경고: 저장 공간 여유 ${FREE_MB}MB — 디스크 이미지가 커질 공간이 부족할 수 있습니다"
fi

# ---- 4. 실행 ----
XRES=${RES%x*}; YRES=${RES#*x}
STAMP=$(date +%Y%m%d-%H%M%S)
SERIAL_LOG=$LOGDIR/serial-$STAMP.log
QEMU_LOG=$LOGDIR/qemu-$STAMP.log
CMDLINE="${HAGRA_CMDLINE:-root=LABEL=hagra-root rw rootwait quiet hagra.render=software} console=tty1 console=ttyAMA0,115200"

ARGS=(-M virt -accel tcg,thread=multi -cpu "$CPU" -smp "$SMP" -m "$MEM"
      -drive "file=$DISK,if=virtio,format=qcow2,cache=writeback,discard=unmap"
      -device "virtio-gpu-pci,xres=$XRES,yres=$YRES"
      -device virtio-keyboard-pci -device virtio-tablet-pci
      -device virtio-net-pci,netdev=n0,romfile= -netdev user,id=n0
      -object rng-random,filename=/dev/urandom,id=rng0 -device virtio-rng-pci,rng=rng0
      -rtc base=utc
      -display none -vnc "127.0.0.1:$VNC"
      -pidfile "$PIDFILE")
[ -n "$MONITOR" ] && ARGS+=(-monitor "unix:$MONITOR,server,nowait")
if [ "$UEFI" = 1 ]; then
  VARS=$TMP/hagra-efivars.fd; [ -f "$VARS" ] || truncate -s 64M "$VARS"
  CODE=$TMP/hagra-eficode.fd; cp "$FW" "$CODE"; truncate -s 64M "$CODE"
  ARGS+=(-drive if=pflash,format=raw,readonly=on,file="$CODE" -drive if=pflash,format=raw,file="$VARS")
else
  ARGS+=(-kernel "$KERNEL" -initrd "$INITRD" -append "$CMDLINE")
fi
if [ "$SERIAL" = 1 ]; then ARGS+=(-serial mon:stdio); else ARGS+=(-serial "file:$SERIAL_LOG"); fi

command -v termux-wake-lock >/dev/null && termux-wake-lock 2>/dev/null || true
cleanup() {
  rm -f "$PIDFILE" ${MONITOR:+"$MONITOR"}
  command -v termux-wake-unlock >/dev/null && termux-wake-unlock 2>/dev/null || true
  say "종료됨. 로그: $SERIAL_LOG"
}
trap cleanup EXIT

say "하그라(HAGRA) ${HAGRA_VERSION:-} (${HAGRA_SUITE:-} arm64) — $QEMU_VER"
say "메모리 ${MEM}MB · vCPU $SMP · 해상도 $RES · 부팅: $([ "$UEFI" = 1 ] && echo UEFI || echo '직접 커널')"
say "VNC 접속: 127.0.0.1:$((5900 + VNC))   (Android VNC 클라이언트에서 이 주소로 연결)"
say "시리얼 로그: $SERIAL_LOG   —   종료: 패널 전원 메뉴 → Shut down, 또는 bash $0 --stop"
say "첫 부팅은 소프트웨어 에뮬레이션(TCG)이라 1~3분 걸릴 수 있습니다."
START=$(date +%s)
# VNC 앱 자동 열기: QEMU 가 VNC 포트를 연 뒤 vnc:// URL 을 Android 에 전달 (AVNC, bVNC 등이 처리)
if [ "$OPEN" = 1 ] && command -v termux-open-url >/dev/null; then
  ( for i in $(seq 1 30); do
      sleep 1
      if [ -s "$PIDFILE" ]; then sleep 1; termux-open-url "vnc://127.0.0.1:$((5900 + VNC))" >/dev/null 2>&1 || true; break; fi
    done ) &
fi
"$QEMU" "${ARGS[@]}" 2>"$QEMU_LOG" || { say "QEMU 가 오류로 종료되었습니다. $QEMU_LOG:"; tail -20 "$QEMU_LOG"; exit 1; }
say "가동 시간: $(( $(date +%s) - START ))초"
