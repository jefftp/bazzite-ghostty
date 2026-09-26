ghostty_version := "1.3.1"
zig_version := "0.15.2"

root := justfile_directory()
src := root / "src"
dist := root / "dist"

home := env("HOME")
install_prefix := home / ".local"

image := "ghostty-builder:" + ghostty_version

# Show available recipes
_default:
  @just --list

# Display version information
version:
  @echo "Ghostty Version: {{ghostty_version}}"
  @echo "Zig Version:     {{zig_version}}"
  @echo "Install Prefix:  {{install_prefix}}"

# Build the container image
build-image:
  #!/usr/bin/env bash
  set -euo pipefail

  if podman image exists {{image}}; then
    echo "Builder image '{{image}}' already exists."
  else
    podman build -t {{image}} .
  fi

# Download and extract Ghostty source
download:
  #!/usr/bin/env bash
  set -euo pipefail

  if [[ -f "{{src}}/VERSION" ]] && \
     [[ "$(cat "{{src}}/VERSION")" == "{{ghostty_version}}" ]]; then
    echo "Ghostty {{ghostty_version}} source already exists."
    exit 0
  elif [[ -e "{{src}}" ]]; then
    echo "Existing source directory does not contain Ghostty {{ghostty_version}}." >&2
    exit 1
  fi

  curl --fail --location \
    "https://release.files.ghostty.org/{{ghostty_version}}/ghostty-{{ghostty_version}}.tar.gz" \
    --output ghostty.tar.gz

  mkdir -p "{{src}}"
  tar -xzf ghostty.tar.gz --strip-components=1 -C "{{src}}"
  rm ghostty.tar.gz

# Compile Ghostty
compile:
  @podman image exists {{image}} || \
    (echo "Container image {{image}} missing. Run: just build" >&2; exit 1)

  @test -f "{{src}}/build.zig" || \
    (echo "Ghostty source missing. Run: just download-ghostty" >&2; exit 1)

  rm -rf {{dist}}
  mkdir -p {{dist}}

  podman run --rm \
    -e INSTALL_PREFIX={{install_prefix}} \
    -v "{{src}}:/src:Z" \
    -v "{{dist}}:/dist:Z" \
    {{image}}

# Install Ghostty and supporting files
install:
  @test -f "{{dist / 'bin/ghostty'}}" || \
    (echo "Ghostty binary missing. Run: just compile-ghostty" >&2; exit 1)

  install -Dm755 -T \
    "{{dist}}/bin/ghostty" \
    "{{install_prefix}}/bin/ghostty"

  install -Dm755 -T \
    "{{dist}}/lib/libgtk4-layer-shell.so" \
    "{{install_prefix}}/lib/libgtk4-layer-shell.so"

  install -Dm644 -T \
    "{{dist}}/share/applications/com.mitchellh.ghostty.desktop" \
    "{{install_prefix}}/share/applications/com.mitchellh.ghostty.desktop"

  install -Dm644 -T \
    "{{dist}}/share/dbus-1/services/com.mitchellh.ghostty.service" \
    "{{install_prefix}}/share/dbus-1/services/com.mitchellh.ghostty.service"

  install -Dm644 -T \
    "{{dist}}/share/systemd/user/app-com.mitchellh.ghostty.service" \
    "{{install_prefix}}/share/systemd/user/app-com.mitchellh.ghostty.service"

  systemctl --user daemon-reload
  busctl --user call \
    org.freedesktop.DBus \
    /org/freedesktop/DBus \
    org.freedesktop.DBus \
    ReloadConfig

  install -Dm644 -T \
    "{{dist}}/share/terminfo/x/xterm-ghostty" \
    "{{install_prefix}}/share/terminfo/x/xterm-ghostty"

  mkdir -p "{{install_prefix}}/share/icons/hicolor"
  cp -r \
    "{{dist}}/share/icons/hicolor/." \
    "{{install_prefix}}/share/icons/hicolor/"

  cp -r "{{dist}}/share/ghostty" "{{install_prefix}}/share/"

# Remove Ghostty and supporting files
uninstall:
  rm \
    "{{install_prefix}}/share/applications/com.mitchellh.ghostty.desktop" \
    "{{install_prefix}}/bin/ghostty" \
    "{{install_prefix}}/lib/libgtk4-layer-shell.so" \
    "{{install_prefix}}/share/systemd/user/app-com.mitchellh.ghostty.service" \
    "{{install_prefix}}/share/dbus-1/services/com.mitchellh.ghostty.service" \
    "{{install_prefix}}/share/terminfo/x/xterm-ghostty"

  rm -rf "{{install_prefix}}/share/ghostty"

  find "{{install_prefix}}/share/icons/hicolor" \
    -type f \
    -name 'com.mitchellh.ghostty.png' \
    -delete

  busctl --user call \
    org.freedesktop.DBus \
    /org/freedesktop/DBus \
    org.freedesktop.DBus \
    ReloadConfig
  systemctl --user daemon-reload

# Test Ghostty without installing it
test:
  {{dist}}/bin/ghostty

# Remove source
clean-source:
  rm -rf {{src}}

# Remove build and distribution artifacts
clean-dist:
  rm -rf {{src}}/.zig-cache
  rm -rf {{dist}}

# Remove the builder container image
clean-image:
  @if podman image exists {{image}}; then \
    podman image rm {{image}}; \
  fi

# Remove all generated files and the builder image
purge: clean-source clean-dist clean-image

