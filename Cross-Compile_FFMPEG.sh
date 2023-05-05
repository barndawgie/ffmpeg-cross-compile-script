#!/bin/bash
set -x

#Install ubuntu package dependencies before executing this script by running 'sudo ./Prep_System.sh'

#Configure Global Variables
host="x86_64-w64-mingw32"
build="x86_64-linux-gnu"
prefix="$(pwd)/ffmpeg_install"
patch_dir="$(pwd)/patches"
config_dir="$(pwd)/config"
library_path="$prefix/lib"
binary_path="$prefix/bin"
include_path="$prefix/include"
threads="1" #Seeing failures for some reason with parallel builds
configure_params="--host=$host --build=$build --prefix=$prefix --enable-static --disable-shared"
compiler_params="-static-libgcc -static-libstdc++ -static -O3 -s"
export PKG_CONFIG_PATH="$prefix/lib/pkgconfig"
export CFLAGS="-I$include_path"
export CPPFLAGS="-I$include_path"
export LDFLAGS="-L$library_path"

#Select Package Versions
bzip2_git="git://sourceware.org/git/bzip2.git"
bzip2_release="bzip2-1.0.8"
bzip_patchfile_path="$patch_dir/bzip2-1.0.8_brokenstuff.diff" #From https://raw.githubusercontent.com/rdp/ffmpeg-windows-build-helpers/master/patches/bzip2-1.0.8_brokenstuff.diff
bzip_pc_file_path="$patch_dir/bzip2.pc"
zlib_git="https://github.com/madler/zlib.git"
zlib_release="v1.2.13"
sdl_git="https://github.com/libsdl-org/SDL.git"
sdl_release="release-2.26.5"
openssl_git="https://github.com/openssl/openssl.git"
openssl_release="OpenSSL_1_1_1-stable"
libpng_git="https://github.com/glennrp/libpng.git"
libpng_release="v1.6.39"
libxml2_git="https://gitlab.gnome.org/GNOME/libxml2.git"
libxml2_release="v2.10.3"
libzimg_git="https://github.com/sekrit-twc/zimg.git"
libzimg_release="release-3.0.4"
libudfread_git="https://code.videolan.org/videolan/libudfread.git"
libudfread_release="1.1.2"

lame_download="https://versaweb.dl.sourceforge.net/project/lame/lame/3.100/lame-3.100.tar.gz"
fdk_git="https://github.com/mstorsjo/fdk-aac.git"
fdk_release="v2.0.2"

x264_git="https://code.videolan.org/videolan/x264.git"
x264_release="stable"
x265_hg="http://hg.videolan.org/x265"
x265_mri_path="$patch_dir/x265.mri"
libopenjpeg_git="https://github.com/uclouvain/openjpeg.git"
libopenjpeg_release="v2.5.0"
libaom_git="https://aomedia.googlesource.com/aom"
libaom_version="v3.6.0"
ffnvcodec_git="https://github.com/FFmpeg/nv-codec-headers.git"
ffnvcodec_release="n12.0.16.0"
libmfx_git="https://github.com/lu-zero/mfx_dispatch.git"
libmfx_release="master"

libfreetype2_git="https://gitlab.freedesktop.org/freetype/freetype.git"
libfreetype2_release="VER-2-13-0"
harfbuzz_git="https://github.com/harfbuzz/harfbuzz.git"
harfbuzz_release="7.1.0"
fribidi_git="https://github.com/fribidi/fribidi.git"
fribidi_release="v1.0.12" #Upgrade to v1.0.10 causes fribidi to not be found by ffmpeg; maybe due to https://github.com/fribidi/fribidi/issues/156?
fontconfig_git="https://gitlab.freedesktop.org/fontconfig/fontconfig.git"
fontconfig_release="2.14.2"
libass_git="https://github.com/libass/libass.git"
libass_release="0.14.0" #Verion 0.15.0 requires harfbuzz

srt_git="https://github.com/Haivision/srt.git"
srt_release="v1.5.1"
libbluray_git="https://code.videolan.org/videolan/libbluray.git"
libbluray_release="1.3.4"

