#!/usr/bin/env bash
set -e

MKMAGE="$HOST_DIR/bin/mkimage"

# build boot script FIT image
cp -v -- board/tsat/3500/common/images/u-boot-script.its "$1"
cp -v -- board/tsat/3500/common/uboot/boot_script.txt "$1"
$MKMAGE -f "$1/u-boot-script.its" "$1/u-boot-script.itb"
