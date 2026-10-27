#!/bin/bash
# 하그라 이미지를 QEMU 에서 실행 (PC 개발용).  Android/Termux 에서는 android/start-hagra.sh 를 사용한다.
#   image/qemu/run.sh [옵션] TARGET
# TARGET
#   *.iso                      x86-64 live ISO (BIOS/UEFI)
#   DIR (hagra-image.conf 포함)  디스크 이미지 번들: qcow2 + vmlinuz + initrd (직접 커널 부팅, 기본 ARM64)
#   *.qcow2                    디스크 이미지 (같은 디렉터리의 vmlinuz/initrd.img 사용)
# 옵션
#   --serial        시리얼 콘솔을 stdio 로 (디스플레이 없음, -serial mon:stdio)
#   --vnc N         VNC 127.0.0.1:590N 으로 화면 출력 (디스플레이 창 없음)
#   --display MODE  QEMU -display 값 (gtk|sdl|none)
#   --monitor SOCK  HMP 모니터 unix 소켓 (자동 테스트의 screendump 용)
#   --uefi          디스크 이미지를 UEFI 펌웨어(AAVMF/OVMF)로 부팅 (기본: 직접 커널 부팅)
#   --bios          ISO 를 BIOS 로 부팅 (기본 UEFI)
#   --res WxH       가상 디스플레이 해상도 (기본 1280x720)
#   --mem MB / --smp N / --cpu MODEL
#   --gpu virtio|std  가상 그래픽 (기본 virtio). std = QEMU 표준 VGA (bochs-drm 드라이버; virtio 가 없는 가상 머신 경로 시험용)
set -euo pipefail
SERIAL=0; UEFI_ISO=1; UEFI_DISK=0; MONITOR=""; DISPLAY_OPT=""; VNC=""; RES=${HAGRA_RES:-1280x720}
MEM=${HAGRA_MEM:-2048}; SMP=${HAGRA_SMP:-2}; CPU=${HAGRA_CPU:-}; GPU=${HAGRA_GPU:-virtio}; EXTRA=()
while [ $# -gt 1 ]; do
  case "$1" in
    --serial) SERIAL=1; shift ;;
    --bios) UEFI_ISO=0; shift ;;
    --uefi) UEFI_DISK=1; shift ;;
    --monitor) MONITOR=$2; shift 2 ;;
    --display) DISPLAY_OPT=$2; shift 2 ;;
    --vnc) VNC=$2; shift 2 ;;
    --res) RES=$2; shift 2 ;;
    --mem) MEM=$2; shift 2 ;;
    --smp) SMP=$2; shift 2 ;;
    --cpu) CPU=$2; shift 2 ;;
    --gpu) GPU=$2; shift 2 ;;
    --) shift; EXTRA=("$@"); set -- "${@: -1}" ;;
    *) break ;;
  esac
done
TARGET=${1:?usage: run.sh [options] TARGET}
[ -e "$TARGET" ] || { echo "not found: $TARGET" >&2; exit 1; }
XRES=${RES%x*}; YRES=${RES#*x}

find_fw() { # $1 = 아키텍처
  local d c
  if [ "$1" = arm64 ]; then
    for d in /usr/share/AAVMF /usr/share/qemu-efi-aarch64 /usr/share/edk2/aarch64; do
      for c in AAVMF_CODE.fd QEMU_EFI.fd QEMU_EFI-pflash.raw; do [ -f "$d/$c" ] && { echo "$d/$c"; return; }; done
    done
  else
    for d in /usr/share/OVMF /usr/share/edk2/x64 /usr/share/qemu; do
      for c in OVMF_CODE_4M.fd OVMF_CODE.fd; do [ -f "$d/$c" ] && { echo "$d/$c"; return; }; done
    done
  fi
}

# ---- 대상 판별 ----
MODE=iso; ARCH=amd64
if [ -d "$TARGET" ]; then
  MODE=disk; BUNDLE=$TARGET
elif [[ "$TARGET" == *.qcow2 ]]; then
  MODE=disk; BUNDLE=$(dirname "$TARGET")
fi
if [ "$MODE" = disk ]; then
  CONF=$BUNDLE/hagra-image.conf
  [ -f "$CONF" ] || { echo "hagra-image.conf not found in $BUNDLE" >&2; exit 1; }
  # shellcheck disable=SC1090
  . "$CONF"
  ARCH=${HAGRA_ARCH:-arm64}
  DISK=$BUNDLE/${HAGRA_DISK:-hagra-$ARCH.qcow2}
  KERNEL=$BUNDLE/${HAGRA_KERNEL:-vmlinuz}
  INITRD=$BUNDLE/${HAGRA_INITRD:-initrd.img}
  for f in "$DISK" "$KERNEL" "$INITRD"; do [ -f "$f" ] || { echo "missing: $f" >&2; exit 1; }; done
fi

# ---- 가속/CPU ----
HOST_ARCH=$(uname -m)
ACCEL="tcg,thread=multi"
if [ -w /dev/kvm ] && { [ "$ARCH" = amd64 ] && [ "$HOST_ARCH" = x86_64 ] || [ "$ARCH" = arm64 ] && [ "$HOST_ARCH" = aarch64 ]; }; then
  ACCEL=kvm; CPU=${CPU:-host}
fi
if [ "$ARCH" = arm64 ]; then
  QEMU=qemu-system-aarch64; CPU=${CPU:-cortex-a76}
  ARGS=(-M virt -accel "$ACCEL" -cpu "$CPU" -smp "$SMP" -m "$MEM")
  CONSOLE="console=tty1 console=ttyAMA0,115200"
else
  # TCG(KVM 없음) 기본 CPU 는 AVX 없는 Nehalem-v2: "max" 가 내보내는 AVX2 의 마스크 load(vpmaskmov)를 QEMU 8.2 TCG 가
  # 잘못 에뮬레이트해 Qt 의 그림 경로가 segfault 한다 (보그라에서 재현, 실제 CPU·KVM 에서는 정상). KVM 은 위에서 host.
  QEMU=qemu-system-x86_64; CPU=${CPU:-Nehalem-v2}
  # -vga none: q35 의 기본 VGA 를 끄고 virtio-gpu 하나만 둔다 (두 출력이 생기면 screendump 가 빈 화면을 찍는다)
  ARGS=(-machine q35 -accel "$ACCEL" -cpu "$CPU" -smp "$SMP" -m "$MEM" -vga none)
  CONSOLE="console=tty1 console=ttyS0,115200"
fi
command -v "$QEMU" >/dev/null || { echo "$QEMU not installed (qemu-system-arm / qemu-system-x86)" >&2; exit 2; }

# ---- 장치 모델 (Android 실행 스크립트와 동일) ----
case "$GPU" in
  virtio) ARGS+=(-device "virtio-gpu-pci,xres=$XRES,yres=$YRES") ;;
  std) ARGS+=(-device "VGA,xres=$XRES,yres=$YRES") ;;   # QEMU 의 vmware-svga 는 vmwgfx 가 지원하지 않는 구형이라 시험용으로 쓰지 않는다
  *) echo "unknown --gpu $GPU (virtio|std)" >&2; exit 2 ;;
