#!/bin/sh

set -e

# normalize devicetree filename
for dtb in $1/*.dtb; do
  if [ "$(basename "$dtb")" != 'devicetree.dtb' ]; then
    mv -v -- "$dtb" "$1/devicetree.dtb"
  fi
done

# fetch latest terminal and fpga
FPGA_DIR="$1/fpga"
TERM_DIR="$1/terminal"
mkdir -p "$FPGA_DIR"
mkdir -p "$TERM_DIR"

. board/tsat/3500/common/constants.sh
scp "$HOST:$DIR_LATEST_FPGA/*.swu"        "$FPGA_DIR/fpga.swu"
scp "$HOST:$DIR_LATEST_FPGA/*.tar.gz"     "$FPGA_DIR/fpga.tar.gz"
scp "$HOST:$DIR_LATEST_TERMINAL/*.swu"    "$TERM_DIR/terminal.swu"
scp "$HOST:$DIR_LATEST_TERMINAL/*.tar.gz" "$TERM_DIR/terminal.tar.gz"

# populate appfs directory
APPFS_DIR="$1/appfs"
APPFS_FPGA_DIR="$APPFS_DIR/fpga"
APPFS_TERM_DIR="$APPFS_DIR/0"
mkdir -p "$APPFS_DIR"
mkdir -p "$APPFS_FPGA_DIR"
mkdir -p "$APPFS_TERM_DIR"

tar -x --no-same-owner -v -f "$FPGA_DIR/fpga.tar.gz" -C "$APPFS_FPGA_DIR"
tar -x --no-same-owner -v -f "$TERM_DIR/terminal.tar.gz" -C "$APPFS_TERM_DIR"
ln -snf "$(basename "$APPFS_FPGA_DIR")/fpga_viterbi_low.bit" "$APPFS_DIR/fpga.bit"
ln -snf "$(basename "$APPFS_TERM_DIR")" "$APPFS_DIR/current"

# build boot image
cp -- board/tsat/3500/common/images/boot.bif "$1"
cp -- ../binaries/fsbl.elf "$1"
cp -- ../binaries/fpga.bit "$1"

BOOT_IMG='boot.bin'
echo "Creating boot image: $1/$BOOT_IMG"

cd -- "$1"
mkbootimage boot.bif "$BOOT_IMG"
