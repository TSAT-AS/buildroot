#!/bin/sh
set -e # fail fast

KEY=""
for i in $(seq 0 63); do
    ADDR="$(printf "0x%x\n" $((0xffff0000 + i)))"
    DATA="$(devmem "$ADDR" b | sed 's/0x/\\x/')"
    devmem "$ADDR" b 0
    KEY="${KEY:+${KEY}}${DATA}"
done
echo -en "$KEY" | /usr/bin/fscryptctl insert_key
unset KEY ADDR DATA
