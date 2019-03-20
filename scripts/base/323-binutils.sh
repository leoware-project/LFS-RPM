#!/bin/bash
set -o errexit  # exit if error
set -o nounset  # exit if variable not initalized
set +h          # disable hashall

source $TOPDIR/config.inc
source $TOPDIR/function.inc
_prgname=${0##*/}   # script name minus the path

_package="binutils"
_version="2.30"
_sourcedir="${_package}-${_version}"
_log="$LFS_TOP/$LOGDIR/$_prgname.log"
_completed="$LFS_TOP/$LOGDIR/$_prgname.completed"

_red="\\033[1;31m"
_green="\\033[1;32m"
_yellow="\\033[1;33m"
_cyan="\\033[1;36m"
_normal="\\033[0;39m"


printf "${_green}==>${_normal} Building $_package-$_version: "

[ -e $_completed ] && {
    printf "${_yellow}SKIPPING${_normal}\n"
    exit 0
} || printf "\n"

# unpack sources
[ -d binutils-build ] && build2 "rm -rf binutils-build" $_log
[ -d $_sourcedir ] && rm -rf $_sourcedir
unpack "${PWD}" "${_package}-${_version}"

# cd to source dir
cd $_sourcedir

# prep

build2 "mkdir -v ../binutils-build" $_log
build2 "cd ../binutils-build" $_log

build2 "CC=\"gcc -isystem /usr/include ${BUILD64}\" \
LDFLAGS=\"-Wl,-rpath-link,/usr/lib64:/lib64:/usr/lib32:/lib32 ${BUILD64}\" \
../binutils-2.30/configure \
    --prefix=/usr \
    --enable-shared \
    --disable-werror \
    --enable-64-bit-bfd \
    --libdir=/usr/lib64 \
    --enable-gold=yes \
    --enable-plugins \
    --with-system-zlib \
    --enable-ld=default \
    --enable-threads" $_log

# build
build2 "make $MKFLAGS tooldir=/usr" $_log

# test
#build2 "make check" $_log

# install
build2 "make tooldir=/usr install" $_log

# clean up
build2 "cd .." $_log
build2 "rm -rf binutils-build" $_log
build2 "rm -rf $_sourcedir" $_log

# make .completed file
build2 "touch $_completed" $_log

# exit sucessfully
exit 0
