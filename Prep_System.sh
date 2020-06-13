#!/bin/bash
set -x

#This script will install dependencies needed for building ffmpeg. You likely need to run it with sudo.

sudo apt install gcc-mingw-w64-x86-64 g++-mingw-w64-x86-64 yasm make automake autoconf git pkg-config libtool nasm mercurial cmake python3 python3-pip python3-setuptools python3-wheel gperf gettext autopoint byacc flex 
pip3 install docwriter

#Install c2man: Needed for libfribidi and not available via apt
mkdir -p packages
pushd packages
c2man_path=$(which c2man)
if [ ! -x $c2man_path ]; then
    if [ ! -d ./c2man ]; then
    	git clone https://github.com/fribidi/c2man.git
    fi
    pushd c2man
    ./Configure -d -e
    make depend
    make
    sudo make install 
    popd
fi
popd