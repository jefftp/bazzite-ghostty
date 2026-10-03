# Bazzite Ghostty Installer

## About

I wanted a native install of the Ghostty terminal emulator on my Bazzite
desktop. Here's my build scripts for compiling and installing Ghostty
natively into your desktop.

Unfortunately, there's no automatic update service to keep Ghostty at
the most recent version. However Ghostty does not appear to make
rapid version updates that require frequent updates.

As new versions of Ghostty are released, I will be updating these files
to download, compile, and install the new versions.

## How To Use

First you'll want to clone the git repo:

`git clone https://github.com/jefftp/ghostty.git`

Ghostty can be downloaded, compiled, and installed using the command:

`just install`

The install recipe will copy the Ghostty binary and libraries, the .desktop
and icon files, the Ghostty systemd unit files, and the terminfo files into
your `~/.local` directory. Once run, you should be able to find Ghostty
in your program launcher.

You can also step through each of the stages manually if you'd prefer to
keep a closer eye on each of the steps--or in the event one of the steps
fails.

## Step by Step Install Workflow

First, we build the container with the zig compiler:

`just build-image`

Next, we download the source tarball and extract it to `./src`:

`just download`

Then, we run compile the source code. This step takes several minutes and
the zig compiler is very silent during the process, so patience is required:

`just compile`

Finally, we copy the artifacts into your `~/.local` directory:

`just install`

## Uninstalling Ghostty

There is a recipe in the Justfile for removing all the files installed by the
`install` recipe.

`just uninstall`
