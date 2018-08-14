set -xe
#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
date=$(date +%Y-%m-%d)

# the path to the partition mount point that we are backing up
source_partition=/home/

# where backup snapshots will be stored on the local partition
# this is needed for incremental backups
source_snapshot_dir=/var/local/snapshots

MOUNTEDFOLDER=/mnt/bigstore
# where backups will be stored on the backup drive
target_snapshot_dir=$MOUNTEDFOLDER

if mount | grep $MOUNTEDFOLDER > /dev/null; then
    echo "drive mounted"
else
    echo "drive not mounted, please mount a drive at $MOUNTEDFOLDER"

	exit 126
fi

if [ ! -d $source_snapshot_dir ]; then
	echo "If local snapshots exist don't"
    echo 'Creating initial snapshot...'
    mkdir --parents $source_snapshot_dir $target_snapshot_dir

    # create a read-only snapshot on the local disk
    btrfs subvolume snapshot -r $source_partition $source_snapshot_dir/$date

    # clone the snapshot as a new subvolume on the backup drive
    # you could also pipe this through ssh to back up to a remote machine
    btrfs send $source_snapshot_dir/$date | pv | \
        btrfs receive $target_snapshot_dir
elif [ ! -d $source_snapshot_dir/$date ]; then
	echo "if we haven't made a snapshot yet today"
    echo 'Creating root volume snapshot...'

    echo 'a create a read-only snapshot on the local disk'
    btrfs subvolume snapshot -r $source_partition $source_snapshot_dir/$date

    echo 'get the most recent snapshot'
    previous=$(ls --directory $source_snapshot_dir/* | tail -n 1)

    echo 'send (and store) only the changes since the last snapshot'
    btrfs send -p $previous $source_snapshot_dir/$date | pv | \
        btrfs receive $target_snapshot_dir
fi

echo 'Cleaning up...'

# keep the 3 most recent snapshots on the source partition
ls --directory $source_snapshot_dir/* | \
    head --lines=-3 | \
    xargs --no-run-if-empty --verbose \
    btrfs subvolume delete --commit-after

# keep the 28 most recent snapshots on the backup partition
ls --directory $target_snapshot_dir/* | \
    head --lines=-28 | \
    xargs --no-run-if-empty --verbose \
    btrfs subvolume delete --commit-after

echo "trying to unmount $MOUNTEDFOLDER"
umount $target_snapshot_dir
