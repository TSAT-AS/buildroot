#!/usr/bin/env bash
set -e

if [ "$TSAT_RELEASE" = "1" ]; then
  SIGN_OPT=('--release')
fi

MKSWU="$HOST_DIR/bin/mkswu.py"

cd -- "$1"
$MKSWU "${SIGN_OPT[@]}" fpga 'fpga.tar.gz'
$MKSWU "${SIGN_OPT[@]}" terminal 'terminal.tar.gz'
$MKSWU "${SIGN_OPT[@]}" system 'kernel-ramdisk-dtb.itb'
$MKSWU "${SIGN_OPT[@]}" full 'kernel-ramdisk-dtb.itb' 'terminal.tar.gz' 'fpga.tar.gz'
