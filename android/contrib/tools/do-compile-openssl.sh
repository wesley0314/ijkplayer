#! /usr/bin/env bash
#
# Copyright (C) 2014 Miguel Botón <waninkoko@gmail.com>
# Copyright (C) 2014 Zhang Rui <bbcallen@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#--------------------
set -e

if [ -z "$ANDROID_NDK" ]; then
    echo "You must define ANDROID_NDK before starting."
    echo "They must point to your NDK directories.\n"
    exit 1
fi

#--------------------
# common defines
FF_ARCH=$1
if [ -z "$FF_ARCH" ]; then
    echo "You must specific an architecture 'armv7a, arm64, x86, ...'.\n"
    exit 1
fi
#构建的那个地方的根目录
FF_BUILD_ROOT=`pwd`

#Android SDK API版本
FF_ANDROID_API=19

#构建名称
FF_BUILD_NAME=

#源码位置
FF_SOURCE=

#构建工具链前缀
FF_CROSS_PREFIX=

#构建CFLAGS
FF_CFG_FLAGS=

#构建Android ABI（就是平台架构）
FF_ANDROID_ABI=

#额外的构建CFLAGS/LDFLAGS
FF_EXTRA_CFLAGS=
FF_EXTRA_LDFLAGS=



#--------------------
echo ""
echo "--------------------"
echo "[*] make NDK standalone toolchain"
echo "--------------------"
. ./tools/do-detect-env.sh
FF_MAKE_TOOLCHAIN_FLAGS=$IJK_MAKE_TOOLCHAIN_FLAGS
FF_MAKE_FLAGS="$IJK_MAKE_FLAG"
FF_GCC_VER=$IJK_GCC_VER
FF_GCC_64_VER=$IJK_GCC_64_VER


#如果未指定，从Armv7a开始编译
if [ "$FF_ARCH" = "armv7a" ]; then
    FF_ANDROID_ARCH=arm
    FF_ANDROID_ABI="android-arm"
    
    FF_BUILD_NAME=openssl-armv7a
    FF_SOURCE=$FF_BUILD_ROOT/$FF_BUILD_NAME
	
    FF_CROSS_PREFIX=arm-linux-androideabi
	FF_TOOLCHAIN_NAME=${FF_CROSS_PREFIX}-${FF_GCC_VER}



elif [ "$FF_ARCH" = "x86" ]; then
    FF_ANDROID_ARCH=x86
    FF_ANDROID_ABI="android-x86"

    FF_BUILD_NAME=openssl-x86
    FF_SOURCE=$FF_BUILD_ROOT/$FF_BUILD_NAME
	
    FF_CROSS_PREFIX=i686-linux-android
	FF_TOOLCHAIN_NAME=x86-${FF_GCC_VER}

    FF_CFG_FLAGS="$FF_CFG_FLAGS no-asm"

elif [ "$FF_ARCH" = "x86_64" ]; then
    FF_ANDROID_ARCH=x86_64
    #Android 5.0.0开始支持64位架构，所以指定Api为21
    FF_ANDROID_API=21
    FF_ANDROID_ABI="android-x86_64"

    FF_BUILD_NAME=openssl-x86_64
    FF_SOURCE=$FF_BUILD_ROOT/$FF_BUILD_NAME

    FF_CROSS_PREFIX=x86_64-linux-android
    FF_TOOLCHAIN_NAME=${FF_CROSS_PREFIX}-${FF_GCC_64_VER}

elif [ "$FF_ARCH" = "arm64" ]; then
    FF_ANDROID_ARCH=arm64
    #Android 5.0.0开始支持64位架构，所以指定Api为21
    FF_ANDROID_API=21
    FF_ANDROID_ABI="android-arm64"

    FF_BUILD_NAME=openssl-arm64
    FF_SOURCE=$FF_BUILD_ROOT/$FF_BUILD_NAME

    FF_CROSS_PREFIX=aarch64-linux-android
    FF_TOOLCHAIN_NAME=${FF_CROSS_PREFIX}-${FF_GCC_64_VER}

else
    echo "unknown architecture $FF_ARCH";
    exit 1
fi

#工具链位置
FF_TOOLCHAIN_PATH=$ANDROID_NDK/toolchain/$FF_TOOLCHAIN_NAME/prebuilt/linux-x86_64
echo "-> 使用位于 $FF_TOOLCHAIN_PATH  的工具链"
#构建输出文件夹(就是生成库的位置)
FF_PREFIX="$FF_BUILD_ROOT/build/$FF_BUILD_NAME/output"
echo "-> 生成的文件在 $FF_PREFIX"
#创建构建输出文件夹
mkdir -p $FF_PREFIX


#--------------------
echo ""
echo "--------------------"
echo "[*] 配置openssl"
echo "--------------------"
export PATH=$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin:$PATH
export PATH=$FF_TOOLCHAIN_PATH/bin:$PATH
echo $PATH
export COMMON_FF_CFG_FLAGS=

FF_CFG_FLAGS="$FF_CFG_FLAGS $COMMON_FF_CFG_FLAGS"

#--------------------
# 构建选项:
FF_CFG_FLAGS="$FF_CFG_FLAGS zlib-dynamic"
#指定API
FF_CFG_FLAGS="$FF_CFG_FLAGS -D__ANDROID_API__=$FF_ANDROID_API"
#不构建共享库
FF_CFG_FLAGS="$FF_CFG_FLAGS no-shared"
#构建文件夹
FF_CFG_FLAGS="$FF_CFG_FLAGS --prefix=$FF_PREFIX"
#指定ABI
FF_CFG_FLAGS="$FF_CFG_FLAGS $FF_ANDROID_ABI"
#--------------------
cd $FF_SOURCE
#if [ -f "./Makefile" ]; then
#    echo 'reuse configure'
#else

    echo "./Configure $FF_CFG_FLAGS"
    ./Configure $FF_CFG_FLAGS 
#        --extra-cflags="$FF_CFLAGS $FF_EXTRA_CFLAGS" \
#        --extra-ldflags="$FF_EXTRA_LDFLAGS"
#fi

#--------------------
echo ""
echo "--------------------"
echo "[*] 编译 openssl"
echo "--------------------"
make depend
make $FF_MAKE_FLAGS
make install


