#!/usr/bin/env bash
set -e

# normalize U-Boot filename (for bootgen)
UBOOT="$1/u-boot"
if [ -f "$UBOOT" ]; then
  mv -v -- "$UBOOT" "$UBOOT.elf"
fi
