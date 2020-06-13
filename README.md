# ffmpeg-cross-compile-script

A script to cross-compile FFmpeg for Windows on Ubuntu 18.04.

This (non-free) build includes stable releases of:

* x264
* x265
* libfdk-aac
* sdl v2.0.12 (to enable building of ffplay)

Tested using Ubuntu 18.04 running on WSL.

# Usage

Install all dependencies but running the following command:

`./Prep_System.sh`

Then simply execute the script; it will pull required packages down from Git and Mercurial, cross-compile for 64-bit Windows, deposit the resulting binaries in `./ffmpeg_install/bin/`.
