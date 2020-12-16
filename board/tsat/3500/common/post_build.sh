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
VERSION_FILE="$TARGET_DIR/etc/sw-versions"
BSP_GIT_DESCRIBE="$(cd $BASE_DIR/../.. && git describe --tags --long | sed 's/-[0-9]*-g/-/')"
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
BUILDROOT_GIT_DESCRIBE="$(git describe --tags --long | sed 's/-[0-9]*-g/-/')"

sed -i "s/@PLACEHOLDER_RELEASE_VERSION@/$BSP_GIT_DESCRIBE/g" $VERSION_FILE
sed -i "s/@PLACEHOLDER_SYSTEM_VERSION@/$BUILDROOT_GIT_DESCRIBE/g" $VERSION_FILE
