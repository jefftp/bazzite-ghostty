FROM fedora:44

ARG ZIG_VERSION

RUN dnf install -y \
  gtk4-devel \
  gtk4-layer-shell-devel \
  libadwaita-devel \
  gettext \
  patchelf \
  zig-0.15.2-3.fc44 \
  zig-0.15.2-3.fc44 \
  && dnf clean all

WORKDIR /build

COPY --chmod=755 build-ghostty.sh /usr/local/bin/build-ghostty

ENTRYPOINT ["/usr/local/bin/build-ghostty"]

