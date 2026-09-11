FROM fedora:44

ARG ZIG_VERSION

RUN dnf install -y \
  gtk4-devel \
  gtk4-layer-shell-devel \
  libadwaita-devel \
  gettext \
  tar \
  gzip \
  xz \
  curl \
  patchelf \
  && dnf clean all

RUN curl -L \
  "https://ziglang.org/download/${ZIG_VERSION}/zig-x86_64-linux-${ZIG_VERSION}.tar.xz" \
  -o /tmp/zig.tar.xz \
  && mkdir -p /opt/zig \
  && tar -xJf /tmp/zig.tar.xz \
      --strip-components=1 \
      -C /opt/zig \
  && rm /tmp/zig.tar.xz

ENV PATH="/opt/zig:${PATH}"

WORKDIR /build

COPY --chmod=755 build-ghostty.sh /usr/local/bin/build-ghostty

ENTRYPOINT ["/usr/local/bin/build-ghostty"]

