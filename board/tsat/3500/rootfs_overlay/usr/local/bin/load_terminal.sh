#!/bin/sh
set -e # fail fast

RUN_SCRIPT='run.sh'
BASE_DIR='/root'

CURRENT_BASE_DIR="$BASE_DIR/current"
NEXT_BASE_DIR="$BASE_DIR/next"

CURRENT_RUN_SCRIPT="$CURRENT_BASE_DIR/$RUN_SCRIPT"
NEXT_RUN_SCRIPT="$NEXT_BASE_DIR/$RUN_SCRIPT"

# start new terminal if "next" symlink exist and it contains a run script
if [ -h "$NEXT_BASE_DIR" ]; then
  if [ -f "$NEXT_RUN_SCRIPT" ]; then
    # dereference and remove the "next" symlink:
    # the new terminal binary will update the 'current' base symlink to point
    # to the new base if all internal tests pass
    DEREF_RUN_SCRIPT=$(/usr/bin/readlink -fn "$NEXT_RUN_SCRIPT")
    rm "$NEXT_BASE_DIR"

    echo "starting new terminal with: $DEREF_RUN_SCRIPT"
    exec "$DEREF_RUN_SCRIPT"
  else
    echo "FAIL: new terminal run script '$NEXT_RUN_SCRIPT' does not exist"
    rm "$NEXT_BASE_DIR"
  fi
fi

# start regular terminal
if [ ! -f "$CURRENT_RUN_SCRIPT" ]; then
  echo "FAIL: terminal run script '$CURRENT_RUN_SCRIPT' does not exist"
  exit 1
fi

echo "starting regular terminal with: $CURRENT_RUN_SCRIPT"
exec $CURRENT_RUN_SCRIPT
