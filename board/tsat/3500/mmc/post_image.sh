#!/bin/sh

# create the app partition filesystem
output/host/sbin/mkfs.ext4 -v -d "$1/appfs" -E 'root_owner=0:0,lazy_itable_init=0,lazy_journal_init=0' -L 'APP' -O '^64bit' "$1/appfs.ext4" 256M

# generate mmc full image
support/scripts/genimage.sh -c board/tsat/3500/mmc/images/genimage.cfg
