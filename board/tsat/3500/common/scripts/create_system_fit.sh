#!/usr/bin/env bash
set -e

MKMAGE="$HOST_DIR/bin/mkimage"

echo "create system FIT..."
if [ "$TSAT_RELEASE" = "1" ]; then
  FIT_SRC='kernel-ramdisk-dtb-release.its'
else
  FIT_SRC='kernel-ramdisk-dtb-debug.its'
fi

cp -v -- "board/tsat/3500/common/images/$FIT_SRC" "$1"
cd -- "$1"

$MKMAGE -f "$FIT_SRC" 'kernel-ramdisk-dtb.itb'

# sign release builds
if [ "$TSAT_RELEASE" = "1" ]; then
  echo "sign system FIT..."
  $MKMAGE -F 'kernel-ramdisk-dtb.itb' -k 'id=%15' -N pkcs11 -K 'u-boot.dtb' -c "Signed by build system" -r
fi
