#!/usr/bin/env bash
set -e

if [ "$BUILD_TYPE" = "PROD" ]; then
  cp -- ../keys/efuse.nky.enc "$1"
  cp -- ../keys/appfs.key.enc "$1"

  # unlock smart card
  SERIAL="$(gpg-connect-agent 'scd serialno' /bye | grep -o 'SERIALNO [A-Z0-9]*' | cut -d' ' -f2)"
  gpg-connect-agent 'OPTION pinentry-mode=loopback' "/let PIN $PIN" '/definq PASSPHRASE PIN' "scd checkpin $SERIAL" /bye

  # decrypt keys
  gpg --batch --yes --status-file "$1/keys.log" --decrypt --armor --output "/dev/shm/tmp/efuse.nky" "$1/efuse.nky.enc"
  gpg --batch --yes --status-file "$1/keys.log" --decrypt --armor --output "/dev/shm/tmp/appfs.key" "$1/appfs.key.enc"

  # force GPG/scdaemon to release Yubikey and let PIV be used
  gpg-connect-agent 'scd killscd' /bye
fi
