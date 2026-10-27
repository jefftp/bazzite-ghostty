FROM fedora:44

RUN dnf install -y \
  gtk4-devel \
  gtk4-layer-shell-devel \
  libadwaita-devel \
  libglvnd-devel \
  gettext \
  patchelf \
  && dnf clean all

RUN set -eu; \
  curl --fail --location --show-error --silent \
    "https://ziglang.org/download/0.17.0/zig-x86_64-linux-0.17.0.tar.xz" \
    --output /tmp/zig.tar.xz; \
  mkdir -p /opt/zig; \
  tar -xJf /tmp/zig.tar.xz --strip-components=1 -C /opt/zig; \
  rm /tmp/zig.tar.xz

ENV PATH="/opt/zig:${PATH}"

WORKDIR /build

COPY --chmod=755 scripts/build-ghostty.sh /usr/local/bin/build-ghostty

ENTRYPOINT ["/usr/local/bin/build-ghostty"]

