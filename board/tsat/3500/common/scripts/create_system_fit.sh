#!/usr/bin/env bash
set -e

MKMAGE="$HOST_DIR/bin/mkimage"

echo "create system FIT..."
if [ "$BUILD_TYPE" = "PROD" ]; then
  FIT_SRC='kernel-ramdisk-dtb-release.its'
else
  FIT_SRC='kernel-ramdisk-dtb-debug.its'
fi

cp -v -- "board/tsat/3500/common/images/$FIT_SRC" "$1"
cd -- "$1"

$MKMAGE -f "$FIT_SRC" 'kernel-ramdisk-dtb.itb'

# sign image
if [ "$BUILD_TYPE" = "PROD" ]; then
  # override openssl config
  export OPENSSL_CONF="$WORK/openssl.cnf"

  echo "sign system FIT..."
  $MKMAGE -F 'kernel-ramdisk-dtb.itb' -k 'id=%15' -N pkcs11 -K 'u-boot.dtb' -c "Signed by build system" -r
fi
