#!/bin/bash
set -o errexit  # exit if error
set -o nounset  # exit if variable not initalized
set +h          # disable hashall

source $TOPDIR/config.inc
source $TOPDIR/function.inc
_prgname=${0##*/}   # script name minus the path

_package="readline"
_version="7.0"
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
#[ -d glibc-build ] && build2 "rm -rf glibc-build" $_log
[ -d $_sourcedir ] && rm -rf $_sourcedir
unpack "${PWD}" "${_package}-${_version}"

# cd to source dir
cd $_sourcedir

# prep
#build2 "mkdir -v ../glibc-build" $_log
#build2 "cd ../glibc-build" $_log

build2 "sed -i '/MV.*old/d' Makefile.in" $_log
build2 "sed -i '/{OLDSUFF}/c:' support/shlib-install" $_log

build2 "CC=\"gcc ${BUILD32}\" CXX=\"g++ ${BUILD32}\" \
./configure \
    --prefix=/usr \
    --libdir=/usr/lib32 \
    --disable-static \
    --docdir=/usr/share/doc/readline-7.0" $_log

# build
build2 "make SHLIB_LIBS=\"-L$TOOLS/lib32 -lncurses\" $MKFLAGS " $_log

# test
#build2 "make check" $_log

# install
build2 "make SHLIB_LIBS=\"-L$TOOLS/lib32 -lncurses\" htmldir=/usr/share/doc/readline-7.0 install" $_log

ln -svf ../../lib32/$(readlink /lib32/libreadline.so) /usr/lib32/libreadline.so
ln -svf ../../lib32/$(readlink /lib32/libhistory.so) /usr/lib32/libhistory.so
rm -v /lib32/lib{readline,history}.so

# clean up
build2 "cd .." $_log
#build2 "rm -rf glibc-build" $_log
build2 "rm -rf $_sourcedir" $_log

# make .completed file
build2 "touch $_completed" $_log

# exit sucessfully
exit 0
