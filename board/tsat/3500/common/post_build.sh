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

# set version build info
GIT_DESCRIBE_CMD='git describe --tags --long'
GIT_DATETIME_CMD='git log -1 --date=format:%F_%T --pretty=format:%cd'

BUILDROOT_GIT_DESCRIBE="$($GIT_DESCRIBE_CMD)"
BUILDROOT_GIT_DATETIME="$($GIT_DATETIME_CMD)"

BSP_DIR="$BASE_DIR/../.."
BSP_GIT_DESCRIBE="$(cd "$BSP_DIR" && "$GIT_DESCRIBE_CMD")"
if [ -z $BSP_GIT_DESCRIBE ]; then
  if [ "$BUILD_TYPE" = "PROD" ]; then
    echo "ERROR: could not determine release version"
    echo "Buildroot must be a child of master-bsp-collection"
    exit 1
  else
    echo "Buildroot not a child of master-bsp-collection, use 'develop' as release tag"
    BSP_GIT_DESCRIBE="develop"
  fi
fi
BSP_GIT_DATETIME="$(cd "$BSP_DIR" && $GIT_DATETIME_CMD)"

TERMINAL_DIR="$BR2_DL_DIR/terminal/git"
TERMINAL_GIT_DESCRIBE="$(cd "$TERMINAL_DIR" && $GIT_DESCRIBE_CMD)"
TERMINAL_GIT_DATETIME="$(cd "$TERMINAL_DIR" && $GIT_DATETIME_CMD)"

FPGA_ID="$(grep -o 'FPGA_VER ".*"' $TERMINAL_DIR/CMakeLists.txt | cut -d'"' -f2)"
FPGA_COMMIT_HASH="$(cd "$TERMINAL_DIR" && git log -1 --pretty=format:%h -- fpga_api/$FPGA_ID)"
FPGA_GIT_DATETIME="$(cd "$TERMINAL_DIR" && $GIT_DATETIME_CMD -- fpga_api/$FPGA_ID)"

normalize()
{
  echo "$1" | sed 's/-[0-9]*-g/-/'
}
BSP_VERSION="$(normalize "$BSP_GIT_DESCRIBE")"
BUILDROOT_VERSION="$(normalize "$BUILDROOT_GIT_DESCRIBE")"
TERMINAL_VERSION="$(normalize "$TERMINAL_GIT_DESCRIBE")"
FPGA_VERSION="$FPGA_ID-$FPGA_COMMIT_HASH"

(
  echo "release $BSP_VERSION"
  echo "system $BUILDROOT_VERSION"
  echo "terminal $TERMINAL_VERSION"
  echo "fpga $FPGA_VERSION"
  echo "release-datetime $BSP_GIT_DATETIME"
  echo "system-datetime $BUILDROOT_GIT_DATETIME"
  echo "terminal-datetime $TERMINAL_GIT_DATETIME"
  echo "fpga-datetime $FPGA_GIT_DATETIME"
) > "$TARGET_DIR/etc/sw-versions"
