#!/bin/sh
# Usage: load_kos.sh

set -e # fail fast

KO_FILE="$1"
STATUS_MSG="Loading KO"
MB_REV=$(hexdump -s 14 -d -n 2 /sys/class/i2c-dev/i2c-1/device/1-0050/eeprom | cut -c 11- | head -n 1 | sed 's/^0*//' | tr -d " \t\n\r")

case $MB_REV in
  1)
    /sbin/insmod /lib/modules/4.14.0-xilinx/extra/adrf6755.ko
    ;;
  2)
    /sbin/insmod /lib/modules/4.14.0-xilinx/extra/adrf6755.ko
    /sbin/insmod /lib/modules/4.14.0-xilinx/extra/tps65233.ko
    ;;
  *)
    echo "$STATUS_MSG: FAIL (boardrev does not exist)"
    exit 1
    ;;
esac

if [ $? -ne 0 ]; then
    echo "$STATUS_MSG: FAIL (insmod)"
    exit 1
fi

echo "$STATUS_MSG: OK"
