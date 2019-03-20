#!/bin/bash
set -o errexit  # exit if error
set -o nounset  # exit if variable not initalized
set +h          # disable hashall

source $TOPDIR/config.inc
source $TOPDIR/function.inc
_prgname=${0##*/}   # script name minus the path

_package="multiarch_wrapper"
_version="0.1"
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
#[ -d gcc-build ] && build2 "rm -rf gcc-build" $_log
[ -d $_sourcedir ] && rm -rf $_sourcedir
#unpack "${PWD}" "${_package}-${_version}"
install -vdm 0755 $_sourcedir

# cd to source dir
cd $_sourcedir

# prep
cat > multiarch_wrapper.c << "EOF"
#define _GNU_SOURCE

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

#ifndef DEF_SUFFIX
#  define DEF_SUFFIX "64"
#endif

int main(int argc, char **argv)
{
  char *filename;
  char *suffix;

  if(!(suffix = getenv("USE_ARCH")))
    if(!(suffix = getenv("BUILDENV")))
      suffix = DEF_SUFFIX;

  if (asprintf(&filename, "%s-%s", argv[0], suffix) < 0) {
    perror(argv[0]);
    return -1;
  }

  int status = EXIT_FAILURE;
  pid_t pid = fork();

  if (pid == 0) {
    execvp(filename, argv);
    perror(filename);
  } else if (pid < 0) {
    perror(argv[0]);
  } else {
    if (waitpid(pid, &status, 0) != pid) {
      status = EXIT_FAILURE;
      perror(argv[0]);
    } else {
      status = WEXITSTATUS(status);
    }
  }

  free(filename);

  return status;
}

EOF
# build
build2 "gcc ${BUILD64} multiarch_wrapper.c -o /usr/bin/multiarch_wrapper" $_log

# test
echo 'echo "32bit Version"' > test-32
echo 'echo "64bit Version"' > test-64
chmod -v 755 test-32 test-64
ln -sfv /usr/bin/multiarch_wrapper test

USE_ARCH=32 ./test
USE_ARCH=64 ./test

# install

# clean up
build2 "cd .." $_log
#build2 "rm -rf gcc-build" $_log
build2 "rm -rf $_sourcedir" $_log

# make .completed file
build2 "touch $_completed" $_log

# exit sucessfully
exit 0
