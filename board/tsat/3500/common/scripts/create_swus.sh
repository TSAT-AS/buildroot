#!/usr/bin/env bash
set -e

if [ "$BUILD_TYPE" = "PROD" ]; then
  SIGN_OPT=('--sign')

  # override openssl config
  export OPENSSL_CONF="$WORK/openssl.cnf"
fi

MKSWU="$HOST_DIR/bin/mkswu.py"

cd -- "$1"
$MKSWU "${SIGN_OPT[@]}" fpga 'fpga.tar.gz'
$MKSWU "${SIGN_OPT[@]}" terminal 'terminal.tar.gz'
$MKSWU "${SIGN_OPT[@]}" system 'kernel-ramdisk-dtb.itb'
$MKSWU "${SIGN_OPT[@]}" full 'kernel-ramdisk-dtb.itb' 'terminal.tar.gz' 'fpga.tar.gz'
