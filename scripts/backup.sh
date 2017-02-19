#! /bin/bash

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

MOUNTEDFOLDER=/mnt/bigstore
BACKUPFOLDER=$MOUNTEDFOLDER/backup
if mount | grep $MOUNTEDFOLDER > /dev/null; then
    echo "drive mounted"
else
    echo "drive not mounted, please mount a drive at $MOUNTEDFOLDER"

	exit 126
fi
OLDLABEL=.old

echo "deleting old old backup"
rm -rf "$BACKUPFOLDER$OLDLABEL"
echo "copying old backup to be perserved"
mv "$BACKUPFOLDER" "$BACKUPFOLDER$OLDLABEL"
mkdir -p BACKUPFOLDER

echo "mounting boot"
mount /dev/sda2 /boot

echo "doing the backup"
rsync -aAXv --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/media/*","/lost+found"} / $BACKUPFOLDER

echo "unmounting boot"
umount /boot

echo "trying to unmount $MOUNTEDFOLDER"
umount $MOUNTEDFOLDER
