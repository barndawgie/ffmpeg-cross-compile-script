# ffmpeg-cross-compile-script

A script to cross-compile FFmpeg for Windows on Ubuntu 18.04.

This (non-free) build includes stable releases of:

* x264
* x265
* libfdk-aac
* SDL v2.0.12 (to enable building of ffplay)
* libfreetype, libfontconfit, and libfribidi (for Drawtext support)
* libxml2


Tested using Ubuntu 18.04 running on WSL.

# Usage

Install all dependencies by running the following command:

`./Prep_System.sh`

Then simply execute the script; it will pull required packages down from Git and Mercurial, cross-compile for 64-bit Windows, and deposit the resulting binaries in `./ffmpeg_install/bin/`.
