#!/usr/bin/env bash
set -e

if [ "$BUILD_TYPE" = "PROD" ]; then
  if [ -z "$PIN" ]; then
    echo "ERROR: PIN not defined"
    exit 1
  fi
  OPENSSL_CONF="$WORK/openssl.cnf"
  cp -- board/tsat/3500/production/openssl.cnf "$OPENSSL_CONF"
  sed -i "s#= BR_HOST#= $HOST_DIR#g" "$OPENSSL_CONF"
  sed -i "s#= SC_PIN#= $PIN#g" "$OPENSSL_CONF"
fi
