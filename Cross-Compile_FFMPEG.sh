#!/bin/bash
set -x

#Configure Global Variables
host="x86_64-w64-mingw32"
prefix="$(pwd)/ffmpeg_install"
threads=2
compiler_params="-static-libgcc -static-libstdc++ -static -O3 -s"
export PKG_CONFIG_PATH="$prefix/lib/pkgconfig"

#Configure Package Variables
ffmpeg_release="n4.1.4"
fdk_release="v2.0.0"
x264_release="stable"
x265_release="stable"
srt_release="v1.3.2"

#Install Ubuntu Packages
#sudo apt install gcc-mingw-w64-x86-64 g++-mingw-w64-x86-64 yasm make automake autoconf git pkg-config libtool nasm mercurial cmake

#Get Packages
git clone https://github.com/mstorsjo/fdk-aac.git fdk-aac
pushd fdk-aac
git fetch --tags
git checkout $fdk_release -B release
popd

git clone https://code.videolan.org/videolan/x264.git x264
pushd x264
git checkout $x264_release -B release
popd

hg clone https://bitbucket.org/multicoreware/x265 -r $x265_release

git clone https://github.com/Haivision/srt.git srt
pushd srt
git checkout $srt_release -B release
popd

git clone https://git.ffmpeg.org/ffmpeg.git ffmpeg
pushd ffmpeg
git fetch --tags
git checkout $ffmpeg_release -B release
popd

#Build
pushd fdk-aac
./autogen.sh
./configure --host=$host --prefix=$prefix --enable-static --disable-shared
make -j $threads install
popd

pushd x264
./configure --host=$host --enable-static --cross-prefix=$host- --prefix=$prefix
make -j $threads install
popd

pushd x265
cd ./build
cmake -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_C_COMPILER=x86_64-w64-mingw32-gcc -DCMAKE_CXX_COMPILER=x86_64-w64-mingw32-g++ -DCMAKE_RC_COMPILER=x86_64-w64-mingw32-windres -DCMAKE_ASM_YASM_COMPILER=yasm -DCMAKE_CXX_FLAGS="$compiler_params" -DCMAKE_C_FLAGS="$compiler_params" -DCMAKE_SHARED_LIBRARY_LINK_C_FLAGS="$compiler_params" -DCMAKE_SHARED_LIBRARY_LINK_CXX_FLAGS="$compiler_params" -DENABLE_CLI=1 -DCMAKE_INSTALL_PREFIX=$prefix -DENABLE_SHARED=0 ../source
make -j $threads install
popd

#pushd srt
#./configure --use-static-libstdc++ --with-compiler-prefix=$host- --cmake_system_name=Generic --cmake_system=Generic --cmake_c_compiler=x86_64-w64-mingw32-gcc --cmake_cxx_compiler=x86_64-w64-mingw32-g++ --cmake_rc_compiler=x86_64-w64-mingw32-windres --cmake_cxx_flags="-static-libgcc -static-libstdc++ -static -o3 -s" --cmake_c_flags="-static-libgcc -static-libstdc++ -static -o3 -s" --cmake_shared_library_link_c_flags="-static-libgcc -static-libstdc++ -static -o3 -s" --cmake_shared_library_link_cxx_flags="-static-libgcc -static-libstdc++ -static -o3 -s" --cmake_install_prefix=$cross-prefix
#popd

pushd ffmpeg
./configure --arch=x86_64 --target-os=mingw32 --cross-prefix=$host- --pkg-config=pkg-config --pkg-config-flags=--static --prefix=$prefix --extra-libs=-lstdc++ --extra-cflags="$compiler_params" --extra-cxxflags="$compiler_params" --extra-ldflags="$compiler_params" --extra-ldexeflags="$compiler_params" --extra-ldsoflags="$compiler_params" --logfile=./config.log --enable-nonfree --enable-gpl --enable-libfdk-aac --enable-libx264 --enable-libx265
make -j $threads install
popd
