#!/bin/sh

SWU_KEY_SRC_DIR='../keys'
SWU_KEY_DST_DIR="$TARGET_DIR/usr/local/share"
SWU_KEY_DST_NAME='public.pem'

if [ "$TSAT_SECURE" = "1" ]; then
  SWU_KEY_SRC_NAME='swu-release-pub.pem'
else
  SWU_KEY_SRC_NAME='swu-debug-pub.pem'
fi

mkdir -p -- "$SWU_KEY_DST_DIR"
cp -- "$SWU_KEY_SRC_DIR/$SWU_KEY_SRC_NAME" "$SWU_KEY_DST_DIR/$SWU_KEY_DST_NAME"

VERSION_FILE="$TARGET_DIR/etc/sw-versions"
BSP_GIT_DESCRIBE="$(cd $BASE_DIR/../.. && git describe --tags --long | sed 's/-[0-9]*-g/-/')"
if [ -z $BSP_GIT_DESCRIBE ]; then
  BSP_GIT_DESCRIBE='UNKNOWN'
fi
BUILDROOT_GIT_DESCRIBE="$(git describe --tags --long | sed 's/-[0-9]*-g/-/')"

sed -i "s/@PLACEHOLDER_RELEASE_VERSION@/$BSP_GIT_DESCRIBE/g" $VERSION_FILE
sed -i "s/@PLACEHOLDER_SYSTEM_VERSION@/$BUILDROOT_GIT_DESCRIBE/g" $VERSION_FILE
