#!/bin/bash
set -o errexit  # exit if error
set -o nounset  # exit if variable not initalized
set +h          # disable hashall

source $TOPDIR/config.inc
source $TOPDIR/function.inc
_prgname=${0##*/}   # script name minus the path

_package=""
_version=""
_sourcedir="${_package}-${_version}"
_log="$LFS_TOP/$LOGDIR/$_prgname.log"
_completed="$LFS_TOP/$LOGDIR/$_prgname.completed"

_red="\\033[1;31m"
_green="\\033[1;32m"
_yellow="\\033[1;33m"
_cyan="\\033[1;36m"
_normal="\\033[0;39m"


printf "${_green}==>${_normal} Adjust toolchain: "

[ -e $_completed ] && {
    printf "${_yellow}SKIPPING${_normal}\n"
    exit 0
} || printf "\n"

gcc -dumpspecs | \
perl -p \
     -e "s@$TOOLS@@g;" \
     -e "s@\*startfile_prefix_spec:\n@\$_/usr/lib64/ @g;" > \
     $(dirname $(gcc --print-libgcc-file-name))/specs

# make .completed file
build2 "touch $_completed" $_log

# exit sucessfully
exit 0
