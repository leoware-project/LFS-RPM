#!/bin/bash
exit 0
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
[ -d $_sourcedir ] && rm -rf $_sourcedir
unpack "${PWD}" "${_package}-${_version}"

# cd to source dir
cd $_sourcedir

# prep
build2 "install -vdm 0755 build" $_log
build2 "cd build" $_log
build2 "CC=$LFS_TGT-gcc                \
AR=$LFS_TGT-ar                 \
RANLIB=$LFS_TGT-ranlib         \
../configure                   \
    --prefix=$TOOLS            \
    --disable-nls              \
    --disable-werror           \
    --with-lib-path=$TOOLS/lib \
    --with-sysroot=$LFS" $_log

# build
build2 "make $MKFLAGS" $_log

# install
build2 "make install" $_log

build2 "make -C ld clean" $_log
build2 "make -C ld LIB_PATH=/usr/lib:/lib" $_log
build2 "cp -v ld/ld-new $TOOLS/bin" $_log

# clean up
cd ..
rm -rf $_sourcedir

# make .completed file
touch $_completed

# exit sucessfully
exit 0
