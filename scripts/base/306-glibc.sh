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
sed -i "s|libs -o|libs -L/usr/lib64 -Wl,-dynamic-linker=${LINKER} -o|" \
  scripts/test-installation.pl
unset LINKER

build2 "mkdir -v ../glibc-build" $_log
build2 "cd ../glibc-build" $_log

build2 "CC=\"gcc ${BUILD64}\" CXX=\"g++ ${BUILD64}\" \
../glibc-2.27/configure \
    --prefix=/usr \
    --enable-kernel=3.2 \
    --libexecdir=/usr/lib64/glibc \
    --libdir=/usr/lib64 \
    --host=${LFS_TARGET} \
    --enable-stack-protector=strong \
    --enable-multi-arch \
    libc_cv_slibdir=/lib64" $_log

# build
build2 "make $MKFLAGS" $_log

# test
#build2 "sed -i '/cross-compiling/s@ifeq@ifneq@g' ../glibc-2.27/localedata/Makefile" $_log
#build2 "make check" $_log

# install
build2 "make install" $_log
#build2 "rm -v /usr/include/rpcsvc/*.x" $_log

build2 "cp -v ../glibc-2.27/nscd/nscd.conf /etc/nscd.conf" $_log
build2 "mkdir -pv /var/cache/nscd" $_log

build2 "install -v -Dm644 ../glibc-2.27/nscd/nscd.tmpfiles /usr/lib/tmpfiles.d/nscd.conf" $_log
build2 "install -v -Dm644 ../glibc-2.27/nscd/nscd.service /lib/systemd/system/nscd.service" $_log

mkdir -pv /usr/lib/locale
localedef -i cs_CZ -f UTF-8 cs_CZ.UTF-8
localedef -i de_DE -f ISO-8859-1 de_DE
localedef -i de_DE@euro -f ISO-8859-15 de_DE@euro
localedef -i de_DE -f UTF-8 de_DE.UTF-8
localedef -i en_GB -f UTF-8 en_GB.UTF-8
localedef -i en_HK -f ISO-8859-1 en_HK
localedef -i en_PH -f ISO-8859-1 en_PH
localedef -i en_US -f ISO-8859-1 en_US
localedef -i en_US -f UTF-8 en_US.UTF-8
localedef -i es_MX -f ISO-8859-1 es_MX
localedef -i fa_IR -f UTF-8 fa_IR
localedef -i fr_FR -f ISO-8859-1 fr_FR
localedef -i fr_FR@euro -f ISO-8859-15 fr_FR@euro
localedef -i fr_FR -f UTF-8 fr_FR.UTF-8
localedef -i it_IT -f ISO-8859-1 it_IT
localedef -i it_IT -f UTF-8 it_IT.UTF-8
localedef -i ja_JP -f EUC-JP ja_JP
localedef -i ru_RU -f KOI8-R ru_RU.KOI8-R
localedef -i ru_RU -f UTF-8 ru_RU.UTF-8
localedef -i tr_TR -f UTF-8 tr_TR.UTF-8
localedef -i zh_CN -f GB18030 zh_CN.GB18030

cat > /etc/nsswitch.conf << "EOF"
# Begin /etc/nsswitch.conf

passwd: files
group: files
shadow: files

hosts: files dns
networks: files

protocols: files
services: files
ethers: files
rpc: files

# End /etc/nsswitch.conf
EOF

unpack "$PWD" "tzdata2018c"

ZONEINFO=/usr/share/zoneinfo
mkdir -pv $ZONEINFO/{posix,right}

for tz in etcetera southamerica northamerica europe africa antarctica  \
          asia australasia backward pacificnew systemv; do
    zic -L /dev/null   -d $ZONEINFO       -y "sh yearistype.sh" ${tz}
    zic -L /dev/null   -d $ZONEINFO/posix -y "sh yearistype.sh" ${tz}
    zic -L leapseconds -d $ZONEINFO/right -y "sh yearistype.sh" ${tz}
done

cp -v zone.tab zone1970.tab iso3166.tab $ZONEINFO
zic -d $ZONEINFO -p America/Los_Angeles
unset ZONEINFO

build2 "ln -sfv /usr/share/zoneinfo/America/Los_Angeles /etc/localtime" $_log

cat > /etc/ld.so.conf << "EOF"
# Begin /etc/ld.so.conf
/usr/local/lib64
/usr/local/lib32
/usr/lib64
/usr/lib32
/lib64
/lib32
/opt/lib64
/opt/lib32
/opt/lib

# Add an include directory
include /etc/ld.so.conf.d/*.conf

EOF

build2 "install -vdm 0755 /etc/ld.so.conf.d" $_log


# clean up
build2 "cd .." $_log
build2 "rm -rf glibc-build" $_log
build2 "rm -rf $_sourcedir" $_log

# make .completed file
build2 "touch $_completed" $_log

# exit sucessfully
exit 0
