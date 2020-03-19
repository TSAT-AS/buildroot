#!/bin/sh

set -e

# create the app partition filesystem
output/host/sbin/mkfs.jffs2 -v -U -e 256 -l -d "$1/appfs" -o "$1/appfs.jffs2"

# generate qspi full image
cp -- board/tsat/3500/qspi/images/full.bif "$1"

FULL_IMG='full_qspi.bin'
echo "Creating full QSPI image: $1/$FULL_IMG"

cd -- "$1"
mkbootimage full.bif "$FULL_IMG"
