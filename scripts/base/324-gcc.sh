#!/bin/bash
set -o errexit  # exit if error
set -o nounset  # exit if variable not initalized
set +h          # disable hashall

source $TOPDIR/config.inc
source $TOPDIR/function.inc
_prgname=${0##*/}   # script name minus the path

_package="gcc"
_version="7.3.0"
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
[ -d gcc-build ] && build2 "rm -rf gcc-build" $_log
[ -d $_sourcedir ] && rm -rf $_sourcedir
unpack "${PWD}" "${_package}-${_version}"

# cd to source dir
cd $_sourcedir

# prep
build2 "patch -Np1 -i ../../sources/gcc-7.3.0-specs-1.patch" $_log
build2 "patch -Np1 -i ../../sources/gcc-7.3.0-isl-0.20-includes-1.patch" $_log

build2 "sed -i 's@\./fixinc\.sh@-c true@' gcc/Makefile.in" $_log

build2 "mkdir -v ../gcc-build" $_log
build2 "cd ../gcc-build" $_log

build2 "SED=sed CC=\"gcc -isystem /usr/include ${BUILD64}\" \
CXX=\"g++ -isystem /usr/include ${BUILD64}\" \
LDFLAGS=\"-Wl,-rpath-link,/usr/lib64:/lib64:/usr/lib32:/lib32\" \
../gcc-7.3.0/configure \
    --prefix=/usr \
    --libdir=/usr/lib64 \
    --libexecdir=/usr/lib64 \
    --enable-languages=c,c++ \
    --with-system-zlib \
    --enable-install-libiberty \
    --disable-bootstrap \
    --with-multilib-list=m32,m64 \
    --enable-targets=x86_64-pc-linux-gnu,i686-pc-linux-gnu" $_log

# build
build2 "make $MKFLAGS" $_log

# test
#ulimit -s 32768
#build2 "make -k check" $_log

# install
build2 "make install" $_log

build2 "ln -sfv ../usr/bin/cpp /lib" $_log

build2 "mv -v /usr/lib32/libstdc++*gdb.py /usr/share/gdb/auto-load/usr/lib32" $_log
build2 "mv -v /usr/lib64/libstdc++*gdb.py /usr/share/gdb/auto-load/usr/lib64" $_log

# clean up
build2 "cd .." $_log
build2 "rm -rf gcc-build" $_log
build2 "rm -rf $_sourcedir" $_log

# make .completed file
build2 "touch $_completed" $_log

# exit sucessfully
exit 0
