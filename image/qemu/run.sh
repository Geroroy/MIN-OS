#!/bin/bash
# MIN OS ISO 를 QEMU 에서 실행.  image/qemu/run.sh [--serial] [--bios] [--monitor SOCK] [--display none] ISO
set -euo pipefail
SERIAL=0; UEFI=1; MONITOR=""; DISPLAY_OPT=""; EXTRA=()
while [ $# -gt 1 ]; do
  case "$1" in
    --serial) SERIAL=1; shift ;;
    --bios) UEFI=0; shift ;;
    --monitor) MONITOR=$2; shift 2 ;;
    --display) DISPLAY_OPT=$2; shift 2 ;;
    --) shift; EXTRA=("$@"); set -- "${@: -1}" ;;
    *) break ;;
  esac
done
ISO=${1:?usage: run.sh [options] ISO}
[ -f "$ISO" ] || { echo "ISO not found: $ISO" >&2; exit 1; }

ACCEL="tcg,thread=multi"; CPU="max"
if [ -w /dev/kvm ]; then ACCEL=kvm; CPU=host; fi
ARGS=(-machine q35,accel=$ACCEL -cpu $CPU -smp "${MINOS_SMP:-2}" -m "${MINOS_MEM:-2048}"
      -cdrom "$ISO" -boot d
      -device virtio-vga
      -device qemu-xhci -device usb-tablet -device usb-kbd
      -device virtio-net-pci,netdev=n0 -netdev user,id=n0
      -device virtio-rng-pci
      -rtc base=utc)
if [ "$UEFI" = 1 ]; then
  CODE=""; VARS=""
  for d in /usr/share/OVMF /usr/share/edk2/x64 /usr/share/qemu; do
    for c in OVMF_CODE_4M.fd OVMF_CODE.fd; do [ -z "$CODE" ] && [ -f "$d/$c" ] && CODE=$d/$c; done
    for v in OVMF_VARS_4M.fd OVMF_VARS.fd; do [ -z "$VARS" ] && [ -f "$d/$v" ] && VARS=$d/$v; done
  done
  if [ -n "$CODE" ]; then
    VARS_COPY=${MINOS_OVMF_VARS:-/tmp/minos-ovmf-vars-$$.fd}; cp "$VARS" "$VARS_COPY"
    ARGS+=(-drive if=pflash,format=raw,readonly=on,file="$CODE" -drive if=pflash,format=raw,file="$VARS_COPY")
  else
    echo "OVMF not found; falling back to BIOS boot" >&2
  fi
fi
if [ "$SERIAL" = 1 ]; then
  ARGS+=(-display "${DISPLAY_OPT:-none}" -serial mon:stdio)
else
  ARGS+=(-display "${DISPLAY_OPT:-gtk}" -serial stdio)
fi
[ -n "$MONITOR" ] && ARGS+=(-monitor "unix:$MONITOR,server,nowait")
echo "qemu-system-x86_64 (accel=$ACCEL) $ISO" >&2
exec qemu-system-x86_64 "${ARGS[@]}" "${EXTRA[@]}"