ffmpeg_git="https://git.ffmpeg.org/ffmpeg.git"
ffmpeg_release="n6.0"

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
    --enable-nvdec \
    --enable-nvenc \
    --enable-libmp3lame \
    --enable-openssl \
    --enable-libfreetype \
    --enable-libfribidi \
    --enable-libass \
    --enable-libfontconfig \
    --enable-libsrt \
    --enable-libzimg \
    --enable-libmfx \
    --enable-libbluray"
    # Of Interest: --enable-libbluray --enable-libdav1d --enable-libopus --enable-libtheora --enable-libvmaf  --enable-libvorbis --enable-libvpx --enable-libwebp 

mkdir -p $include_path
mkdir -p $library_path
mkdir -p $PKG_CONFIG_PATH

mkdir -p packages
pushd packages #Put all these dependencies somewhere

#Build and Install Dependences

#Libs
mkdir -p libs
pushd libs

    #libbz2
    git clone -b $bzip2_release $bzip2_git bzip2
    pushd bzip2
    patch -p0 < $bzip_patchfile_path
    CC=$host-gcc AR=$host-ar RANLIB=$host-ranlib make -j $threads libbz2.a
    install -m644 bzlib.h $include_path/bzlib.h
    install -m644 libbz2.a $library_path/libbz2.a
    install -m644 $bzip_pc_file_path $PKG_CONFIG_PATH
    popd

    #ZLIB: Required for FreeTyep2
    git clone -b $zlib_release $zlib_git zlib
    pushd zlib
    sed -i /"PREFIX ="/d win32/Makefile.gcc
    ./configure -static --prefix=$host-
    BINARY_PATH=$binary_path INCLUDE_PATH=$include_path LIBRARY_PATH=$library_path PREFIX=$host- make -f win32/Makefile.gcc
    BINARY_PATH=$binary_path INCLUDE_PATH=$include_path LIBRARY_PATH=$library_path PREFIX=$host- make -f win32/Makefile.gcc install
    popd

    #SDL: Required for ffplay compilation
    git clone -b $sdl_release $sdl_git SDL
    pushd SDL
    ./autogen.sh
    mkdir -p build
    cd build
    ../configure $configure_params
    make install
    popd

    #openssl
    git clone -b $openssl_release $openssl_git openssl
    pushd openssl
    ./config --prefix=$prefix --cross-compile-prefix=$host- no-shared no-dso zlib
    CC=$host-gcc AR=$host-ar RANLIB=$host-ranlib RC=$host-windres ./Configure --prefix=$prefix -L$library_path -I$include_path no-shared no-dso zlib mingw64
    make -j $threads
    make install_sw
    popd

    #libpng: Required for FreeType2
    git clone -b $libpng_release $libpng_git libpng
    pushd libpng
    LDFLAGS="-L$library_path" CPPFLAGS="-I$include_path" ./configure $configure_params
    make -j $threads
    make install
    popd

    #Libxml2
    git clone -b $libxml2_release $libxml2_git libxml2
    pushd libxml2
    ./autogen.sh $configure_params --without-python
    make -j $threads
    make install
    popd

    #libzimg
    git clone -b $libzimg_release $libzimg_git zimg
    pushd zimg
    ./autogen.sh
    ./configure $configure_params
    make -j $threads
    make install
    popd

    #libudfread: Needed for libbluray
    git clone -b $libudfread_release $libudfread_git libudfread
    pushd libudfread
    autoreconf -i
    ./configure $configure_params
    make -j $threads
    make install
    popd


popd #leave libs directory

#Audio Codecs
mkdir -p audio
pushd audio

    #lameMP3
    if [ ! -d ./lame ]
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
    git clone -b $fdk_release $fdk_git fdk-aac
    pushd fdk-aac
    ./autogen.sh
    ./configure $configure_params
    make -j $threads
    make install
    popd

popd #leave audio directory

