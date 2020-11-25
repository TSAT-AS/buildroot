#!/usr/bin/env bash
set -e

# define build type as defined in defconfig
export BUILD_TYPE="$2"

# create work area
TMP_DIR=$(mktemp -d -p /dev/shm)
LINK_NAME="/dev/shm/tmp"
ln -snf "$TMP_DIR" "$LINK_NAME"

cp -- ../binaries/fsbl.elf "$1"
cp -- ../binaries/fpga.bit "$1"

SCRIPTS='./board/tsat/3500/common/scripts/'
$SCRIPTS/normalize_filenames.sh "$@"
$SCRIPTS/create_system_fit.sh "$@"
$SCRIPTS/create_uboot_script.sh "$@"
$SCRIPTS/create_default_boot_vars.sh "$@"
$SCRIPTS/prepare_keys.sh "$@"
$SCRIPTS/create_appfs.sh "$@"
$SCRIPTS/create_boot_image.sh "$@"
$SCRIPTS/create_swus.sh "$@"

# destroy work area
rm "$LINK_NAME"
rm -rf "$TMP_DIR"
