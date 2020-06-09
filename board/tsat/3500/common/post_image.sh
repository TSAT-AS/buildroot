#!/bin/sh

set -e

# normalize U-Boot filename (for bootgen)
UBOOT="$1/u-boot"
if [ -f "$UBOOT" ]; then
  mv -v -- "$UBOOT" "$UBOOT.elf"
fi

# normalize Linux kernel filename (for bootgen)
KERNEL="$1/uImage"
if [ -f "$KERNEL" ]; then
  mv -v -- "$KERNEL" "$KERNEL.bin"
fi

# normalize devicetree filename
for dtb in $1/*.dtb; do
  if [ "$(basename "$dtb")" != 'devicetree.dtb' ]; then
    mv -v -- "$dtb" "$1/devicetree.dtb"
  fi
done

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

# build boot image
cp -- board/tsat/3500/common/images/boot.bif "$1"
cp -- ../binaries/fsbl.elf "$1"
cp -- ../binaries/fpga.bit "$1"

BOOT_IMG='boot.bin'
echo "Creating boot image: $1/$BOOT_IMG"

cd -- "$1"
bootgen -image boot.bif -arch zynq -o "$BOOT_IMG" -efuseppkbits hash_ppk.txt -w on -log info

# create terminal and fpga SWUs
export KEY="$HOST_DIR/usr/share/mkswu/private.pem"
export POSTSCRIPT="$HOST_DIR/usr/share/mkswu/fpga-postinstall.sh"
$HOST_DIR/bin/mkswu-fpga 'fpga.tar.gz'
export POSTSCRIPT="$HOST_DIR/usr/share/mkswu/terminal-postinstall.sh"
$HOST_DIR/bin/mkswu-terminal 'terminal.tar.gz'