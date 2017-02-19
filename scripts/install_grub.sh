#! /bin/bash

echo "refreshing mtab"
rm /etc/mtab
grep -v rootfs /proc/mounts > /etc/mtab
echo "installing grub"
grub-install --no-floppy /dev/sda
