#!/bin/sh

set -e

cp -- board/tsat/3500/qspi/images/full.bif "$1"

FULL_IMG='full_qspi.bin'
echo "Creating full QSPI image: $1/$FULL_IMG"

cd -- "$1"
mkbootimage full.bif "$FULL_IMG"
