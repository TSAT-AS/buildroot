#!/bin/sh

# define build type as defined in defconfig
export BUILD_TYPE="$2"

# add swupdate public key
if [ "$BUILD_TYPE" = "PROD" ]; then
  SWU_KEY_SRC_DIR='../keys'
  SWU_KEY_SRC_NAME='swu-release-pub.pem'
  SWU_KEY_DST_DIR="$TARGET_DIR/usr/local/share"
  SWU_KEY_DST_NAME='public.pem'
  mkdir -p -- "$SWU_KEY_DST_DIR"
  cp -- "$SWU_KEY_SRC_DIR/$SWU_KEY_SRC_NAME" "$SWU_KEY_DST_DIR/$SWU_KEY_DST_NAME"
fi
