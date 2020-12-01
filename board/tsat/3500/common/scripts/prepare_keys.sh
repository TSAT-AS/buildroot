#!/usr/bin/env bash
set -e

if [ "$BUILD_TYPE" = "PROD" ]; then
  cp -- ../keys/efuse.nky.enc "$1"
  cp -- ../keys/appfs.key.enc "$1"
  gpg --decrypt --armor --output "/dev/shm/tmp/efuse.nky" "$1/efuse.nky.enc"
  gpg --decrypt --armor --output "/dev/shm/tmp/appfs.key" "$1/appfs.key.enc"
  gpg-connect-agent 'scd killscd' /bye # force GPG to release Yubikey and let PIV be used
fi
