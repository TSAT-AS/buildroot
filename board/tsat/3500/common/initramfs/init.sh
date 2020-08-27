#!/bin/sh

DM_NAME='rootfs'
NEW_ROOT='/.squashfs'

VERITY_DATA_DEVICE="$rootfsdev" # boot arg variable made available in shell env
VERITY_HASH_DEVICE="$VERITY_DATA_DEVICE" # hash appended to squashfs on same dev
VERITY_HASH_OFFSET="$(cat /verity-hash-dev-offset)"
VERITY_ROOT_HASH="$(cat /verity-root-hash)"

busybox mount -t sysfs /sys /sys
busybox mount -t tmpfs /dev /dev
busybox mount -t proc /proc /proc
busybox mdev -s

veritysetup \
  --hash-offset="$VERITY_HASH_OFFSET" \
  open \
  "$VERITY_DATA_DEVICE" \
  "$DM_NAME" \
  "$VERITY_HASH_DEVICE" \
  "$VERITY_ROOT_HASH"

busybox mkdir "$NEW_ROOT"
if busybox mount -t squashfs "/dev/mapper/$DM_NAME" "$NEW_ROOT"; then
  echo "Filesystem '$rootfsdev': verified"
  busybox mount --move /dev  "$NEW_ROOT"/dev
  exec busybox switch_root "$NEW_ROOT" /sbin/init
fi

echo "Filesystem '$rootfsdev' verification: FAIL"
export PS1='(initramfs) '
exec /bin/sh
