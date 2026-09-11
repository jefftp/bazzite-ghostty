#!/usr/bin/env bash
set -euo pipefail

: "${INSTALL_PREFIX:?INSTALL_PREFIX must be set}"

cd /src

zig build -p "${INSTALL_PREFIX}" \
  -Doptimize=ReleaseFast \
  -fno-sys=gtk4-layer-shell

patchelf \
  --set-rpath '$ORIGIN/../lib' \
  "${INSTALL_PREFIX}/bin/ghostty"

cp -a "${INSTALL_PREFIX}/." /dist/

