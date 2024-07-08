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
zlib_release="v1.3"
sdl_git="https://github.com/libsdl-org/SDL.git"
sdl_release="release-2.28.5"
openssl_git="https://github.com/openssl/openssl.git"
openssl_release="OpenSSL_1_1_1-stable"
libpng_git="https://github.com/glennrp/libpng.git"
libpng_release="v1.6.40"
libxml2_git="https://gitlab.gnome.org/GNOME/libxml2.git"
libxml2_release="v2.13.2"
libzimg_git="https://github.com/sekrit-twc/zimg.git"
libzimg_release="release-3.0.5"
libudfread_git="https://code.videolan.org/videolan/libudfread.git"
libudfread_release="1.1.2"

lame_download="https://versaweb.dl.sourceforge.net/project/lame/lame/3.100/lame-3.100.tar.gz"
fdk_git="https://github.com/mstorsjo/fdk-aac.git"
fdk_release="v2.0.3"

x264_git="https://code.videolan.org/videolan/x264.git"
x264_release="stable"
x265_git="https://bitbucket.org/multicoreware/x265_git.git"
x265_release="3.5"
x265_mri_path="$patch_dir/x265.mri"
libopenjpeg_git="https://github.com/uclouvain/openjpeg.git"
libopenjpeg_release="v2.5.0"
libaom_git="https://aomedia.googlesource.com/aom"
libaom_version="v3.8.0"
ffnvcodec_git="https://github.com/FFmpeg/nv-codec-headers.git"
ffnvcodec_release="n12.1.14.0"

libfreetype2_git="https://gitlab.freedesktop.org/freetype/freetype.git"
libfreetype2_release="VER-2-13-2"
harfbuzz_git="https://github.com/harfbuzz/harfbuzz.git"
harfbuzz_release="8.3.0"
fribidi_git="https://github.com/fribidi/fribidi.git"
fribidi_release="v1.0.13"
fontconfig_git="https://gitlab.freedesktop.org/fontconfig/fontconfig.git"
fontconfig_release="2.15.0"
libass_git="https://github.com/libass/libass.git"
libass_release="0.17.1"

srt_git="https://github.com/Haivision/srt.git"
srt_release="v1.5.3"
libbluray_git="https://code.videolan.org/videolan/libbluray.git"
libbluray_release="1.3.4"

ffmpeg_git="https://git.ffmpeg.org/ffmpeg.git"
ffmpeg_release="n6.1.1"

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
    --enable-libbluray"
    #--enable-libmfx
    # Of Interest: --enable-libdav1d --enable-libopus --enable-libtheora --enable-libvmaf  --enable-libvorbis --enable-libvpx --enable-libwebp

# Helper Methods
do_git_checkout () {
  local repo_url="$1"
  local tag="$2"
  local to_dir="$3"

  if [ ! -d $to_dir ]; then
    echo "Cloning $repo_url@$tag to $to_dir"
    git clone -b $tag $repo_url $to_dir
  else
    echo "Skipping clone as $to_dir is already present."
  fi
}

#Build and Install Dependences

mkdir -p $include_path
mkdir -p $library_path
mkdir -p $PKG_CONFIG_PATH

mkdir -p packages
pushd packages || exit #Put all these dependencies somewhere

