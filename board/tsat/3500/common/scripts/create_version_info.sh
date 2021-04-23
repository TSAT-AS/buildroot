#!/usr/bin/env bash

set -e

echo "create version info"

BUILD_DATETIME="$(date --iso-8601="seconds")"

# git helpers
git_describe(){ git describe --tags --long -- "$@"; } # get version string
git_commit_hash(){ git log -1 --pretty="format:%H" -- "$@"; } # get full commit hash
git_commit_hash_short(){ git log -1 --pretty="format:%h" -- "$@"; } # get short commit hash
git_commit_date(){ git log -1 --pretty="format:%cI" -- "$@"; } # get comitter date in strict ISO 8601 format

# get buildroot/system info
git fetch --deepen 200 # get more history in case of shallow clone (jenkins currently does this)
git fetch --tags # get all tags in case of shallow clone (jenkins currently does this)
BUILDROOT_GIT_DESCRIBE="$(git_describe)"
BUILDROOT_GIT_COMMIT="$(git_commit_hash)"
BUILDROOT_GIT_DATETIME="$(git_commit_date)"

# create system fit image checksum
SYSTEM_FIT_IMAGE="$1/kernel-ramdisk-dtb.itb"
SYSTEM_FIT_IMAGE_PADDED="${SYSTEM_FIT_IMAGE}.padded"
cp "$SYSTEM_FIT_IMAGE" "$SYSTEM_FIT_IMAGE_PADDED"
SYSTEM_PARTITION_SIZE='0xC00000'
SYSTEM_FIT_IMAGE_SIZE="$(stat --printf="%s" $SYSTEM_FIT_IMAGE_PADDED)"
SYSTEM_PADDING_SIZE="$(($SYSTEM_PARTITION_SIZE - $SYSTEM_FIT_IMAGE_SIZE))"
dd if=/dev/zero bs=1 count="$SYSTEM_PADDING_SIZE" | tr "\000" "\377" >> "$SYSTEM_FIT_IMAGE_PADDED"
SYSTEM_FIT_IMAGE_PADDED_SHA256="$(sha256sum $SYSTEM_FIT_IMAGE_PADDED | cut -d' ' -f1)"

# get bsp-collection info
pushd "$BASE_DIR/../.."
git_describe_special()
{
  local LAST_MASTER_RELEASE_TAG="$(git describe --tags --abbrev=0 origin/master)"
  local LAST_COMMON_ANCESTOR="$(git merge-base $LAST_MASTER_RELEASE_TAG HEAD)"
  local COMMITTS_SINCE_RELEACE_TAG="$(git log --oneline --no-merges "$LAST_COMMON_ANCESTOR"..HEAD | wc -l)"
  local LATEST_COMMIT_HASH="$(git_commit_hash_short)"
  echo "$LAST_MASTER_RELEASE_TAG-$COMMITTS_SINCE_RELEACE_TAG-g$LATEST_COMMIT_HASH"
}
BSP_GIT_DESCRIBE="$(git_describe_special)"
BSP_GIT_COMMIT="$(git_commit_hash)"
BSP_GIT_DATETIME="$(git_commit_date)"
popd

# get terminal- and FPGA info
pushd "$BR2_DL_DIR/terminal/git"
TERMINAL_GIT_DESCRIBE="$(git_describe_special)"
TERMINAL_GIT_COMMIT="$(git_commit_hash)"
TERMINAL_GIT_DATETIME="$(git_commit_date)"
FPGA_ID="$(grep -o 'FPGA_VER ".*"' CMakeLists.txt | cut -d'"' -f2)"
FPGA_GIT_COMMIT="$(git_commit_hash "fpga_api/$FPGA_ID")"
FPGA_GIT_COMMIT_SHORT="$(git_commit_hash_short "fpga_api/$FPGA_ID")"
FPGA_GIT_DESCRIBE="$FPGA_ID-0-g$FPGA_GIT_COMMIT_SHORT"
FPGA_GIT_DATETIME="$(git_commit_date "fpga_api/$FPGA_ID")"
popd

# create version info output dir
VERSION_DIR="$1/version_info"
mkdir -p -- "$VERSION_DIR"

# write release version file
(
  echo "build-datetime $BUILD_DATETIME"
  echo "release        $BSP_GIT_DESCRIBE"
  echo "system         $BUILDROOT_GIT_DESCRIBE"
  echo "terminal       $TERMINAL_GIT_DESCRIBE"
  echo "fpga           $FPGA_GIT_DESCRIBE"
) > "$VERSION_DIR/release"

# write system version file
(
  echo "build-datetime $BUILD_DATETIME"
  echo "version        $BUILDROOT_GIT_DESCRIBE"
  echo "commit         $BUILDROOT_GIT_COMMIT"
  echo "commit-date    $BUILDROOT_GIT_DATETIME"
  echo
  echo "sha256-partition $SYSTEM_FIT_IMAGE_PADDED_SHA256"
) > "$VERSION_DIR/system"

# write terminal version file
(
  echo "build-datetime $BUILD_DATETIME"
  echo "version        $TERMINAL_GIT_DESCRIBE"
  echo "commit         $TERMINAL_GIT_COMMIT"
  echo "commit-date    $TERMINAL_GIT_DATETIME"
) > "$VERSION_DIR/terminal"

# write fpga version file
(
  echo "build-datetime $BUILD_DATETIME"
  echo "version        $FPGA_GIT_DESCRIBE"
  echo "commit         $FPGA_GIT_COMMIT"
  echo "commit-date    $FPGA_GIT_DATETIME"
) > "$VERSION_DIR/fpga"
