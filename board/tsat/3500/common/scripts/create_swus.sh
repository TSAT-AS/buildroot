#!/usr/bin/env bash
set -e

if [ "$BUILD_TYPE" = "PROD" ]; then
  SIGN_OPT=('--sign')

  # override openssl config
  export OPENSSL_CONF="$WORK/openssl.cnf"
fi

MKSWU="$HOST_DIR/bin/mkswu.py"

cd -- "$1"
VERSION_DIR='version_info'
$MKSWU "${SIGN_OPT[@]}" fpga "$VERSION_DIR/fpga" 'fpga.tar.gz'
$MKSWU "${SIGN_OPT[@]}" terminal "$VERSION_DIR/terminal" 'terminal.tar.gz'
$MKSWU "${SIGN_OPT[@]}" system "$VERSION_DIR/system" 'kernel-ramdisk-dtb.itb'
$MKSWU "${SIGN_OPT[@]}" full "$VERSION_DIR/release" 'kernel-ramdisk-dtb.itb' 'terminal.tar.gz' 'fpga.tar.gz'
