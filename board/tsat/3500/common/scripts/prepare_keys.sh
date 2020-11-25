#!/usr/bin/env bash
set -e

if [ "$TSAT_SECURE" = "1" ]; then
  cp -- ../keys/efuse.nky.enc "$1"
  cp -- ../keys/appfs.key.enc "$1"
  gpg --decrypt --armor --output "$TMP_DIR/efuse.nky" "$1/efuse.nky.enc"
  gpg --decrypt --armor --output "$TMP_DIR/appfs.key" "$1/appfs.key.enc"
  gpg-connect-agent 'scd killscd' /bye # force GPG to release Yubikey and let PIV be used
fi
