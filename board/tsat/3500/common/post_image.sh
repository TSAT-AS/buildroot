#!/bin/sh

set -e

# normalize U-Boot filename (for bootgen)
UBOOT="$1/u-boot"
if [ -f "$UBOOT" ]; then
  mv -v -- "$UBOOT" "$UBOOT.elf"
fi

# populate appfs directory
APPFS_DIR="$1/appfs"
APPFS_FPGA_DIR="$APPFS_DIR/fpga"
APPFS_TERM_DIR="$APPFS_DIR/terminal"
mkdir -p "$APPFS_DIR"
mkdir -p "$APPFS_FPGA_DIR"
mkdir -p "$APPFS_TERM_DIR"
tar -x --no-same-owner -v -f "$1/fpga.tar.gz" -C "$APPFS_FPGA_DIR"
tar -x --no-same-owner -v -f "$1/terminal.tar.gz" -C "$APPFS_TERM_DIR"
ln -snf "$(basename "$APPFS_FPGA_DIR")/fpga_viterbi_low.bit" "$APPFS_DIR/fpga.bit"
ln -snf "$(basename "$APPFS_TERM_DIR")" "$APPFS_DIR/current"

# create FIT image
echo "create system FIT..."
if [ "$TSAT_RELEASE" = "1" ]; then
  FIT_SRC='kernel-ramdisk-dtb-release.its'
else
  FIT_SRC='kernel-ramdisk-dtb-debug.its'
fi
cp -v -- "board/tsat/3500/common/images/$FIT_SRC" "$1"
mkimage -f "$1/$FIT_SRC" "$1/kernel-ramdisk-dtb.itb"

# sign FIT image (only in release builds)
if [ "$TSAT_RELEASE" = "1" ]; then
  echo "sign system FIT..."
  mkimage -F "$1/kernel-ramdisk-dtb.itb" -k 'id=%04' -N pkcs11 -K "$1/u-boot.dtb" -c "Signed by build system" -r
fi

# get files for boot image creation
cp -- ../binaries/fsbl.elf "$1"
cp -- ../binaries/fpga.bit "$1"

# create terminal and fpga SWUs
cd -- "$1"
$HOST_DIR/bin/mkswu.py fpga 'fpga.tar.gz'
$HOST_DIR/bin/mkswu.py terminal 'terminal.tar.gz'
