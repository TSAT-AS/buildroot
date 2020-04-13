#!/bin/sh

set -e

# create appfs filesystem
APPFS_INPUT="$1/appfs"
APPFS_OUTPUT="$1/appfs.jffs2"
test -d "$APPFS_INPUT" || exit 1
test -f "$APPFS_OUTPUT" && rm "$APPFS_OUTPUT"
output/host/sbin/mkfs.jffs2 -v -U -e 256 -l -d "$APPFS_INPUT" -o "$APPFS_OUTPUT"

# generate qspi full image
cp -- board/tsat/3500/qspi/images/full.bif "$1"

FULL_IMG='qspi.img'
echo "Creating full QSPI image: $1/$FULL_IMG"

cd -- "$1"
mkbootimage full.bif "$FULL_IMG"

# generate qspi swu packages
export KEY="$HOST_DIR/usr/share/mkswu/private.pem"
$HOST_DIR/bin/mkswu-qspi-system 'uImage' 'devicetree.dtb' 'rootfs.squashfs'
$HOST_DIR/bin/mkswu-qspi-full 'qspi-system.swu' 'terminal.swu' 'fpga.swu'
