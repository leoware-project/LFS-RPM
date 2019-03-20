#!/bin/bash
set -o errexit  # exit if error
set -o nounset  # exit if variable not initalized
set +h          # disable hashall

source $TOPDIR/config.inc
source $TOPDIR/function.inc
_prgname=${0##*/}   # script name minus the path

_package="glibc"
_version="2.27"
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
[ -d glibc-build ] && build2 "rm -rf glibc-build" $_log
[ -d $_sourcedir ] && rm -rf $_sourcedir
unpack "${PWD}" "${_package}-${_version}"

# cd to source dir
cd $_sourcedir

# prep
build2 "patch -Np1 -i ../../sources/glibc-2.27-fhs-1.patch" $_log

LINKER=$(readelf -l $TOOLS/bin/bash | sed -n "s@.*interpret.*$TOOLS\(.*\)]\$@\1@p")
sed -i "s|libs -o|libs -L/usr/lib32 -Wl,-dynamic-linker=${LINKER} -o|" \
  scripts/test-installation.pl
unset LINKER

build2 "mkdir -v ../glibc-build" $_log
build2 "cd ../glibc-build" $_log

build2 "CC=\"gcc ${BUILD32}\" CXX=\"g++ ${BUILD32}\" \
../glibc-2.27/configure \
    --prefix=/usr \
    --enable-kernel=3.2 \
    --libexecdir=/usr/lib32/glibc \
    --libdir=/usr/lib32 \
    --host=${LFS_TARGET32} \
    --enable-stack-protector=strong \
    --enable-multi-arch \
    libc_cv_slibdir=/lib32" $_log

# build
build2 "make $MKFLAGS" $_log

# test
build2 "sed -i '/cross-compiling/s@ifeq@ifneq@g' ../glibc-2.27/localedata/Makefile" $_log
#build2 "make check" $_log

# install
build2 "touch /etc/ld.so.conf" $_log
build2 "sed '/test-installation/s@\$(PERL)@echo not running@' -i ../glibc-2.27/Makefile" $_log
build2 "make install" $_log
#build2 "rm -v /usr/include/rpcsvc/*.x" $_log

# clean up
build2 "cd .." $_log
build2 "rm -rf glibc-build" $_log
build2 "rm -rf $_sourcedir" $_log

# make .completed file
build2 "touch $_completed" $_log

# exit sucessfully
exit 0
