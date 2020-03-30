#!/bin/sh
# Usage: load_fpga.sh <path-to-xz-compressed-fpga-image

set -e # fail fast

FW_PATH='/lib/firmware'
FPGA_FILE="$1"
STATUS_MSG="Loading FPGA ($FPGA_FILE)"

if [ "$#" -lt "1" ]; then
  echo "$STATUS_MSG: FAIL (FPGA not specified, e.g. fpga_turbo_high.bit.bin.xz)"
  exit 1
fi

if [ ! -f "$FPGA_FILE" ]; then
  echo "$STATUS_MSG: FAIL (FPGA does not exist)"
  exit 1
fi

FPGA_MD5="$(md5sum "$FPGA_FILE" | cut -d' ' -f1)"
FPGA_NAME="${FPGA_MD5}"

# cleanup existing files in the firmware directory
rm -- $FW_PATH/* 2>/dev/null

# extract the specified FPGA image into the firmware directory
unxz -c -- "$FPGA_FILE" > "$FW_PATH/$FPGA_NAME"

# take down network interfaces since these will be affected
ip link set down dev eth0
ip link set down dev eth1

# load FPGA
echo 0 > /sys/class/fpga_manager/fpga0/flags
echo "$FPGA_NAME" > /sys/class/fpga_manager/fpga0/firmware

# bring up network interfaces...twice(bug?)
sleep 3
ip link set up dev eth0 || ip link set up dev eth0
ip link set up dev eth1 || ip link set up dev eth1

echo "$STATUS_MSG: OK"
