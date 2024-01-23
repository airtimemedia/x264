#!/bin/bash

PATH="$PATH:/usr/local/bin:/opt/homebrew/bin"

DIR="$1"
CC="$2"
CFLAGS="$3"
OS="$4"
ARCH="$5"
CCACHE="$6"
AR="$7"
RANLIB="$8"
LDFLAGS="$9"
NASM="${10}"

# Default AS to Nasm for x86_64
# Nasm of at least 2.13 is required
if [ "$ARCH" = "x86_64" ] ; then
  AS=${NASM}
fi

# TODO: disable stuff we're not using
CONFIG_OPTS=" --disable-swscale --disable-lavf --disable-ffms"

echo "CC: ${CC}"
echo "CFLAGS: ${CFLAGS}"
echo "OS: ${OS}"
echo "ARCH: ${ARCH}"
echo "AR: ${AR}"

if [ "$OS" = "android" ] ; then
  CONFIG_OPTS="${CONFIG_OPTS} --host=armv7"
  export AR
  export RANLIB
  export CPP="${CC} -E"
elif [ "x$OS" = "xosx" ] ; then
  OS=darwin12
  CONFIG_OPTS="$CONFIG_OPTS --host=x86_64-apple-darwin"
elif [ "x$OS" = "xios" ] ; then
  OS=darwin
  if [ "x$ARCH" = "xi386" -o "x$ARCH" = "xx86_64" ] ; then
    SDK="iphonesimulator"
    OS=darwin12
  else
    SDK="iphoneos"
    CONFIG_OPTS="${CONFIG_OPTS} --host=arm-apple-darwin"
  fi
  CC="xcrun -sdk ${SDK} clang -arch ${ARCH}"
  if [ "x$CCACHE" != "x" ]; then
    CC="$CCACHE $CC"
  fi
elif [ "x$OS" = "xlinux" ] ; then
  if [[ $CFLAGS == *"-fPIC"* ]] ; then
    CONFIG_OPTS="${CONFIG_OPTS} --enable-pic"
  fi
fi

export CC
export CFLAGS
export LDFLAGS
export AS

${DIR}/configure ${CONFIG_OPTS}