#Libs
mkdir -p libs
pushd libs || exit

    #libbz2
    do_git_checkout $bzip2_git $bzip2_release bzip2
    pushd bzip2 || exit
    patch -p0 < $bzip_patchfile_path
    CC=$host-gcc AR=$host-ar RANLIB=$host-ranlib make -j $threads libbz2.a
    install -m644 bzlib.h $include_path/bzlib.h
    install -m644 libbz2.a $library_path/libbz2.a
    install -m644 $bzip_pc_file_path $PKG_CONFIG_PATH
    popd || exit

    #zlib
    do_git_checkout $zlib_git $zlib_release zlib
    pushd zlib || exit
    sed -i /"PREFIX ="/d win32/Makefile.gcc
    ./configure -static --prefix=$host-
    BINARY_PATH=$binary_path INCLUDE_PATH=$include_path LIBRARY_PATH=$library_path PREFIX=$host- make -f win32/Makefile.gcc
    BINARY_PATH=$binary_path INCLUDE_PATH=$include_path LIBRARY_PATH=$library_path PREFIX=$host- make -f win32/Makefile.gcc install
    popd || exit

    #SDL: Required for ffplay compilation
    do_git_checkout $sdl_git $sdl_release SDL
    pushd SDL || exit
    ./autogen.sh
    mkdir -p build
    cd build || exit
    ../configure $configure_params
    make install
    popd || exit

    #openssl
    do_git_checkout $openssl_git $openssl_release openssl
    pushd openssl || exit
    ./config --prefix=$prefix --cross-compile-prefix=$host- no-shared no-dso zlib
    CC=$host-gcc AR=$host-ar RANLIB=$host-ranlib RC=$host-windres ./Configure --prefix=$prefix -L$library_path -I$include_path no-shared no-dso zlib mingw64
    make -j $threads
    make install_sw
    popd || exit

    #libpng: Required for FreeType2
    do_git_checkout $libpng_git $libpng_release libpng
    pushd libpng || exit
    LDFLAGS="-L$library_path" CPPFLAGS="-I$include_path" ./configure $configure_params
    make -j $threads
    make install
    popd || exit

    #Libxml2
    do_git_checkout $libxml2_git $libxml2_release libxml2
    pushd libxml2 || exit
    ./autogen.sh $configure_params --without-python
    make -j $threads
    make install
    popd || exit

    #libzimg
    do_git_checkout $libzimg_git $libzimg_release zimg
    pushd zimg || exit
    ./autogen.sh
    ./configure $configure_params
    make -j $threads
    make install
    popd || exit

    #libudfread: Needed for libbluray
    do_git_checkout $libudfread_git $libudfread_release libudfread
    pushd libudfread || exit
    autoreconf -i
    ./configure $configure_params
    make -j $threads
    make install
    popd || exit

popd || exit #leave libs directory

# #Subtitle/Font Dependencies
mkdir -p subs
pushd subs || exit

    #Libfreetype2: Required for Drawtext Filter
    do_git_checkout $libfreetype2_git $libfreetype2_release freetype2
    pushd freetype2 || exit
    ./autogen.sh
    ./configure $configure_params --with-zlib=yes --with-png=yes --with-bzip2=yes --with-brotli=no --with-harfbuzz=no
    make -j $threads
    make install
    popd || exit

    #Harfbuzz: Needed for libass
    do_git_checkout $harfbuzz_git $harfbuzz_release harfbuzz
    pushd harfbuzz || exit
    ./autogen.sh $configure_params --with-icu=no --with-glib=no #Still seeing some weird build failures with glib
    make -j $threads
    make install
    popd || exit

    # #Rebuild Freetype2 with HarfBuzz - This seems to work but then seems to break Fontconfig build?
    # pushd freetype2
    # ./configure $configure_params --with-zlib=yes --with-png=yes --with-bzip2=yes --with-brotli=yes --with-harfbuzz=yes
    # make -j $threads
    # make install
    # popd || exit

    #libfribidi: Required for Libass
    do_git_checkout $fribidi_git $fribidi_release fribidi
    pushd fribidi || exit
    ./autogen.sh $configure_params
    make -j $threads
    make install
    popd || exit

    #Fontconfig: Improves Drawtext Filter, HarfBuzz
    do_git_checkout $fontconfig_git $fontconfig_release fontconfig
    pushd fontconfig || exit
    ./autogen.sh $configure_params --enable-libxml2
    make -j $threads
    make install
    popd || exit

    #libass
    do_git_checkout $libass_git $libass_release libass
    pushd libass || exit
    ./autogen.sh
    ./configure $configure_params
    make -j $threads
    make install
    popd || exit

popd || exit #Leave subs directory

#Audio Codecs
mkdir -p audio
pushd audio || exit

    #lameMP3
    if [ ! -d ./lame ]
    then
        mkdir -p lame
        curl $lame_download -o lame.tar.gz
        tar -xvzf lame.tar.gz --directory lame --strip-components=1
        rm lame.tar.gz
    fi
    pushd lame || exit
    ./configure $configure_params --disable-gtktest --enable-nasm
    make -j $threads
    make install
    popd || exit

    #FDK: The Best AAC Codec for ffmpeg
    do_git_checkout $fdk_git $fdk_release fdk-aac
    pushd fdk-aac || exit
    ./autogen.sh
    ./configure $configure_params
    make -j $threads
    make install
    popd || exit

popd || exit #leave audio directory

