
#!/bin/bash
set -x

#Install The Following Ubuntu Package Dependencies Before Executing This Script
#apt install gcc-mingw-w64-x86-64 g++-mingw-w64-x86-64 yasm make automake autoconf git pkg-config libtool nasm mercurial cmake python3 python3-pip python3-setuptools python3-wheel gperf gettext autopoint
#apt install flex byacc
#pip3 install docwriter

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
zlib_release="v1.2.11"
FREETYPE2_release="VER-2-10-0"
fribidi_release="v1.0.9"
libxml2_release="v2.9.10"
fontconfig_release="2.13.92"

mkdir -p packages
pushd packages #Put all these dependencies somewhere

#Get Packages
#Install c2man: Needed for libfribidi
c2man_path=$(which c2man)
if [ ! -x $c2man_path ]; then
    if [ ! -d ./c2man ]; then
    	git clone https://github.com/fribidi/c2man.git
    fi
    pushd c2man
    ./Configure -d -e
    make depend
    make
    make install #Likely requires sudo
    popd
fi

#SDL: Required for ffplay compilation
if [ ! -d ./SDL ]
then
    hg clone http://hg.libsdl.org/SDL -r $SDL_release
fi
pushd SDL
hg update -r $SDL_release
hg pull -u -r $SDL_release
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
    git clone https://github.com/madler/zlib.git
fi
pushd zlib
git fetch --tags
git checkout $zlib_release -B release
sed -i /"PREFIX ="/d win32/Makefile.gcc
./configure -static --prefix=$host-
BINARY_PATH=$prefix/bin INCLUDE_PATH=$prefix/include LIBRARY_PATH=$prefix/lib PREFIX=x86_64-w64-mingw32- make -f win32/Makefile.gcc
BINARY_PATH=$prefix/bin INCLUDE_PATH=$prefix/include LIBRARY_PATH=$prefix/lib PREFIX=x86_64-w64-mingw32- make -f win32/Makefile.gcc install
popd

#Libxml2
if [ ! -d ./libxml2 ]
then
    git clone https://gitlab.gnome.org/GNOME/libxml2.git
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
    git clone https://git.savannah.gnu.org/git/freetype/freetype2.git
fi
pushd freetype2
git fetch --tags
git checkout $FREETYPE2_release -B release
./autogen.sh
./configure $configure_params --with-png=no --with-harfbuzz=no
make -j $threads
make install
popd

#libfribidi: Required for Drawtext
if [ ! -d ./fribidi ]
then
    git clone https://github.com/fribidi/fribidi.git
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
    git clone https://gitlab.freedesktop.org/fontconfig/fontconfig.git
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
    git clone https://github.com/mstorsjo/fdk-aac.git fdk-aac
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
    git clone https://code.videolan.org/videolan/x264.git x264
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
    hg clone https://bitbucket.org/multicoreware/x265 -r stable
fi
pushd x265
hg update -r stable
hg pull -u -r stable
cd ./build
cmake -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_C_COMPILER=x86_64-w64-mingw32-gcc -DCMAKE_CXX_COMPILER=x86_64-w64-mingw32-g++ -DCMAKE_RC_COMPILER=x86_64-w64-mingw32-windres -DCMAKE_ASM_YASM_COMPILER=yasm -DCMAKE_CXX_FLAGS="$compiler_params" -DCMAKE_C_FLAGS="$compiler_params" -DCMAKE_SHARED_LIBRARY_LINK_C_FLAGS="$compiler_params" -DCMAKE_SHARED_LIBRARY_LINK_CXX_FLAGS="$compiler_params" -DENABLE_CLI=1 -DCMAKE_INSTALL_PREFIX=$prefix -DENABLE_SHARED=0 ../source
make -j $threads

make install
popd

#Download, Configure, and Build ffmpeg, ffprobe, and ffplay
if [ ! -d ./ffmpeg ]
then
    git clone https://git.ffmpeg.org/ffmpeg.git ffmpeg
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
    --enable-libxml2"
./configure --arch=x86_64 --target-os=mingw32 --cross-prefix=$host- --pkg-config=pkg-config --pkg-config-flags=--static --prefix=$prefix \
    --extra-libs=-lstdc++ --extra-cflags="$compiler_params" --extra-cxxflags="$compiler_params" --extra-ldflags="$compiler_params" \
    --extra-ldexeflags="$compiler_params" --extra-ldsoflags="$compiler_params" --logfile=./config.log $FFMPEG_OPTIONS
make -j $threads
make install
popd

popd #Back to upper-level directory