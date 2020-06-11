#!/bin/bash
set -x

#Install The Following Ubuntu Package Dependencies Before Executing This Script
#apt install gcc-mingw-w64-x86-64 g++-mingw-w64-x86-64 yasm make automake autoconf git pkg-config libtool nasm mercurial cmake

#Configure Global Variables
host="x86_64-w64-mingw32"
prefix="$(pwd)/ffmpeg_install"
threads=2
configure_params="--host=$host --prefix=$prefix --enable-static --disable-shared"
compiler_params="-static-libgcc -static-libstdc++ -static -O3 -s"
export PKG_CONFIG_PATH="$prefix/lib/pkgconfig"

#Select Package Versions
ffmpeg_release="n4.2.3"
fdk_release="v2.0.1"
SDL_release="release-2.0.12"

#Get Packages
#SDL: Required for ffplay compilation
if [ ! -d ./SDL ]
then
    hg clone http://hg.libsdl.org/SDL -r $SDL_release
fi
pushd SDL
hg update -r $SDL_release
hg pull -u -r $SDL_release
./autogen.sh
mkdir build
cd build
../configure $configure_params
make -j $threads install
popd

#FDK: The Best AAC Codec for ffmpeg
if [ ! -d ./fdk-aac ]
then
    git clone https://github.com/mstorsjo/fdk-aac.git fdk-aac
fi
pushd fdk-aac
git pull
git fetch --tags
git checkout $fdk_release -B release
./autogen.sh
./configure $configure_params
make -j $threads install
popd

#x264: h.264 Video Encoding for ffmpeg
if [ ! -d ./x264 ]
then
    git clone https://code.videolan.org/videolan/x264.git x264
fi
pushd x264
git pull
git fetch --tags
git checkout stable
./configure --host=$host --enable-static --cross-prefix=$host- --prefix=$prefix
make -j $threads install
popd

#x265: HEVC Video Encoding for ffmpeg
if [ ! -d ./x265 ]
then
    hg clone https://bitbucket.org/multicoreware/x265 -r stable
fi
pushd x265
hg update -r stable
hg pull -u -r stable
cd ./build
cmake -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_C_COMPILER=x86_64-w64-mingw32-gcc -DCMAKE_CXX_COMPILER=x86_64-w64-mingw32-g++ -DCMAKE_RC_COMPILER=x86_64-w64-mingw32-windres -DCMAKE_ASM_YASM_COMPILER=yasm -DCMAKE_CXX_FLAGS="$compiler_params" -DCMAKE_C_FLAGS="$compiler_params" -DCMAKE_SHARED_LIBRARY_LINK_C_FLAGS="$compiler_params" -DCMAKE_SHARED_LIBRARY_LINK_CXX_FLAGS="$compiler_params" -DENABLE_CLI=1 -DCMAKE_INSTALL_PREFIX=$prefix -DENABLE_SHARED=0 ../source
make -j $threads install
popd

#Download, Configure, and Build ffmpeg, ffprobe, and ffplay
if [ ! -d ./ffmpeg ]
then
    git clone https://git.ffmpeg.org/ffmpeg.git ffmpeg
fi
pushd ffmpeg
git pull
git fetch --tags
git checkout $ffmpeg_release -B release
./configure --arch=x86_64 --target-os=mingw32 --cross-prefix=$host- --pkg-config=pkg-config --pkg-config-flags=--static --prefix=$prefix --extra-libs=-lstdc++ --extra-cflags="$compiler_params" --extra-cxxflags="$compiler_params" --extra-ldflags="$compiler_params" --extra-ldexeflags="$compiler_params" --extra-ldsoflags="$compiler_params" --logfile=./config.log --enable-nonfree --enable-gpl --enable-libfdk-aac --enable-libx264 --enable-libx265
make -j $threads install
popd
