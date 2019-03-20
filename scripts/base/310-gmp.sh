#!/bin/bash
set -o errexit  # exit if error
set -o nounset  # exit if variable not initalized
set +h          # disable hashall

source $TOPDIR/config.inc
source $TOPDIR/function.inc
_prgname=${0##*/}   # script name minus the path

_package="gmp"
_version="6.1.2"
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

build2 "CC=\"gcc -isystem /usr/include ${BUILD64}\" \
CXX=\"g++ -isystem /usr/include ${BUILD64}\" \
LDFLAGS=\"-Wl,-rpath-link,/usr/lib64:/lib64 ${BUILD64}\" \
./configure \
    --prefix=/usr \
    --libdir=/usr/lib64 \
    --enable-cxx \
    --docdir=/usr/share/doc/gmp-6.1.2" $_log

# build
build2 "make $MKFLAGS" $_log
build2 "make html" $_log

# test
build2 "make check" $_log

# install
build2 "make install" $_log
build2 "make install-html" $_log

build2 "mv -v /usr/include/gmp{,-64}.h" $_log

cat > /usr/include/gmp.h << "EOF"
/* gmp.h - Stub Header  */
#ifndef __STUB__GMP_H__
#define __STUB__GMP_H__

#if defined(__x86_64__) || \
    defined(__sparc64__) || \
    defined(__arch64__) || \
    defined(__powerpc64__) || \
    defined (__s390x__)
# include "gmp-64.h"
#else
# include "gmp-32.h"
#endif

#endif /* __STUB__GMP_H__ */
EOF


# clean up
build2 "cd .." $_log
#build2 "rm -rf glibc-build" $_log
build2 "rm -rf $_sourcedir" $_log

# make .completed file
build2 "touch $_completed" $_log

# exit sucessfully
exit 0
