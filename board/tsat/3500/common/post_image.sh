#!/bin/sh

set -e

cp -- board/tsat/3500/common/images/boot.bif "$1"
cp -- ../binaries/fsbl.elf "$1"
cp -- ../binaries/fpga.bit "$1"

BOOT_IMG='boot.bin'
echo "Creating boot image: $1/$BOOT_IMG"

cd -- "$1"
mkbootimage boot.bif "$BOOT_IMG"