#Video Codecs
mkdir -p video
pushd video || exit

    #x264: h.264 Video Encoding for ffmpeg
    do_git_checkout $x264_git $x264_release x264
    pushd x264 || exit
    ./configure --host=$host --enable-static --cross-prefix=$host- --prefix=$prefix
    make -j $threads
    make install
    popd || exit

    #x265: HEVC Video Encoding for ffmpeg
    do_git_checkout $x265_git $x265_release x265
    pushd x265 || exit
    cd ./build || exit

    mkdir -p 8bit 10bit 12bit

    #Build 12-Bit
    cd 12bit || exit
    cmake -DCMAKE_TOOLCHAIN_FILE="$config_dir/toolchain-x86_64-w64-mingw32.cmake" \
    	-DCMAKE_INSTALL_PREFIX=$prefix -DENABLE_SHARED=OFF \
        -DENABLE_CLI=OFF -DEXPORT_C_API=OFF \
        -DHIGH_BIT_DEPTH=ON -DMAIN12=ON \
        ../../source
    make -j $threads

    #Build 10-Bit
    cd  ../10bit || exit
    cmake -DCMAKE_TOOLCHAIN_FILE="$config_dir/toolchain-x86_64-w64-mingw32.cmake" \
        -DCMAKE_INSTALL_PREFIX=$prefix -DENABLE_SHARED=OFF \
        -DENABLE_CLI=OFF -DEXPORT_C_API=OFF \
        -DHIGH_BIT_DEPTH=ON -DMAIN12=OFF \
        ../../source
    make -j $threads

    #Build 8-Bit
    cd ../8bit || exit
    ln -sf ../10bit/libx265.a libx265_main10.a
    ln -sf ../12bit/libx265.a libx265_main12.a
    cmake -DCMAKE_TOOLCHAIN_FILE="$config_dir/toolchain-x86_64-w64-mingw32.cmake" \
        -DCMAKE_INSTALL_PREFIX=$prefix -DENABLE_SHARED=OFF \
        -DENABLE_CLI=OFF -DEXPORT_C_API=ON \
        -DEXTRA_LIB="x265_main10.a;x265_main12.a" -DEXTRA_LINK_FLAGS=-L. -DLINKED_10BIT=ON -DLINKED_12BIT=ON \
        ../../source
    make -j $threads

    #Combine all x265 Libraries
    mv libx265.a libx265_main.a
    ar -M <$x265_mri_path
    make install
    popd || exit

    #openjpeg: JPEG 2000 Codec
    do_git_checkout $libopenjpeg_git $libopenjpeg_release openjpeg
    pushd openjpeg || exit
    mkdir -p build
    cd build || exit
    cmake -DCMAKE_TOOLCHAIN_FILE="$config_dir/toolchain-x86_64-w64-mingw32.cmake" \
    	-DCMAKE_INSTALL_PREFIX=$prefix \
    	-DBUILD_THIRDPARTY=TRUE -DBUILD_SHARED_LIBS=0 \
        ..
    make -j $threads
    make install
    popd || exit

    #libaom: AV1 Codec
    do_git_checkout $libaom_git $libaom_version aom
    pushd aom || exit
    mkdir -p out
    cd out || exit
    cmake -DCMAKE_TOOLCHAIN_FILE="../build/cmake/toolchains/x86_64-mingw-gcc.cmake" \
        -DCMAKE_INSTALL_PREFIX=$prefix \
        ..
    make -j $threads
    make install
    popd || exit

    #NVEnc/NVDec
    do_git_checkout $ffnvcodec_git $ffnvcodec_release ffnvcodec
    pushd ffnvcodec || exit
    make install PREFIX=$prefix
    popd || exit

popd || exit #leave video directory

mkdir -p protocols
pushd protocols || exit

    #SRT
    do_git_checkout $srt_git $srt_release srt
    pushd srt || exit
    mkdir -p out
    cd out || exit
    cmake -DCMAKE_TOOLCHAIN_FILE="$config_dir/toolchain-x86_64-w64-mingw32.cmake" \
        -DCMAKE_INSTALL_PREFIX=$prefix \
        -DENABLE_SHARED=0 \
        -DENABLE_STATIC=1 \
        -DENABLE_DEBUG=0 \
        -DENABLE_APPS=0 \
        ..
    make -j $threads
    make install
    popd || exit

    #libbluray
    do_git_checkout $libbluray_git $libbluray_release libbluray
    pushd libbluray || exit
    autoreconf -i
    ./configure $configure_params  --disable-doxygen-doc --disable-bdjava-jar
    make -j $threads
    make install
    popd || exit

popd || exit

#Download, Configure, and Build ffmpeg, ffprobe, and ffplay
do_git_checkout $ffmpeg_git $ffmpeg_release ffmpeg
pushd ffmpeg || exit
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
popd || exit

popd || exit #Back to upper-level directory
echo "If successful, executables now available at $binary_path"
