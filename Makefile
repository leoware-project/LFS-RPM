LFS=/mnt/leoware
LFS_USER=samuel
TOOLS=/leoware-tools
CROSS_TOOLS=/leoware-cross


LOGDIR=logs


#all: update-scripts menuconfig setup toolchain base efi rpm boot








update-scripts:
#	cp -aurv /home/samuel/src/clfs/config.inc /mnt/clfs/usr/src/clfs/
#	cp -aurv /home/samuel/src/clfs/function.inc /mnt/clfs/usr/src/clfs/
#	cp -aurv /home/samuel/src/clfs/scripts/* /mnt/clfs/usr/src/clfs/scripts/
#	cp -aurv /home/samuel/src/clfs/build-clfs /mnt/clfs/usr/src/clfs/
#	cp -aurv /home/samuel/src/clfs/build-shell.sh /mnt/clfs/usr/src/clfs/
#	cp -aurv /home/samuel/src/clfs/bootfiles.sh /mnt/clfs/usr/src/clfs/
#	cp -aurv /home/samuel/src/clfs/toolchain.sh /mnt/clfs/usr/src/clfs/
#	cp -aurv /home/samuel/src/clfs/Makefile /mnt/clfs/usr/src/clfs/
#	cp -aurv /home/samuel/src/clfs/sources/* /mnt/clfs/usr/src/clfs/sources/


menuconfig: ${LOGDIR}/menuconfig.completed
	./menuconfig
	touch ${LOGDIR}/menuconfig.completed

setup: ${LOGDIR}/setup.completed ${LOGDIR}/menuconfig.completed
	./setup.sh

cross-tools: ${LOGDIR}/cross-tools.completed
	./cross-tools.sh

tools: ${LOGDIR}/tools.completed
	./tools.sh

chroot: ${LOGDIR}/tools.completed
	sudo ./tools-chroot

base: ${LOGDIR}/base.completed ${LOGDIR}/tools.completed
	./base.sh

efi: ${LOGDIR}/efi.completed ${LOGDIR}/base.completed
	./efi.sh

rpm: ${LOGDIR}/rpm.completed ${LOGDIR}/efi.completed
	./rpm.sh

boot: ${LOGDIR}/boot.completed ${LOGDIR}/rpm.completed
	./boot.sh


clean:
	rm -rf ${TOOLS}/*
	rm -rf ${CROSS_TOOLS}/*
	rm -rf ${LFS}/{bin,boot,dev,etc,home,lib,lib32,lib64,media,mnt,opt,proc,root,run,sbin,srv,sys,tmp,var}
	rm -rf ${LFS}/usr/{bin,include,lib,lib32,lib64,local,sbin,share}
	chown -R ${LFS_USER}:${LFS_USER} ${LFS}
	#cp -v leoware-bashrc /home/${LFS_USER}/.bashrc
	#chown ${LFS_USER}:${LFS_USER} /home/${LFS_USER}/.bashrc
	rm -f logs/*
	rm -rf build/*
	touch logs/setup.completed
	touch logs/menuconfig.completed

${LOGDIR}/menuconfig.completed: ;

${LOGDIR}/setup.completed: ;

${LOGDIR}/cross-tools.completed: ;

${LOGDIR}/tools.completed: ;

${LOGDIR}/base.completed: ;

${LOGDIR}/efi.completed: ;

${LOGDIR}/rpm.completed: ;

${LOGDIR}/boot.completed: ;
