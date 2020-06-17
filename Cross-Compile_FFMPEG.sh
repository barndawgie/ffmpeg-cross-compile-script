#!/bin/bash
set -x

#Install ubuntu package dependencies before executing this script by running ./Prep_System.sh

#Configure Global Variables
host="x86_64-w64-mingw32"
prefix="$(pwd)/ffmpeg_install"
threads=2
configure_params="--host=$host --prefix=$prefix --enable-static --disable-shared"
compiler_params="-static-libgcc -static-libstdc++ -static -O3 -s"
export PKG_CONFIG_PATH="$prefix/lib/pkgconfig"

#Select Package Versions
sdl_hg="http://hg.libsdl.org/SDL"
sdl_release="release-2.0.12"
zlib_git="https://github.com/madler/zlib.git"
zlib_release="v1.2.11"
libxml2_git="https://gitlab.gnome.org/GNOME/libxml2.git"
libxml2_release="v2.9.10"
libfreetype2_git="https://git.savannah.gnu.org/git/freetype/freetype2.git"
libfreetype2_release="VER-2-10-0"
fribidi_git="https://github.com/fribidi/fribidi.git"
fribidi_release="v1.0.9"
fontconfig_git="https://gitlab.freedesktop.org/fontconfig/fontconfig.git"
fontconfig_release="2.13.92"
fdk_git="https://github.com/mstorsjo/fdk-aac.git"
fdk_release="v2.0.1"
x264_git="https://code.videolan.org/videolan/x264.git"
x265_hg="https://bitbucket.org/multicoreware/x265"
libopenjpeg_git="https://github.com/uclouvain/openjpeg.git"
libopenjpeg_release="v2.3.1"
ffmpeg_git="https://git.ffmpeg.org/ffmpeg.git"
ffmpeg_release="n4.3"

mkdir -p packages
pushd packages #Put all these dependencies somewhere

#Get Packages
#SDL: Required for ffplay compilation
if [ ! -d ./SDL ]
then
    hg clone $sdl_hg -r $sdl_release
fi
pushd SDL
hg update -r $sdl_release
hg pull -u -r $sdl_release
./autogen.sh
mkdir -p build
cd build
../configure $configure_params
make -j $threads
make install
popd

#ZLIB: Required for FreeTyep2
if [ ! -d ./zlib ]
then
    git clone $zlib_git
fi
pushd zlib
git fetch --tags
git checkout $zlib_release -B release
sed -i /"PREFIX ="/d win32/Makefile.gcc
./configure -static --prefix=$host-
BINARY_PATH=$prefix/bin INCLUDE_PATH=$prefix/include LIBRARY_PATH=$prefix/lib PREFIX=$host- make -f win32/Makefile.gcc
BINARY_PATH=$prefix/bin INCLUDE_PATH=$prefix/include LIBRARY_PATH=$prefix/lib PREFIX=$host- make -f win32/Makefile.gcc install
popd

#Libxml2
if [ ! -d ./libxml2 ]
then
    git clone $libxml2_git
fi
pushd libxml2
git fetch --tags
git checkout $libxml2_release -B release
./autogen.sh $configure_params --without-python
make -j $threads
make install
popd

#Libfreetype2: Required for Drawtext Filter
if [ ! -d ./freetype2 ]
then
    git clone $libfreetype2_git
fi
pushd freetype2
git fetch --tags
git checkout $libfreetype2_release -B release
./autogen.sh
./configure $configure_params --with-png=no --with-harfbuzz=no
make -j $threads
make install
popd

#libfribidi: Required for Drawtext
if [ ! -d ./fribidi ]
then
    git clone $fribidi_git
fi
pushd fribidi
git fetch --tags
git checkout $fribidi_release -B release
./autogen.sh $configure_params
make -j $threads
make install
popd

#Fontconfig: Required? for Drawtext Filter
if [ ! -d ./fontconfig ]
then
    git clone $fontconfig_git
fi
pushd fontconfig
git fetch --tags
git checkout $fontconfig_release -B release
./autogen.sh $configure_params --enable-libxml2
make -j $threads
make install
popd

