#!/usr/bin/env bash
set -euo pipefail

: "${GHOSTTY_VERSION:?GHOSTTY_VERSION must be set}"
: "${INSTALL_PREFIX:?INSTALL_PREFIX must be set}"

rm -rf /build/ghostty
mkdir -p /build/ghostty

curl -L \
  "https://release.files.ghostty.org/${GHOSTTY_VERSION}/ghostty-${GHOSTTY_VERSION}.tar.gz" \
  -o /tmp/ghostty.tar.gz
tar -xzf /tmp/ghostty.tar.gz --strip-components=1 -C /build/ghostty
rm /tmp/ghostty.tar.gz

cd /build/ghostty
zig build -p "${INSTALL_PREFIX}" \
  -Doptimize=ReleaseFast \
  -fno-sys=gtk4-layer-shell

patchelf \
  --set-rpath '$ORIGIN/../lib' \
  "${INSTALL_PREFIX}/bin/ghostty"

cp -a "${INSTALL_PREFIX}/." /out/

