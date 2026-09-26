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

# Build the container image
build-image:
  podman build -t {{image}} .

# Download and extract Ghostty source
download:
  rm -rf {{src}}
  mkdir -p {{src}}
  curl -L \
    "https://release.files.ghostty.org/{{ghostty_version}}/ghostty-{{ghostty_version}}.tar.gz" \
    -o ghostty.tar.gz
  tar -xzf ghostty.tar.gz --strip-components=1 -C {{src}}
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

# Remove artifacts
clean:
  rm -rf {{dist}}
  -podman image rm {{image}}


