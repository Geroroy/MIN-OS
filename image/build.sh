#!/bin/bash
# 하그라 부팅 이미지 빌드
#   sudo image/build.sh [--suite debian-trixie|ubuntu-noble] [--arch amd64|arm64] [--format iso|disk]
#                       [--profile default|mobile] [--output PATH] [--work DIR]
#                       [--reuse-rootfs] [--iso-only|--image-only] [--only-hook NN] [--no-iso] [--release]
# 포맷
#   iso  : squashfs + live-boot + GRUB hybrid ISO (BIOS+UEFI)            — 기본 (amd64)
#   disk : GPT 디스크 이미지(ESP + ext4 루트) → qcow2 + vmlinuz/initrd 번들   — 기본 (arm64, Termux QEMU)
# 단계: 1 rootfs(mmdebstrap, 교차 아키텍처는 qemu-user binfmt) → 2 hooks(chroot) → 3 squashfs|파티션 → 4 ISO|qcow2
# 호스트의 디스크·부트로더는 건드리지 않는다 (loop 장치도 사용하지 않음).
set -euo pipefail

REPO=$(cd "$(dirname "$0")/.." && pwd)
SUITE=debian-trixie
ARCH=amd64
FORMAT=""
PROFILE=""
OUTPUT=""
WORK=""
REUSE_ROOTFS=0
ISO_ONLY=0
ONLY_HOOK=""
NO_ISO=0
DEV=1

while [ $# -gt 0 ]; do
  case "$1" in
    --suite) SUITE=$2; shift 2 ;;
    --arch) ARCH=$2; shift 2 ;;
    --format) FORMAT=$2; shift 2 ;;
    --profile) PROFILE=$2; shift 2 ;;
    --output) OUTPUT=$2; shift 2 ;;
    --work) WORK=$2; shift 2 ;;
    --reuse-rootfs) REUSE_ROOTFS=1; shift ;;
    --iso-only|--image-only) REUSE_ROOTFS=1; ISO_ONLY=1; shift ;;
    --only-hook) REUSE_ROOTFS=1; ONLY_HOOK=$2; shift 2 ;;   # 기존 rootfs 에서 지정한 hook(접두 번호)만 다시 실행 후 이미지 조립
    --no-iso) NO_ISO=1; shift ;;
    --release) DEV=0; shift ;;
    -h|--help) sed -n 2,10p "$0"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done

[ "$(id -u)" -eq 0 ] || { echo "root 권한이 필요합니다 (chroot/mount)" >&2; exit 1; }
CONF=$REPO/image/config
[ -f "$CONF/suites/$SUITE.conf" ] || { echo "unknown suite: $SUITE" >&2; exit 2; }
# shellcheck disable=SC1090
. "$CONF/suites/$SUITE.conf"

case "$ARCH" in
  amd64) FORMAT=${FORMAT:-iso}; PROFILE=${PROFILE:-default} ;;
  arm64) FORMAT=${FORMAT:-disk}; PROFILE=${PROFILE:-mobile} ;;
  *) echo "unsupported arch: $ARCH (amd64|arm64)" >&2; exit 2 ;;
esac
case "$FORMAT" in iso|disk) ;; *) echo "unknown format: $FORMAT (iso|disk)" >&2; exit 2 ;; esac
# 아키텍처별 미러/커널 (suite conf 의 *_arm64 변수)
if [ "$ARCH" != amd64 ]; then
  v="MIRROR_$ARCH"; [ -n "${!v:-}" ] && MIRROR=${!v}
fi
v="KERNEL_PKGS_$ARCH"; KERNEL_PKGS=${!v:-${KERNEL_PKGS:-}}
[ -n "$KERNEL_PKGS" ] || { echo "suite $SUITE has no KERNEL_PKGS for $ARCH" >&2; exit 2; }

WORK=${WORK:-$REPO/image/work/$SUITE-$ARCH}
[ "$SUITE-$ARCH" = "ubuntu-noble-amd64" ] && [ -d "$REPO/image/work/ubuntu-noble/rootfs" ] && [ ! -d "$WORK" ] && WORK=$REPO/image/work/ubuntu-noble
if [ -z "$OUTPUT" ]; then
  if [ "$FORMAT" = iso ]; then OUTPUT=$REPO/out/hagra-dev-$SUITE-$ARCH.iso
  else OUTPUT=$REPO/out/hagra-$ARCH; fi   # 디렉터리 번들: hagra-$ARCH.qcow2 + vmlinuz + initrd.img