#Video Codecs
mkdir -p video
pushd video

    #x264: h.264 Video Encoding for ffmpeg
    git clone -b $x264_release $x264_git x264
    pushd x264
    ./configure --host=$host --enable-static --cross-prefix=$host- --prefix=$prefix
    make -j $threads
    make install
    popd

    #x265: HEVC Video Encoding for ffmpeg
    hg clone $x265_hg -r stable
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
    ar -M <$x265_mri_path
    make install
    popd

    #openjpeg: JPEG 2000 Codec
    git clone -b $libopenjpeg_release $libopenjpeg_git openjpeg
    pushd openjpeg
    mkdir -p build
    cd build
    cmake -DCMAKE_TOOLCHAIN_FILE="$config_dir/toolchain-x86_64-w64-mingw32.cmake" \
    	-DCMAKE_INSTALL_PREFIX=$prefix \
    	-DBUILD_THIRDPARTY=TRUE -DBUILD_SHARED_LIBS=0 \
        ..
    make -j $threads
    make install
    popd

    #libaom: AV1 Codec
    git clone -b $libaom_version $libaom_git aom
    pushd aom
    mkdir -p out
    cd  out
    cmake -DCMAKE_TOOLCHAIN_FILE="../build/cmake/toolchains/x86_64-mingw-gcc.cmake" \
        -DCMAKE_INSTALL_PREFIX=$prefix \
        ..
    make -j $threads
    make install
    popd

    #NVEnc/NVDec
    git clone -b $ffnvcodec_release $ffnvcodec_git ffnvcodec
    pushd ffnvcodec
    make install PREFIX=$prefix
    popd

    #libmfx
    git clone -b $libmfx_release $libmfx_git libmfx
    pushd libmfx
    autoreconf -i
    ./configure $configure_params
    make -j $threads
    make install
    popd

popd #leave video directory

# #Subtitle/Font Dependencies
mkdir -p subs
pushd subs

    #Libfreetype2: Required for Drawtext Filter
    git clone -b $libfreetype2_release $libfreetype2_git freetype2
    pushd freetype2
    ./autogen.sh
    ./configure $configure_params --with-zlib=yes --with-png=yes --with-bzip2=yes --with-brotli=no --with-harfbuzz=no
    make -j $threads
    make install
    popd

    #Harfbuzz: Optional for libass
    git clone -b $harfbuzz_release $harfbuzz_git harfbuzz
    pushd harfbuzz
    ./autogen.sh $configure_params
    make -j $threads
    make install
    popd

    # #Rebuild Freetype2 with HarfBuzz - This seems to work but then seems to break Fontconfig build?
    # pushd freetype2
    # ./configure $configure_params --with-zlib=yes --with-png=yes --with-bzip2=yes --with-brotli=yes --with-harfbuzz=yes
    # make -j $threads
    # make install
    # popd

    #libfribidi: Required for Libass
    git clone -b $fribidi_release $fribidi_git fribidi
    pushd fribidi
    ./autogen.sh $configure_params
    make -j $threads
    make install
    popd

    #Fontconfig: Improves Drawtext Filter, HarfBuzz
    git clone -b $fontconfig_release $fontconfig_git fontconfig
    pushd fontconfig
    ./autogen.sh $configure_params --enable-libxml2
    make -j $threads
    make install
    popd

    #libass
    git clone -b $libass_release $libass_git libass
    pushd libass
    ./autogen.sh
    ./configure $configure_params
    make -j $threads
    make install
    popd

popd #Leave subs directory

mkdir -p protocols
pushd protocols

    #SRT
    git clone -b $srt_release $srt_git srt
    pushd srt
    mkdir -p out
    cd out
    cmake -DCMAKE_TOOLCHAIN_FILE="$config_dir/toolchain-x86_64-w64-mingw32.cmake" \
        -DCMAKE_INSTALL_PREFIX=$prefix \
        -DENABLE_SHARED=0 \
        -DENABLE_STATIC=1 \
        -DENABLE_DEBUG=0 \
        -DENABLE_APPS=0 \
        ..
    make -j $threads
    make install
    popd

    #libbluray
    git clone -b $libbluray_release $libbluray_git libbluray
    pushd libbluray
    autoreconf -i
    ./configure $configure_params  --disable-doxygen-doc --disable-bdjava-jar
    make -j $threads
    make install
    popd

popd

#Download, Configure, and Build ffmpeg, ffprobe, and ffplay
git clone -b $ffmpeg_release $ffmpeg_git ffmpeg
pushd ffmpeg
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
#Make and install tools
make -j $threads alltools
mkdir -p $binary_path/tools/
cp ./tools/*.exe $binary_path/tools/
popd

popd #Back to upper-level directory
echo "If successful, executables now available at $binary_path"
