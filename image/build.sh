#!/bin/bash
# MIN OS 부팅 이미지 빌드
#   sudo image/build.sh [--suite debian-trixie|ubuntu-noble] [--arch amd64] [--output out/x.iso]
#                       [--work DIR] [--reuse-rootfs] [--iso-only] [--no-iso] [--release]
# 단계: 1 rootfs(mmdebstrap) → 2 hooks(chroot) → 3 squashfs → 4 GRUB hybrid ISO
# 호스트의 디스크·부트로더는 건드리지 않는다 (loop 장치도 사용하지 않음).
set -euo pipefail

REPO=$(cd "$(dirname "$0")/.." && pwd)
SUITE=debian-trixie
ARCH=amd64
OUTPUT=""
WORK=""
REUSE_ROOTFS=0
ISO_ONLY=0
NO_ISO=0
DEV=1

while [ $# -gt 0 ]; do
  case "$1" in
    --suite) SUITE=$2; shift 2 ;;
    --arch) ARCH=$2; shift 2 ;;
    --output) OUTPUT=$2; shift 2 ;;
    --work) WORK=$2; shift 2 ;;
    --reuse-rootfs) REUSE_ROOTFS=1; shift ;;
    --iso-only) REUSE_ROOTFS=1; ISO_ONLY=1; shift ;;
    --no-iso) NO_ISO=1; shift ;;
    --release) DEV=0; shift ;;
    -h|--help) sed -n 2,7p "$0"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done

[ "$(id -u)" -eq 0 ] || { echo "root 권한이 필요합니다 (chroot/mount)" >&2; exit 1; }
CONF=$REPO/image/config
[ -f "$CONF/suites/$SUITE.conf" ] || { echo "unknown suite: $SUITE" >&2; exit 2; }
# shellcheck disable=SC1090
. "$CONF/suites/$SUITE.conf"

WORK=${WORK:-$REPO/image/work/$SUITE}
OUTPUT=${OUTPUT:-$REPO/out/minos-dev-$SUITE-$ARCH.iso}
ROOTFS=$WORK/rootfs
ISOROOT=$WORK/iso
VERSION=$(sed -n 's/^project(minos VERSION \([0-9.]*\).*/\1/p' "$REPO/CMakeLists.txt")
mkdir -p "$WORK" "$(dirname "$OUTPUT")"

for t in mmdebstrap mksquashfs xorriso grub-mkstandalone mformat mcopy rsync; do
  command -v "$t" >/dev/null || { echo "missing tool: $t (run scripts/install-deps.sh)" >&2; exit 2; }
done

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
    MINOS_SUITE="$SUITE_NAME" MINOS_VERSION="$VERSION" MINOS_DEV="$DEV" MINOS_KERNEL_PKGS="$KERNEL_PKGS" \
    "$@"
}

# ---------- 1. rootfs ----------
if [ "$REUSE_ROOTFS" = 1 ] && [ -d "$ROOTFS/usr" ]; then
  log "1/4 rootfs 재사용: $ROOTFS"
else
  log "1/4 rootfs 생성: $SUITE_NAME ($ARCH) from $MIRROR"
  rm -rf "$ROOTFS"
  INCLUDE=$(pkglist "$CONF/packages.base" "$CONF/packages.desktop")
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
rm -rf "$ROOTFS/tmp/minos-src" "$ROOTFS/tmp/minos-hooks"
mkdir -p "$ROOTFS/tmp/minos-src"
rsync -a --exclude build --exclude 'build-*' --exclude out --exclude image/work --exclude .git \
  "$REPO/CMakeLists.txt" "$REPO/libs" "$REPO/shell" "$REPO/session" "$REPO/image" "$ROOTFS/tmp/minos-src/"
cp -a "$CONF/hooks" "$ROOTFS/tmp/minos-hooks"
chroot_mount
for hook in "$ROOTFS"/tmp/minos-hooks/*.sh; do
  name=$(basename "$hook")
  log "   hook $name"
  run_in_chroot /bin/bash "/tmp/minos-hooks/$name"
done
chroot_umount
rm -rf "$ROOTFS/tmp/minos-src" "$ROOTFS/tmp/minos-hooks"
fi

[ "$NO_ISO" = 1 ] && { log "rootfs 준비 완료 (--no-iso): $ROOTFS"; exit 0; }

# ---------- 3. squashfs ----------
log "3/4 squashfs"
rm -rf "$ISOROOT"
mkdir -p "$ISOROOT/live" "$ISOROOT/boot/grub" "$ISOROOT/EFI/BOOT"
cp -L "$ROOTFS/boot/vmlinuz" "$ISOROOT/live/vmlinuz"
cp -L "$ROOTFS/boot/initrd.img" "$ISOROOT/live/initrd.img"
mksquashfs "$ROOTFS" "$ISOROOT/live/filesystem.squashfs" -comp zstd -Xcompression-level 15 -b 1M \
  -noappend -no-progress -quiet -e proc sys dev run tmp 'var/cache/apt' 2>&1 | tail -3 || true
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
  -volid "MINOS" \
  -eltorito-boot boot/grub/bios.img -no-emul-boot -boot-load-size 4 -boot-info-table \
  --eltorito-catalog boot/grub/boot.cat --grub2-boot-info \
  --grub2-mbr /usr/lib/grub/i386-pc/boot_hybrid.img \
  -eltorito-alt-boot -e EFI/efiboot.img -no-emul-boot \
  -append_partition 2 0xef "$EFIIMG" \
  -o "$OUTPUT" "$ISOROOT" 2>&1 | grep -vE '^xorriso : UPDATE' | tail -5

log "완료: $OUTPUT ($(du -h "$OUTPUT" | cut -f1))"
echo "   실행: image/qemu/run.sh $OUTPUT    또는    make run ISO=$OUTPUT"
