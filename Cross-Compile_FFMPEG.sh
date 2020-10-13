#!/bin/bash
set -x

#Install ubuntu package dependencies before executing this script by running ./Prep_System.sh

#Configure Global Variables
host="x86_64-w64-mingw32"
prefix="$(pwd)/ffmpeg_install"
patch_dir="$(pwd)/patches"
config_dir="$(pwd)/config"
library_path="$prefix/lib"
binary_path="$prefix/bin"
include_path="$prefix/include"
threads=2
configure_params="--host=$host --prefix=$prefix --enable-static --disable-shared"
compiler_params="-static-libgcc -static-libstdc++ -static -O3 -s"
export PKG_CONFIG_PATH="$prefix/lib/pkgconfig"

#Select Package Versions
zlib_git="https://github.com/madler/zlib.git"
zlib_release="v1.2.11"
bzip2_git="https://git.code.sf.net/p/bzip2/bzip2.git"
bzip2_release="bzip2-1_0_8"
bzip_patchfile_path="$patch_dir/bzip2-1.0.8_brokenstuff.diff" #From https://raw.githubusercontent.com/rdp/ffmpeg-windows-build-helpers/master/patches/bzip2-1.0.8_brokenstuff.diff
sdl_hg="http://hg.libsdl.org/SDL"
sdl_release="release-2.0.12"
openssl_git="https://github.com/openssl/openssl.git"
openssl_release="OpenSSL_1_1_1h"
libpng_git="https://github.com/glennrp/libpng.git"
libpng_release="v1.6.37"
libxml2_git="https://gitlab.gnome.org/GNOME/libxml2.git"
libxml2_release="v2.9.10"
libfreetype2_git="https://git.savannah.gnu.org/git/freetype/freetype2.git"
libfreetype2_release="VER-2-10-2"
fribidi_git="https://github.com/fribidi/fribidi.git"
fribidi_release="v1.0.9"
fontconfig_git="https://gitlab.freedesktop.org/fontconfig/fontconfig.git"
fontconfig_release="2.13.92"
libass_git="https://github.com/libass/libass.git"
libass_release="0.14.0"
lame_download="https://managedway.dl.sourceforge.net/project/lame/lame/3.100/lame-3.100.tar.gz"
fdk_git="https://github.com/mstorsjo/fdk-aac.git"
fdk_release="v2.0.1"
x264_git="https://code.videolan.org/videolan/x264.git"
x265_hg="http://hg.videolan.org/x265"
libopenjpeg_git="https://github.com/uclouvain/openjpeg.git"
libopenjpeg_release="v2.3.1"
libaom_git="https://aomedia.googlesource.com/aom"
libaom_version="v2.0.0"
ffmpeg_git="https://git.ffmpeg.org/ffmpeg.git"
ffmpeg_release="n4.3.1"

#FFMPEG Configuration
FFMPEG_OPTIONS="\
    --enable-nonfree \
    --enable-gpl \
    --enable-libfdk-aac \
    --enable-libx264 \
    --enable-libx265 \
    --enable-libxml2 \
    --enable-libopenjpeg \
    --enable-libaom \
    --enable-libmp3lame \
    --enable-openssl \
    --enable-libfreetype
    --enable-libfontconfig \
    --enable-libfribidi \
    --enable-libass"

mkdir -p packages
pushd packages #Put all these dependencies somewhere

#Build and Install Dependences
#Libs
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
BINARY_PATH=$binary_path INCLUDE_PATH=$include_path LIBRARY_PATH=$library_path PREFIX=$host- make -f win32/Makefile.gcc
BINARY_PATH=$binary_path INCLUDE_PATH=$include_path LIBRARY_PATH=$library_path PREFIX=$host- make -f win32/Makefile.gcc install
popd

#libbz2
if [ ! -d ./bzip2 ]
then
    git clone $bzip2_git
fi
pushd bzip2
git fetch --tags
git checkout $bzip2_release -B release
patch -p0 < $bzip_patchfile_path
CC=$host-gcc AR=$host-ar RANLIB=$host-ranlib make -j $threads libbz2.a
install -m644 bzlib.h $include_path/bzlib.h
install -m644 libbz2.a $library_path/libbz2.a
popd

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

#openssl
if [ ! -d ./openssl ]
then
    git clone $openssl_git
fi
pushd openssl
git fetch --tags
git checkout $openssl_release -B release
./config --prefix=$prefix --cross-compile-prefix=$host- no-shared no-dso zlib
CC=$host-gcc AR=$host-ar RANLIB=$host-ranlib RC=$host-windres ./Configure --prefix=$prefix -L$library_path -I$include_path no-shared no-dso zlib mingw64
make -j $threads
make install_sw
popd

#libpng: Required for FreeType2
if [ ! -d ./libpng ]
then
    git clone $libpng_git
