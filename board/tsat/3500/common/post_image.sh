#!/usr/bin/env bash
set -e

# define build type as defined in defconfig
export BUILD_TYPE="$2"

# define work area
export WORK="$(mktemp -d -p /dev/shm)"

# copy in essential binaries
cp -- ../binaries/fsbl.elf "$1"
cp -- ../binaries/fpga.bit "$1"

SCRIPTS='./board/tsat/3500/common/scripts/'
$SCRIPTS/prepare_openssl.sh "$@"
$SCRIPTS/prepare_keys.sh "$@"
$SCRIPTS/normalize_filenames.sh "$@"
$SCRIPTS/create_system_fit.sh "$@"
$SCRIPTS/create_uboot_script.sh "$@"
$SCRIPTS/create_default_boot_vars.sh "$@"
$SCRIPTS/create_version_info.sh "$@"
$SCRIPTS/create_appfs.sh "$@"
$SCRIPTS/create_boot_image.sh "$@"
$SCRIPTS/create_swus.sh "$@"

# remove work area
rm -rf -- "$WORK"
