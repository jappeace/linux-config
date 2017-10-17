#!/bin/bash


cd /usr/src/linux
VERSION=`LC_ALL=C stat /usr/src/linux | grep File | sed s/File.\*x\-// | sed s/\-gentoo// | sed s/\'// | sed s/\ \*//`
echo "installing linux version: $VERSION"
echo "use: '$ eselect kernel list' to change"

MOUNTEDFOLDER=/boot
if mount | grep $MOUNTEDFOLDER > /dev/null; then
    echo "boot folder mounted"
else
	echo "boot folder not mounted, please mount at $MOUNTEDFOLDER"
	echo "(last time it was: $ mount /dev/nvme0n1p1 /boot)"
	exit 126
fi

KERNEL="kernel-"$VERSION"-gentoo"

IS_SAME_VERSION=0
if [ ! -f "/boot/$KERNEL" ]; then
	IS_SAME_VERSION=1
	echo "will rebuild dependend userland modules later"

fi

echo "cleaning old build"
make clean

echo "building and installing"
make -j$(nproc) && make modules_install && echo "removing old kernal" && rm /boot/$KERNEL

die() { echo "$@" 1>&2 ; exit 1; }

echo "copying new kernal"
cp arch/x86/boot/bzImage /boot/$KERNEL || die "WARNING: Couldn't copy kernel, probably ran out of disk space, exiting"

if (( IS_SAME_VERSION == 1 )); then
	echo "rebuilding modules"
	emerge @module-rebuild
fi

echo "redoing grub"
grub-mkconfig -o /boot/grub/grub.cfg
