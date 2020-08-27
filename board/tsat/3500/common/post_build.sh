#!/bin/sh

SWU_KEY_SRC_DIR='board/tsat/3500/common/keys'
SWU_KEY_DST_DIR="$TARGET_DIR/usr/local/share"
SWU_KEY_DST_NAME='public.pem'

if [ "$RELEASE" = "1" ]; then
  SWU_KEY_SRC_NAME='swu-debug-pub.pem'
else
  SWU_KEY_SRC_NAME='swu-debug-pub.pem'
fi

mkdir -p -- "$SWU_KEY_DST_DIR"
cp -- "$SWU_KEY_SRC_DIR/$SWU_KEY_SRC_NAME" "$SWU_KEY_DST_DIR/$SWU_KEY_DST_NAME"