fi
ROOTFS=$WORK/rootfs
ISOROOT=$WORK/iso
VERSION=$(sed -n 's/^project(hagra VERSION \([0-9.]*\).*/\1/p' "$REPO/CMakeLists.txt")
mkdir -p "$WORK" "$(dirname "$OUTPUT")"

for t in mmdebstrap rsync; do
  command -v "$t" >/dev/null || { echo "missing tool: $t (run scripts/install-deps.sh)" >&2; exit 2; }
done
if [ "$FORMAT" = iso ]; then TOOLS="mksquashfs xorriso grub-mkstandalone mformat mcopy"; else TOOLS="mke2fs sfdisk mformat mcopy qemu-img"; fi
for t in $TOOLS; do
  command -v "$t" >/dev/null || { echo "missing tool: $t (run scripts/install-deps.sh)" >&2; exit 2; }
done
HOST_ARCH=$(dpkg --print-architecture)
if [ "$ARCH" != "$HOST_ARCH" ]; then
  # 교차 아키텍처: qemu-user-static + binfmt_misc 필요
  if [ ! -e "/proc/sys/fs/binfmt_misc/qemu-$( [ "$ARCH" = arm64 ] && echo aarch64 || echo "$ARCH")" ]; then
    echo "binfmt_misc에 qemu-$ARCH 가 등록되어 있지 않습니다. scripts/install-deps.sh 를 실행하거나 qemu-user-static/binfmt-support 를 설치하십시오." >&2
    exit 2
  fi
fi
echo "== 하그라 image build: suite=$SUITE arch=$ARCH format=$FORMAT profile=$PROFILE kernel='$KERNEL_PKGS'"

log() { printf '\n\033[1m== %s\033[0m\n' "$*"; }
pkglist() { grep -hvE '^\s*(#|$)' "$@" | tr '\n' ',' | sed 's/,$//'; }

# ---------- chroot 마운트 관리 ----------
MOUNTED=0
chroot_mount() {
  mount -t proc proc "$ROOTFS/proc"
  mount -t sysfs sys "$ROOTFS/sys"
  mount --bind /dev "$ROOTFS/dev"
  mount -t devpts devpts -o gid=5,mode=620,ptmxmode=666 "$ROOTFS/dev/pts"
  mount -t tmpfs tmpfs "$ROOTFS/run"
  MOUNTED=1
  cp -L /etc/resolv.conf "$ROOTFS/etc/resolv.conf"
  # chroot 안에서 서비스가 시작되지 않도록
  printf '#!/bin/sh\nexit 101\n' > "$ROOTFS/usr/sbin/policy-rc.d"; chmod +x "$ROOTFS/usr/sbin/policy-rc.d"
}
chroot_umount() {
  [ "$MOUNTED" = 1 ] || return 0
  rm -f "$ROOTFS/usr/sbin/policy-rc.d"
  for m in run dev/pts dev sys proc; do
    umount -l "$ROOTFS/$m" 2>/dev/null || true
  done
  MOUNTED=0
}
trap chroot_umount EXIT
run_in_chroot() {
  chroot "$ROOTFS" /usr/bin/env -i \
    PATH=/usr/sbin:/usr/bin:/sbin:/bin HOME=/root LC_ALL=C.UTF-8 TERM=dumb \
    DEBIAN_FRONTEND=noninteractive \
    HAGRA_SUITE="$SUITE_NAME" HAGRA_VERSION="$VERSION" HAGRA_DEV="$DEV" HAGRA_KERNEL_PKGS="$KERNEL_PKGS" \
    HAGRA_ARCH="$ARCH" HAGRA_FORMAT="$FORMAT" HAGRA_PROFILE="$PROFILE" \
    "$@"
}

# ---------- 1. rootfs ----------
if [ "$REUSE_ROOTFS" = 1 ] && [ -d "$ROOTFS/usr" ]; then
  log "1/4 rootfs 재사용: $ROOTFS"
