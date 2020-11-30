#!/usr/bin/env bash
set -e

# create default boot-selector and boot-count
echo -en "\xaa" > "$1/default_selector.bin"
echo -en "\x00" > "$1/default_count.bin"
