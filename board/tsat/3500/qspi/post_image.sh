#!/bin/sh

set -e

# create appfs filesystem
APPFS_INPUT="$1/appfs"
APPFS_OUTPUT="$1/appfs.jffs2"
test -d "$APPFS_INPUT" || exit 1
test -f "$APPFS_OUTPUT" && rm "$APPFS_OUTPUT"
output/host/sbin/mkfs.jffs2 -v -U -e 256 -l -d "$APPFS_INPUT" -o "$APPFS_OUTPUT"

# build boot script FIT image
cp -v -- board/tsat/3500/common/images/u-boot-script.its "$1"
cp -v -- board/tsat/3500/qspi/uboot/boot_script.txt "$1"
mkimage -f "$1/u-boot-script.its" "$1/u-boot-script.itb"

# generate qspi full image
cp -- board/tsat/3500/qspi/images/full.bif "$1"

FULL_IMG='qspi.img'
echo "Creating full QSPI image: $1/$FULL_IMG"

cd -- "$1"
bootgen -image full.bif -arch zynq -o "$FULL_IMG" -efuseppkbits hash_ppk.txt -w on -log info

# generate qspi swu packages
export KEY="$HOST_DIR/usr/share/mkswu/private.pem"
$HOST_DIR/bin/mkswu-qspi-system 'kernel-dtb.itb' 'rootfs.squashfs'
$HOST_DIR/bin/mkswu-qspi-full 'qspi-system.swu' 'terminal.swu' 'fpga.swu'
