#!/bin/sh
# Usage: load_ko.sh <absolute-path-to-ko-file>

set -e # fail fast

KO_FILE="$1"
STATUS_MSG="Loading KO ($KO_FILE)"

if [ "$#" -lt "1" ]; then
  echo "$STATUS_MSG: FAIL (ko not specified)"
  exit 1
fi

if [ ! -f "$KO_FILE" ]; then
  echo "$STATUS_MSG: FAIL (ko does not exist)"
  exit 1
fi

/sbin/insmod $KO_FILE
if [ $? -ne 0 ]; then
    echo "$STATUS_MSG: FAIL (insmod)"
    exit 1
fi

echo "$STATUS_MSG: OK"
