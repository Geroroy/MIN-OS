#!/bin/bash
# 디스크 이미지용 UEFI 부트로더: 대상 아키텍처의 GRUB을 chroot 안에서 생성한다 (호스트에 교차 GRUB 패키지가 없어도 됨).
# 결과: /boot/efi-staging/BOOT<ARCH>.EFI — build.sh 가 ESP 파티션에 복사한다. 직접 커널 부팅(-kernel/-initrd)과 병행 지원.
set -euo pipefail
[ "${MINOS_FORMAT:-iso}" = disk ] || exit 0
export DEBIAN_FRONTEND=noninteractive
case "${MINOS_ARCH:-amd64}" in
  arm64) PKG=grub-efi-arm64-bin; TARGET=arm64-efi; EFI=BOOTAA64.EFI ;;
  amd64) PKG=grub-efi-amd64-bin; TARGET=x86_64-efi; EFI=BOOTX64.EFI ;;
  *) echo "unsupported arch ${MINOS_ARCH}"; exit 1 ;;
esac
[ -n "$(ls /var/lib/apt/lists 2>/dev/null)" ] || apt-get update >/tmp/minos-apt-update.log 2>&1
apt-get install -y --no-install-recommends "$PKG" grub-common >/tmp/minos-grub.log 2>&1 || { tail -20 /tmp/minos-grub.log; exit 1; }

install -Dm644 /tmp/minos-src/image/grub/grub-disk.cfg /boot/grub/grub.cfg
sed -i "s/@VERSION@/${MINOS_VERSION:-dev}/; s/@SUITE@/${MINOS_SUITE:-}/; s/@ARCH@/${MINOS_ARCH}/" /boot/grub/grub.cfg
# mobile 프로필(TCG 전제)은 기본 항목부터 소프트웨어 렌더링
if [ "${MINOS_PROFILE:-default}" = mobile ]; then sed -i 's/@RENDER@/minos.render=software/' /boot/grub/grub.cfg; else sed -i 's/ @RENDER@//' /boot/grub/grub.cfg; fi
if [ "${MINOS_ARCH}" = arm64 ]; then
  sed -i 's/@CONSOLE@/console=tty1 console=ttyAMA0,115200/' /boot/grub/grub.cfg
else
  sed -i 's/@CONSOLE@/console=tty1 console=ttyS0,115200/' /boot/grub/grub.cfg
fi
cat > /tmp/early.cfg <<'E'
search --no-floppy --set=root --label minos-root
set prefix=($root)/boot/grub
configfile ($root)/boot/grub/grub.cfg
E
mkdir -p /boot/efi-staging
grub-mkstandalone -O "$TARGET" -o "/boot/efi-staging/$EFI" --locales="" --fonts="" \
  --modules="part_gpt part_msdos ext2 fat gzio search search_label search_fs_uuid normal configfile linux echo ls cat serial terminal all_video gfxterm font reboot halt" \
  "boot/grub/grub.cfg=/tmp/early.cfg" >/tmp/minos-grub-mk.log 2>&1 || { tail -20 /tmp/minos-grub-mk.log; exit 1; }
ls -la "/boot/efi-staging/$EFI"