else
  log "1/4 rootfs 생성: $SUITE_NAME ($ARCH) from $MIRROR"
  rm -rf "$ROOTFS"
  INCLUDE=$(pkglist "$CONF/packages.base" "$CONF/packages.desktop" "$CONF/packages.$FORMAT")
  [ -n "${EXTRA_PKGS:-}" ] && INCLUDE="$INCLUDE,$(echo "$EXTRA_PKGS" | tr ' ' ',')"
  KEYRING_OPT=""
  [ -n "${KEYRING:-}" ] && [ -f "$KEYRING" ] && KEYRING_OPT="--keyring=$KEYRING"
  mmdebstrap --variant=minbase --mode=root --architectures="$ARCH" --components="$COMPONENTS" \
    --include="$INCLUDE" $KEYRING_OPT \
    --aptopt='Acquire::Languages "none"' \
    --dpkgopt='path-exclude=/usr/share/man/*' --dpkgopt='path-exclude=/usr/share/doc/*' \
    --dpkgopt='path-include=/usr/share/doc/*/copyright' \
    --dpkgopt='path-exclude=/usr/share/locale/*' --dpkgopt='path-include=/usr/share/locale/ko/*' --dpkgopt='path-include=/usr/share/locale/en/*' \
    "$SUITE_NAME" "$ROOTFS" "$MIRROR"
fi

# ---------- 2. hooks ----------
if [ "$ISO_ONLY" = 1 ]; then
log "2/4 chroot 커스터마이즈 건너뜀 (--iso-only)"
else
log "2/4 chroot 커스터마이즈"
rm -rf "$ROOTFS/tmp/hagra-src" "$ROOTFS/tmp/hagra-hooks"
mkdir -p "$ROOTFS/tmp/hagra-src"
rsync -a --exclude build --exclude 'build-*' --exclude out --exclude image/work --exclude .git \
  "$REPO/CMakeLists.txt" "$REPO/libs" "$REPO/shell" "$REPO/settings" "$REPO/browser" "$REPO/tools" "$REPO/design" "$REPO/session" "$REPO/image" "$ROOTFS/tmp/hagra-src/"