esac
ARGS+=(-device virtio-keyboard-pci -device virtio-tablet-pci
       -device virtio-net-pci,netdev=n0,romfile= -netdev user,id=n0
       -object rng-random,filename=/dev/urandom,id=rng0 -device virtio-rng-pci,rng=rng0
       -rtc base=utc)

if [ "$MODE" = iso ]; then
  ARGS+=(-cdrom "$TARGET" -boot d -device qemu-xhci -device usb-tablet)
  if [ "$UEFI_ISO" = 1 ]; then
    CODE=$(find_fw amd64 || true)
    if [ -n "$CODE" ]; then
      VARS=${CODE%/*}/OVMF_VARS_4M.fd; [ -f "$VARS" ] || VARS=${CODE%/*}/OVMF_VARS.fd
      VARS_COPY=${HAGRA_OVMF_VARS:-/tmp/hagra-ovmf-vars-$$.fd}; cp "$VARS" "$VARS_COPY"
      ARGS+=(-drive if=pflash,format=raw,readonly=on,file="$CODE" -drive if=pflash,format=raw,file="$VARS_COPY")
    else
      echo "OVMF not found; falling back to BIOS boot" >&2
    fi
  fi
else
  ARGS+=(-drive "file=$DISK,if=virtio,format=qcow2,cache=writeback,discard=unmap")
  if [ "$UEFI_DISK" = 1 ]; then
    CODE=$(find_fw "$ARCH" || true)
    [ -n "$CODE" ] || { echo "UEFI firmware for $ARCH not found (qemu-efi-aarch64 / ovmf)" >&2; exit 2; }
    VARS_COPY=${HAGRA_OVMF_VARS:-/tmp/hagra-fw-vars-$$.fd}
    truncate -s 64M "$VARS_COPY"
    if [ "$ARCH" = arm64 ]; then
      # AAVMF: pflash 는 64MB 로 패딩되어야 한다
      CODE_PAD=/tmp/hagra-fw-code-$$.fd; cp "$CODE" "$CODE_PAD"; truncate -s 64M "$CODE_PAD"; CODE=$CODE_PAD
    fi
    ARGS+=(-drive if=pflash,format=raw,readonly=on,file="$CODE" -drive if=pflash,format=raw,file="$VARS_COPY")
  else
    ARGS+=(-kernel "$KERNEL" -initrd "$INITRD" -append "${HAGRA_CMDLINE:-root=LABEL=hagra-root rw} $CONSOLE")
  fi
fi

if [ "$SERIAL" = 1 ]; then
  ARGS+=(-display none -serial mon:stdio)
elif [ -n "$VNC" ]; then
  ARGS+=(-display none -vnc "127.0.0.1:$VNC" -serial stdio)
  echo "VNC: 127.0.0.1:$((5900 + VNC))" >&2
else
  ARGS+=(-display "${DISPLAY_OPT:-gtk}" -serial stdio)
fi
[ -n "$MONITOR" ] && ARGS+=(-monitor "unix:$MONITOR,server,nowait")
echo "$QEMU (accel=$ACCEL cpu=$CPU mem=${MEM}M smp=$SMP gpu=$GPU res=$RES mode=$MODE) $TARGET" >&2
exec "$QEMU" "${ARGS[@]}" "${EXTRA[@]}"
