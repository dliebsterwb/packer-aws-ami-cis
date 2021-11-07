#!/bin/bash

set -xe

#This script has logic to create partitions volume groups and logical volumes which we will use to create root partition with LVM support

echo "\n\n  Skipping CIS partitionioning owing to OneFS configuration \n\n"

readonly local dev="/dev/nvme1n1"
readonly local target_dev="/dev/nvme0n1"
readonly local mntpoint="/mnt"

 [ ! -d "${mntpoint}" ] && \
 errx "cannot find mountpoint '${mntpoint}'"

#parted used to create partitions in {dev}
#Will be creating two partitions
#1 for boot {dev}1
#2 for creating volume group and logical volumes


partprobe
parted -s -a optimal ${dev} mklabel gpt -- mkpart primary ext4 1 -1 || exit 1
partprobe

echo "/n ========= DIAGS ========================"
partprobe -s
lsblk
fdisk -l 
ls -all /dev/nvme*
echo "================================================================= /n"


mkfs -t ext4 "${dev}p1" || exit 1 

#Create ${mntpoint}/* directory and mount it to logical volumes created

sleep 5 # A

#Copy the data from the root volume to the Logical volume


#rsync -qaxHAX --exclude={"/home/ubuntu/.ssh/authorized_keys","/var/log/*", \
#                        "/var/cache/*","/lost+found","/tmp/*","/var/lib/update-notifier/*", \
#                        "/var/lib/amazon/ssm/i-*"} \ 
#                        / ${mntpoint}/  
echo 
lsblk
echo

dd if=${target_dev} of=${dev} 

#tar -cf ${mntpoint}/home/kitchen-sink.tar --acls --xattrs --exclude='./proc/*' --exclude='./sys/*' --exclude='./dev/*' \
#    --exclude='./var/run/acpid.scoket' --exclude='./var/rub/dbus/system_bus_socket' /
# cd ${mntpoint} && tar -xf ${mntpoint}/home/kitcken-sink.tar --acls --xattrs

#Remove the existing ${mntpoint}/etc/fstab file
mount ${dev}p1 ${mntpoint}/ || exit 1 
rm -f ${mntpoint}/etc/fstab

#To mount all mounting points after instance reboot, update ${mntpoint}/etc/fstab file.
echo "${target_dev}p1 / ext4 defaults 0 0" >> ${mntpoint}/etc/fstab