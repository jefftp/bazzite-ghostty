#!/usr/bin/env bash
set -euo pipefail

: "${INSTALL_PREFIX:?INSTALL_PREFIX must be set}"
: "${VERSION_STRING:?VERSION_STRING must be set}"

cd /src

zig build \
  --summary failures \
  --prefix "${INSTALL_PREFIX}" \
  -Doptimize=ReleaseFast \
  -Dversion-string="${VERSION_STRING}" \
  -fno-sys=gtk4-layer-shell

patchelf \
  --set-rpath '$ORIGIN/../lib' \
  "${INSTALL_PREFIX}/bin/ghostty"

cp -a "${INSTALL_PREFIX}/." /dist/

