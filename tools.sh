#!/bin/bash
#################################################
# Title:    tools.sh    			            #
# Date:     2019-03-01			                #
# Version:	0.1			                     	#
# Author:	<samuel@samuelraynor.com>	        #
# Options:					                    #
#################################################

set -o errexit  # exit if error
set -o nounset  # exit if variable not initalized
set +h          # disable hashall
source config.inc
source function.inc
PRGNAME=${0##*/}	# script name minus the path
LOGDIR="$LFS_TOP/$LOGDIR"
#
#	Main line
#
#msg "Building Chapter 5 Tool chain"
[ "${LFS_USER}" != $(whoami) ] && die "Not lfs user: FAILURE"
[ -z "${LFS_TARGET}" ]  && die "Environment not set: FAILURE"
[ "${LFS_TOP}" = $(pwd) ] && build2 "cd ${LFS_TOP}" "${LOGDIR}/toolchain.log"

# execute all toolchain scripts
for script in `find $LFS_TOP/scripts/{chroot,tools} -type f | sort`
do
    cd $LFS_TOP/$BUILDDIR

    export PATH=$CROSS_TOOLS/bin:/bin:/usr/bin
    export LC_ALL=POSIX

    export CC="${LFS_TARGET}-gcc ${BUILD64}"
    export CXX="${LFS_TARGET}-g++ ${BUILD64}"
    export AR="${LFS_TARGET}-ar"
    export AS="${LFS_TARGET}-as"
    export RANLIB="${LFS_TARGET}-ranlib"
    export LD="${LFS_TARGET}-ld"
    export STRIP="${LFS_TARGET}-strip"

    # execute the file
    TOPDIR=$LFS_TOP bash $script

done
exit 1
touch "$LOGDIR/tools.completed"
exit 0
