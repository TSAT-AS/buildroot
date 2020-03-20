#!/bin/sh

set -e

# create boot-, env- and kernel filesystems
support/scripts/genimage.sh -c board/tsat/3500/mmc/images/filesystems.cfg

# create appfs filesystem
APPFS_INPUT="$1/appfs"
APPFS_OUTOUT="$1/appfs.ext4"
APPFS_SIZE='256M'
test -d "$APPFS_INPUT" || exit 1
output/host/sbin/mkfs.ext4 -v -d "$APPFS_INPUT" -E 'root_owner=0:0,lazy_itable_init=0,lazy_journal_init=0' -L 'APP' -O '^64bit' "$APPFS_OUTOUT" "$APPFS_SIZE"

# use generated filesystems and create mmc image
support/scripts/genimage.sh -c board/tsat/3500/mmc/images/mmc.cfg