fi
pushd libpng
git fetch --tags
git checkout $libpng_release -B release
LDFLAGS="-L$library_path" CPPFLAGS="-I$include_path" ./configure $configure_params
make -j $threads
make install
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

#Audio Codecs
#lameMP3
if [ ! -d ./lame-3 ]
then
    mkdir -p lame
    curl $lame_download -o lame.tar.gz
    tar -xvzf lame.tar.gz --directory lame --strip-components=1
    rm lame.tar.gz
fi
pushd lame
./configure $configure_params --disable-gtktest --enable-nasm
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

#Video Codecs
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

mkdir -p 8bit 10bit 12bit

#Build 12-Bit
cd 12bit
cmake -DCMAKE_TOOLCHAIN_FILE="$config_dir/toolchain-x86_64-w64-mingw32.cmake" \
	-DCMAKE_INSTALL_PREFIX=$prefix -DENABLE_SHARED=OFF \
    -DENABLE_CLI=OFF -DEXPORT_C_API=OFF \
    -DHIGH_BIT_DEPTH=ON -DMAIN12=ON \
    ../../source
make -j $threads

#Build 10-Bit
cd  ../10bit
cmake -DCMAKE_TOOLCHAIN_FILE="$config_dir/toolchain-x86_64-w64-mingw32.cmake" \
    -DCMAKE_INSTALL_PREFIX=$prefix -DENABLE_SHARED=OFF \
    -DENABLE_CLI=OFF -DEXPORT_C_API=OFF \
    -DHIGH_BIT_DEPTH=ON -DMAIN12=OFF \
    ../../source
make -j $threads

#Build 8-Bit
cd ../8bit
ln -sf ../10bit/libx265.a libx265_main10.a
ln -sf ../12bit/libx265.a libx265_main12.a
cmake -DCMAKE_TOOLCHAIN_FILE="$config_dir/toolchain-x86_64-w64-mingw32.cmake" \
    -DCMAKE_INSTALL_PREFIX=$prefix -DENABLE_SHARED=OFF \
    -DENABLE_CLI=OFF -DEXPORT_C_API=ON \
    -DEXTRA_LIB="x265_main10.a;x265_main12.a" -DEXTRA_LINK_FLAGS=-L. -DLINKED_10BIT=ON -DLINKED_12BIT=ON \
    ../../source
make -j $threads

#Combine all Libraries
mv libx265.a libx265_main.a
ar -M <<EOF
CREATE libx265.a
ADDLIB libx265_main.a
ADDLIB libx265_main10.a
ADDLIB libx265_main12.a
SAVE
END
EOF
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
cmake -DCMAKE_TOOLCHAIN_FILE="$config_dir/toolchain-x86_64-w64-mingw32.cmake" \
	-DCMAKE_INSTALL_PREFIX=$prefix \
	-DBUILD_THIRDPARTY=TRUE -DBUILD_SHARED_LIBS=0 \
    ..
make -j $threads
make install
popd

#libaom: AV1 Codec
if [ ! -d ./aom ]
then
    git clone $libaom_git
fi
mkdir aom_build
pushd aom_build
cmake -DCMAKE_TOOLCHAIN_FILE="../aom/build/cmake/toolchains/x86_64-mingw-gcc.cmake" \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    ../aom
make -j $threads
make install
popd

# #Subtitle/Font Dependencies
#Libfreetype2: Required for Drawtext Filter
if [ ! -d ./freetype2 ]
then
    git clone $libfreetype2_git
fi
pushd freetype2
git fetch --tags
git checkout $libfreetype2_release -B release
./autogen.sh
BZIP2_LIBS="-L$library_path" BZIP2_CFLAGS="-I$include_path" ./configure $configure_params --with-zlib=yes --with-png=yes --with-harfbuzz=no --with-bzip2=yes
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
CLAGS="-I$include_path" LDFLAGS="-L$library_path" LIBS="-lbz2" ./autogen.sh $configure_params --enable-libxml2
make -j $threads
make install
popd

#libass
if [ ! -d ./libass ]
then
    git clone $libass_git
fi
pushd libass
git fetch --tags
git checkout $libass_release -B release
./autogen.sh
./configure $configure_params  --disable-harfbuzz
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
./configure --arch=x86_64 \
    --target-os=mingw32 \
    --cross-prefix=$host- \
    --pkg-config=pkg-config \
    --pkg-config-flags=--static \
    --prefix=$prefix \
    --extra-libs="-lstdc++ -lbz2" \
    --extra-cflags="$compiler_params -I$include_path" \
    --extra-cxxflags="$compiler_params" \
    --extra-ldflags="$compiler_params -L$library_path" \
    --extra-ldexeflags="$compiler_params" \
    --extra-ldsoflags="$compiler_params" \
    --logfile=./config.log \
    $FFMPEG_OPTIONS 
make -j $threads
make install
popd

popd #Back to upper-level directory
pushd $binary_path
