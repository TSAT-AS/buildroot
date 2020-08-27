#!/usr/bin/env bash

set -e

# create appfs filesystem
APPFS_INPUT="$1/appfs"
APPFS_OUTPUT="$1/appfs.ext4"
APPFS_SIZE='256M'
test -d "$APPFS_INPUT" || exit 1
test -f "$APPFS_OUTPUT" && rm "$APPFS_OUTPUT"
output/host/sbin/mkfs.ext4 -v -d "$APPFS_INPUT" -E 'root_owner=0:0,lazy_itable_init=0,lazy_journal_init=0' -L 'APP' -O '^64bit' "$APPFS_OUTPUT" "$APPFS_SIZE"

# build boot image
cp -- board/tsat/3500/common/images/boot.bif "$1"
BOOT_IMG='boot.bin'
echo "Creating boot image: $1/$BOOT_IMG"
pushd "$1"
bootgen -image boot.bif -arch zynq -o "$BOOT_IMG" -w on -log info
popd

# create boot-, env- and kernel filesystems
support/scripts/genimage.sh -c board/tsat/3500/mmc/images/filesystems.cfg

# use generated filesystems and create mmc image
support/scripts/genimage.sh -c board/tsat/3500/mmc/images/mmc.cfg

# generate mmc swu packages
cd -- "$1"
export KEY="$HOST_DIR/usr/share/mkswu/private.pem"
export POSTSCRIPT="$HOST_DIR/usr/share/mkswu/mmc-system-postinstall.sh"
$HOST_DIR/bin/mkswu-mmc-system 'kernel.vfat' 'rootfs.ext4'
$HOST_DIR/bin/mkswu-mmc-full 'mmc-system.swu' 'terminal.swu' 'fpga.swu'
