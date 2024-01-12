# ffmpeg-cross-compile-script

A script to cross-compile FFmpeg for Windows on Ubuntu 22.04. It's not dissimilar from the widely known ffmpeg-build-helpers, but uses provided mingw packages rather than requiring you to build your own toolchain, and builds everything for 64-bit Windows.

This (non-free) build includes stable releases of:

* x264
* x265
* libfdk-aac
* aom (AV1 codec)
* openjpeg
* SDL v2.0.12 (to enable building of ffplay)
* libfreetype, harfguzz, libfontconfig, and libfribidi (for Drawtext support)
* libass
* openssl 1.1.1
* libxml2

Tested using Ubuntu 22.04 running on WSL.

# Usage

Do a one-time install of all dependencies by running the following command (probably as root/sudo):

`./Prep_System.sh`

Then simply execute the `./Cross-Compile_FFMPEG.sh` script; it will pull required packages down from Git, cross-compile for 64-bit Windows, and deposit the resulting binaries in `./ffmpeg_install/bin/`.
