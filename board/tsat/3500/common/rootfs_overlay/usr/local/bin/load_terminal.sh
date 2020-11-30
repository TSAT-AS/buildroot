#!/bin/sh
set -e # fail fast

RUN_SCRIPT='run.sh'
BASE_DIR='/root'
NOAUTO_FLAG='/root/flags/noauto'

CURRENT_BASE_DIR="$BASE_DIR/current"
NEXT_BASE_DIR="$BASE_DIR/next"

CURRENT_RUN_SCRIPT="$CURRENT_BASE_DIR/$RUN_SCRIPT"
NEXT_RUN_SCRIPT="$NEXT_BASE_DIR/$RUN_SCRIPT"

MAX_TRIES=3
REMAINING_TRIES_FILE="/tmp/term_start_tries"

# do nothing if noauto flag is present
if [ -f "$NOAUTO_FLAG" ]; then
  sleep 30
  exit 0
fi

# give up if term crashes repeatedly
if [ -f "$REMAINING_TRIES_FILE" ]; then
  read REMAINING_TRIES < "$REMAINING_TRIES_FILE"
  REMAINING_TRIES=$(($REMAINING_TRIES-1))
  # all three tries used
  if [ "$REMAINING_TRIES" -le 0 ]; then
    echo "term crashed three times, giving up..."
    sleep 30
    exit 0
  fi
  echo $REMAINING_TRIES > $REMAINING_TRIES_FILE
else
  echo "Writing remaining tries to '$REMAINING_TRIES_FILE'"
  echo $MAX_TRIES > $REMAINING_TRIES_FILE
fi

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
