ghostty_version := "1.3.1"
zig_version := "0.15.2"

root := justfile_directory()
dist := root / "dist"

home := env("HOME")
local := home / ".local"
install_prefix := local / "ghostty.app"

image := "ghostty-builder"

# Show available recipes
_default:
  @just --list

# Build the builder image
build-image:
  podman build \
    --build-arg ZIG_VERSION={{zig_version}} \
    --tag {{image}} \
    .

# Compile Ghostty and export the artifacts
export:
  podman image exists {{image}} || \
    (echo "Builder image missing. Run: just build-image" && exit 1)

  rm -rf {{dist}}
  mkdir -p {{dist}}

  podman run --rm \
    -e GHOSTTY_VERSION={{ghostty_version}} \
    -e INSTALL_PREFIX={{install_prefix}} \
    -v "{{dist}}:/out:Z" \
    {{image}}

# Install into ~/.local
install:
  test -x "{{dist / 'bin/ghostty'}}" || \
    (echo "Ghostty binary missing or not executable. Run: just export" && exit 1)

  rm -rf "{{install_prefix}}"
  mkdir -p "{{install_prefix}}"
  cp -a "{{dist}}/." "{{install_prefix}}/"

  mkdir -p {{local}}/bin
  ln -sfn ../ghostty.app/bin/ghostty \
    "{{local}}/bin/ghostty"

  mkdir -p {{local}}/share/applications
  cp {{install_prefix}}/share/applications/com.mitchellh.ghostty.desktop \
    {{local}}/share/applications/

  mkdir -p {{local}}/share/dbus-1/services
  cp {{install_prefix}}/share/dbus-1/services/com.mitchellh.ghostty.service \
    {{local}}/share/dbus-1/services/

  mkdir -p {{local}}/share/systemd/user
  cp {{install_prefix}}/share/systemd/user/app-com.mitchellh.ghostty.service \
    {{local}}/share/systemd/user/

  mkdir -p {{local}}/share/icons/hicolor/128x128/apps
  cp {{install_prefix}}/share/icons/hicolor/128x128/apps/com.mitchellh.ghostty.png \
    {{local}}/share/icons/hicolor/128x128/apps/

  mkdir -p {{local}}/share/icons/hicolor/256x256/apps
  cp {{install_prefix}}/share/icons/hicolor/256x256/apps/com.mitchellh.ghostty.png \
    {{local}}/share/icons/hicolor/256x256/apps/

# Test Ghostty without installing it
test-run:
  {{dist}}/bin/ghostty

# Remove artifacts
clean:
  rm -rf {{dist}}
  -podman image rm {{image}}