#FDK: The Best AAC Codec for ffmpeg
if [ ! -d ./fdk-aac ]
then
    git clone $fdk_git
fi
pushd fdk-aac
git fetch --tags
git checkout $fdk_release -B release
./autogen.sh
./configure $configure_params
make -j $threads
make install
popd

#x264: h.264 Video Encoding for ffmpeg
if [ ! -d ./x264 ]
then
    git clone $x264_git
fi
pushd x264
git fetch --tags
git checkout stable
./configure --host=$host --enable-static --cross-prefix=$host- --prefix=$prefix
make -j $threads
make install
popd

#x265: HEVC Video Encoding for ffmpeg
if [ ! -d ./x265 ]
then
    hg clone $x265_hg -r stable
fi
pushd x265
hg update -r stable
hg pull -u -r stable
cd ./build
cmake -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_C_COMPILER=$host-gcc -DCMAKE_CXX_COMPILER=$host-g++ -DCMAKE_RC_COMPILER=$host-windres -DCMAKE_ASM_YASM_COMPILER=yasm -DCMAKE_CXX_FLAGS="$compiler_params" -DCMAKE_C_FLAGS="$compiler_params" -DCMAKE_SHARED_LIBRARY_LINK_C_FLAGS="$compiler_params" -DCMAKE_SHARED_LIBRARY_LINK_CXX_FLAGS="$compiler_params" -DENABLE_CLI=1 -DCMAKE_INSTALL_PREFIX=$prefix -DENABLE_SHARED=0 ../source
make -j $threads
make install
popd

#openjpeg: JPEG 2000 Codec
if [ ! -d ./openjpeg ]
then
    git clone $libopenjpeg_git
fi
pushd openjpeg
git fetch --tags
git checkout $libopenjpeg_release -B release
mkdir build
cd build
cmake .. -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_C_COMPILER=$host-gcc -DCMAKE_CXX_COMPILER=$host-g++ -DCMAKE_RC_COMPILER=$host-windres -DCMAKE_CXX_FLAGS="$compiler_params" -DCMAKE_C_FLAGS="$compiler_params" -DCMAKE_SHARED_LIBRARY_LINK_C_FLAGS="$compiler_params" -DCMAKE_INSTALL_PREFIX=$prefix -DBUILD_THIRDPARTY=TRUE
      local command="${build_from_dir} -DENABLE_STATIC_RUNTIME=1 -DBUILD_SHARED_LIBS=0 -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_FIND_ROOT_PATH=$mingw_w64_x86_64_prefix -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY -DCMAKE_RANLIB=${cross_prefix}ranlib -DCMAKE_C_COMPILER=${cross_prefix}gcc -DCMAKE_CXX_COMPILER=${cross_prefix}g++ -DCMAKE_RC_COMPILER=${cross_prefix}windres -DCMAKE_INSTALL_PREFIX=$mingw_w64_x86_64_prefix $extra_args"

make -j $threads
make install
popd

#Download, Configure, and Build ffmpeg, ffprobe, and ffplay
if [ ! -d ./ffmpeg ]
then
    git clone $ffmpeg_git
fi
pushd ffmpeg
git fetch --tags
git checkout $ffmpeg_release -B release
FFMPEG_OPTIONS="\
    --enable-nonfree \
    --enable-gpl \
    --enable-libfdk-aac \
    --enable-libx264 \
    --enable-libx265 \
    --enable-libfreetype \
    --enable-libfontconfig \
    --enable-libfribidi \
    --enable-libxml2 \
    --enable-libopenjpeg"
./configure --arch=x86_64 --target-os=mingw32 --cross-prefix=$host- --pkg-config=pkg-config --pkg-config-flags=--static --prefix=$prefix \
    --extra-libs=-lstdc++ --extra-cflags="$compiler_params" --extra-cxxflags="$compiler_params" --extra-ldflags="$compiler_params" \
    --extra-ldexeflags="$compiler_params" --extra-ldsoflags="$compiler_params" --logfile=./config.log $FFMPEG_OPTIONS
make -j $threads
make install
popd

popd #Back to upper-level directory