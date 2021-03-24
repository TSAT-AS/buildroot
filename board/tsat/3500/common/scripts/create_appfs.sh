#!/usr/bin/env bash
set -e

MKFS="$HOST_DIR/sbin/mkfs.ubifs"
UBINIZE="$HOST_DIR/sbin/ubinize"

# UBI/UBIFS input parameters described in http://www.linux-mtd.infradead.org/faq/ubifs.html#L_mkfubifs
# values found on target by running 'mtdinfo -u /dev/mtdX' and 'ubinfo -a':

# > mtdinfo -u /dev/mtd7
# Name:                           appfs
# Type:                           nor
# Eraseblock size:                262144 bytes, 256.0 KiB
# Amount of eraseblocks:          130 (34078720 bytes, 32.5 MiB)
# Minimum input/output unit size: 1 byte
# Sub-page size:                  1 byte
# Character device major/minor:   90:16
# Bad blocks are allowed:         false
# Device is writable:             true
# Default UBI VID header offset:  64
# Default UBI data offset:        128
# Default UBI LEB size:           262016 bytes, 255.8 KiB
# Maximum UBI volumes count:      128
#
# UBI version:                    1
# Count of UBI devices:           1
# UBI control device major/minor: 10:59
# Present UBI devices:            ubi0

# > ubinfo -a
# ubi0
# Volumes count:                           1
# Logical eraseblock size:                 262016 bytes, 255.8 KiB
# Total amount of logical eraseblocks:     135 (35372160 bytes, 33.7 MiB)
# Amount of available logical eraseblocks: 0 (0 bytes)
# Maximum count of volumes                 128
# Count of bad physical eraseblocks:       0
# Count of reserved physical eraseblocks:  0
# Current maximum erase counter value:     1
# Minimum input/output unit size:          1 byte
# Character device major/minor:            245:0
# Present volumes:                         1
#
# Volume ID:   1 (on ubi0)
# Type:        dynamic
# Alignment:   1
# Size:        131 LEBs (34324096 bytes, 32.7 MiB)
# State:       OK
# Name:        appfs
# Character device major/minor: 245:2

# populate appfs directory
APPFS_DIR="$1/appfs"
APPFS_FPGA_DIR="$APPFS_DIR/fpga"
APPFS_TERM_DIR="$APPFS_DIR/terminal"
APPFS_VERSION_DIR="$APPFS_DIR/version"
mkdir -p "$APPFS_DIR"
mkdir -p "$APPFS_FPGA_DIR"
mkdir -p "$APPFS_TERM_DIR"
mkdir -p "$APPFS_VERSION_DIR"
tar -x --no-same-owner -v -f "$1/fpga.tar.gz" -C "$APPFS_FPGA_DIR"
tar -x --no-same-owner -v -f "$1/terminal.tar.gz" -C "$APPFS_TERM_DIR"
ln -snf "$(basename "$APPFS_FPGA_DIR")/fpga_viterbi_low.bit" "$APPFS_DIR/fpga.bit"
ln -snf "$(basename "$APPFS_TERM_DIR")" "$APPFS_DIR/current"
cp "$1"/version_info/* "$APPFS_VERSION_DIR"

# generate ubifs image
APPFS_OUTPUT="$1/appfs.ubifs"
test -f "$APPFS_OUTPUT" && rm "$APPFS_OUTPUT"
if [ "$BUILD_TYPE" = "PROD" ]; then
  CRYPT_OPT=('--cipher')
  CRYPT_OPT+=('AES-256-XTS')
  CRYPT_OPT+=('--key')
  CRYPT_OPT+=("$WORK/appfs.key")
fi
$MKFS --root="$APPFS_DIR" "${CRYPT_OPT[@]}" --min-io-size=1 --leb-size=262016 --max-leb-cnt=131 --output="$APPFS_OUTPUT" --squash-uids

# create ubi image
cp -- board/tsat/3500/common/images/ubi.cfg "$1"
UBI_IMAGE_INPUT="$1/ubi.cfg"
UBI_IMAGE_OUTPUT="$1/ubi.img"
test -f "$UBI_IMAGE_INPUT" || exit 1
test -f "$UBI_IMAGE_OUTPUT" && rm "$UBI_IMAGE_OUTPUT"
cd -- "$1"
$UBINIZE --output="$UBI_IMAGE_OUTPUT" --peb-size=256KiB --min-io-size=1 "$UBI_IMAGE_INPUT"