cp -a "$CONF/hooks" "$ROOTFS/tmp/hagra-hooks"
chroot_mount
for hook in "$ROOTFS"/tmp/hagra-hooks/*.sh; do
  name=$(basename "$hook")
  if [ -n "$ONLY_HOOK" ]; then   # 쉼표로 여러 접두 번호 지정 가능: --only-hook 30,40,55
    match=0; for h in ${ONLY_HOOK//,/ }; do [[ "$name" == "$h"* ]] && match=1; done; [ "$match" = 1 ] || continue
  fi
  log "   hook $name"
  run_in_chroot /bin/bash "/tmp/hagra-hooks/$name"
done
chroot_umount
rm -rf "$ROOTFS/tmp/hagra-src" "$ROOTFS/tmp/hagra-hooks"
fi

[ "$NO_ISO" = 1 ] && { log "rootfs 준비 완료 (--no-iso): $ROOTFS"; exit 0; }

if [ "$FORMAT" = iso ]; then
# ---------- 3. squashfs ----------
log "3/4 squashfs"
rm -rf "$ISOROOT"
mkdir -p "$ISOROOT/live" "$ISOROOT/boot/grub" "$ISOROOT/EFI/BOOT"
cp -L "$ROOTFS/boot/vmlinuz" "$ISOROOT/live/vmlinuz"
cp -L "$ROOTFS/boot/initrd.img" "$ISOROOT/live/initrd.img"
# 주의: /proc /sys /dev /run /tmp 은 비어 있어야 하지만 디렉터리 자체는 반드시 포함되어야 한다 (init 마운트 지점).
for d in proc sys dev/pts run tmp; do mkdir -p "$ROOTFS/$d"; done
mksquashfs "$ROOTFS" "$ISOROOT/live/filesystem.squashfs" -comp zstd -Xcompression-level 15 -b 1M \
  -noappend -no-progress -quiet 2>&1 | tail -3 || true
ls -la "$ISOROOT/live/"

# ---------- 4. ISO ----------
log "4/4 GRUB hybrid ISO (BIOS + UEFI)"
cp "$REPO/image/grub/grub.cfg" "$ISOROOT/boot/grub/grub.cfg"
sed -i "s/@VERSION@/$VERSION/; s/@SUITE@/$SUITE_NAME/" "$ISOROOT/boot/grub/grub.cfg"
EARLY=$WORK/grub-early.cfg
cp "$REPO/image/grub/early.cfg" "$EARLY"
GRUB_MODULES="part_gpt part_msdos fat iso9660 normal configfile search search_label search_fs_uuid linux echo ls cat serial terminal all_video gfxterm font reboot halt"

# UEFI
grub-mkstandalone -O x86_64-efi -o "$WORK/BOOTX64.EFI" --modules="$GRUB_MODULES" --locales="" --fonts="" \
  "boot/grub/grub.cfg=$EARLY"
cp "$WORK/BOOTX64.EFI" "$ISOROOT/EFI/BOOT/BOOTX64.EFI"
EFIIMG=$ISOROOT/EFI/efiboot.img
rm -f "$EFIIMG"
truncate -s 8M "$EFIIMG"
mformat -i "$EFIIMG" ::   # FAT12/16: 작은 이미지에 FAT32 를 강제하면 EDK2(OVMF)가 읽지 못한다
mmd -i "$EFIIMG" ::/EFI ::/EFI/BOOT
mcopy -i "$EFIIMG" "$WORK/BOOTX64.EFI" ::/EFI/BOOT/BOOTX64.EFI

# BIOS
grub-mkstandalone -O i386-pc -o "$WORK/core.img" --modules="$GRUB_MODULES biosdisk" --locales="" --fonts="" \
  --install-modules="$GRUB_MODULES biosdisk vbe vga video_bochs video_cirrus memdisk tar" \
  "boot/grub/grub.cfg=$EARLY"
cat /usr/lib/grub/i386-pc/cdboot.img "$WORK/core.img" > "$ISOROOT/boot/grub/bios.img"

xorriso -as mkisofs -iso-level 3 -full-iso9660-filenames -joliet -rational-rock \
  -volid "HAGRA" \
  -eltorito-boot boot/grub/bios.img -no-emul-boot -boot-load-size 4 -boot-info-table \
  --eltorito-catalog boot/grub/boot.cat --grub2-boot-info \
  --grub2-mbr /usr/lib/grub/i386-pc/boot_hybrid.img \
  -eltorito-alt-boot -e EFI/efiboot.img -no-emul-boot \
  -append_partition 2 0xef "$EFIIMG" \
  -o "$OUTPUT" "$ISOROOT" 2>&1 | grep -vE '^xorriso : UPDATE' | tail -5

log "완료: $OUTPUT ($(du -h "$OUTPUT" | cut -f1))"
echo "   실행: image/qemu/run.sh $OUTPUT    또는    make run ISO=$OUTPUT"

else
# ---------- 3. 파티션 이미지 (loop 장치 없이) ----------
log "3/4 디스크 파티션: ESP(FAT) + 루트(ext4, mke2fs -d)"
DISKWORK=$WORK/disk
rm -rf "$DISKWORK"; mkdir -p "$DISKWORK"
for d in proc sys dev/pts run tmp; do mkdir -p "$ROOTFS/$d"; done
case "$ARCH" in arm64) EFI=BOOTAA64.EFI ;; amd64) EFI=BOOTX64.EFI ;; esac
[ -f "$ROOTFS/boot/efi-staging/$EFI" ] || { echo "bootloader missing: $ROOTFS/boot/efi-staging/$EFI (hook 55)" >&2; exit 1; }

ESP_MB=128
ESP_IMG=$DISKWORK/esp.img
truncate -s ${ESP_MB}M "$ESP_IMG"
mformat -i "$ESP_IMG" -F -v HAGRA-ESP ::
mmd -i "$ESP_IMG" ::/EFI ::/EFI/BOOT
mcopy -i "$ESP_IMG" "$ROOTFS/boot/efi-staging/$EFI" "::/EFI/BOOT/$EFI"

# 루트: 사용량 + 여유 (qcow2 는 희소 → 실제 크기는 사용량만큼)
USED_MB=$(du -sm --exclude=proc --exclude=sys --exclude=dev --exclude=run --exclude=tmp "$ROOTFS" | cut -f1)
ROOT_MB=${HAGRA_ROOT_MB:-$(( USED_MB + 2048 > 6144 ? USED_MB + 2048 : 6144 ))}
ROOT_IMG=$DISKWORK/root.img
truncate -s ${ROOT_MB}M "$ROOT_IMG"
# 이미지 안의 efi-staging 은 ESP 에 이미 복사됨 — 루트에서는 제외
mv "$ROOTFS/boot/efi-staging" "$DISKWORK/efi-staging"
mke2fs -q -F -t ext4 -L hagra-root -d "$ROOTFS" -E lazy_itable_init=1,lazy_journal_init=1 -O ^huge_file "$ROOT_IMG"
mv "$DISKWORK/efi-staging" "$ROOTFS/boot/efi-staging"
echo "   rootfs ${USED_MB}MB → root.img ${ROOT_MB}MB (ext4, label hagra-root)"

# ---------- 4. GPT 디스크 → qcow2 + 직접 부팅용 커널/initrd 번들 ----------
log "4/4 GPT 디스크 이미지 → qcow2 번들"
RAW=$DISKWORK/disk.raw
TOTAL_MB=$(( 1 + ESP_MB + ROOT_MB + 1 ))
truncate -s ${TOTAL_MB}M "$RAW"
case "$ARCH" in
  arm64) ROOT_TYPE=B921B045-1DF0-41C3-AF44-4C6F280D3FAE ;;   # Linux root (ARM64)
  *)     ROOT_TYPE=4F68BCE3-E8CD-4DB1-96E7-FBCAF984B709 ;;   # Linux root (x86-64)
esac
# sfdisk 스크립트는 섹터 단위만 안정적으로 지원한다 (1 MiB = 2048 섹터)
sfdisk -q "$RAW" <<P
label: gpt
unit: sectors
start=2048, size=$((ESP_MB * 2048)), type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B, name="HAGRA-ESP"
start=$(( (1 + ESP_MB) * 2048 )), size=$((ROOT_MB * 2048)), type=${ROOT_TYPE}, name="hagra-root"
P
dd if="$ESP_IMG"  of="$RAW" bs=1M seek=1               conv=notrunc,sparse status=none
dd if="$ROOT_IMG" of="$RAW" bs=1M seek=$((1 + ESP_MB)) conv=notrunc,sparse status=none
rm -f "$ESP_IMG" "$ROOT_IMG"

mkdir -p "$OUTPUT"
QCOW=$OUTPUT/hagra-$ARCH.qcow2
qemu-img convert -f raw -O qcow2 "$RAW" "$QCOW"
rm -f "$RAW"
cp -L "$ROOTFS/boot/vmlinuz" "$OUTPUT/vmlinuz"; chmod 644 "$OUTPUT/vmlinuz"
cp -L "$ROOTFS/boot/initrd.img" "$OUTPUT/initrd.img"
cp "$REPO/android/start-hagra.sh" "$OUTPUT/start-hagra.sh" 2>/dev/null || true
chmod +x "$OUTPUT"/*.sh 2>/dev/null || true
cat > "$OUTPUT/hagra-image.conf" <<C
# 하그라 이미지 메타데이터 (start-hagra.sh / image/qemu/run.sh 가 읽음)
HAGRA_VERSION=$VERSION
HAGRA_SUITE=$SUITE_NAME
HAGRA_ARCH=$ARCH
HAGRA_PROFILE=$PROFILE
HAGRA_DISK=hagra-$ARCH.qcow2
HAGRA_KERNEL=vmlinuz
HAGRA_INITRD=initrd.img
HAGRA_CMDLINE="root=LABEL=hagra-root rw rootwait quiet loglevel=3 systemd.show_status=0 hagra.render=software"
HAGRA_BUILD_DATE=$(date -u +%Y-%m-%dT%H:%M:%SZ)
C
# 커널 버전 기록 (문서/디버깅)
ls "$ROOTFS/lib/modules" | sort -V | tail -1 > "$OUTPUT/kernel-version.txt"
qemu-img info "$QCOW" | grep -E "virtual size|disk size"
log "완료: $OUTPUT/"
ls -la "$OUTPUT"
echo "   실행: image/qemu/run.sh $OUTPUT    (Android: android/start-hagra.sh 참고)"
fi
