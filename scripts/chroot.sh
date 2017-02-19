#! /bin/bash

echo "mounting boot"
mount /dev/sda2 /mnt/gentoo/boot

echo "mounting sys dev & proc"
mount -t proc none /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev
mount --rbind /etc/resolv.conf /mnt/gentoo/etc/resolv.conf

echo "changing root"
chroot /mnt/gentoo /home/.changerootFinal.sh
