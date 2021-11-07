#!/bin/bash

#This script has logic to create partitions volume groups and logical volumes which we will use to create root partition with LVM support

#:wq
# Enable vebose output to the Packer build console
set -x

#Set variables, dev for EBS volume attach, change this if you change in the packer template.
#Mountpoint, to create different mounts and directory in new volume, we will use mntpoint variable

readonly local dev="/dev/nvme1n1"
readonly local mntpoint="/mnt"

 [ ! -d "${mntpoint}" ] && \
 errx "cannot find mountpoint '${mntpoint}'"

#parted used to create partitions in {dev}
#Will be creating two partitions
#1 for boot {dev}1
#2 for creating volume group and logical volumes

parted -a optimal "${dev}" mklabel msdos print || \
exit 1
partprobe
parted -a optimal "${dev}" mkpart primary '0%' '1%' set 1 boot on print || \
exit 1
partprobe
parted -a optimal "${dev}" mkpart primary '1%' '100%' set 2 lvm on print || \
exit 1
partprobe

partprobe -s
lsblk
fdisk -l 
echo "================================================================="
ls -all /dev/nvme*

mkfs -t ext4 "${dev}p1" || \
exit 1

#Create volume group for {dev}2

pvcreate ${dev}p2
vgcreate vol_grp ${dev}p2

#Create logical volumes from volume group created

lvcreate -L 8G -n lv_root vol_grp
lvcreate -L 8G -n lv_var vol_grp
lvcreate -L 8G -n lv_varlog vol_grp
lvcreate -L 4G -n lv_varlogaudit vol_grp
lvcreate -L 4G -n lv_vartmp vol_grp
lvcreate -L 6G -n lv_tmp vol_grp
lvcreate -L 10G -n lv_home vol_grp

#Format the created logical volumes using xfs

mkfs -t ext4 ${dev}p1
mkfs -t ext4  /dev/mapper/vol_grp-lv_varlogaudit
mkfs -t ext4  /dev/mapper/vol_grp-lv_root
mkfs -t ext4  /dev/mapper/vol_grp-lv_vartmp
mkfs -t ext4  /dev/mapper/vol_grp-lv_var
mkfs -t ext4  /dev/mapper/vol_grp-lv_varlog
mkfs -t ext4  /dev/mapper/vol_grp-lv_tmp
mkfs -t ext4  /dev/mapper/vol_grp-lv_home



#Create ${mntpoint}/* directory and mount it to logical volumes created

mount /dev/mapper/vol_grp-lv_root ${mntpoint}/
mkdir -p ${mntpoint}/boot
mount ${dev}p1 ${mntpoint}/boot
mkdir -p ${mntpoint}/var ${mntpoint}/tmp  ${mntpoint}/home
mount  /dev/mapper/vol_grp-lv_var ${mntpoint}/var
mkdir -p ${mntpoint}/var/log/audit
mkdir -p ${mntpoint}/var/tmp
mount /dev/mapper/vol_grp-lv_varlog ${mntpoint}/var/log
mount /dev/mapper/vol_grp-lv_vartmp ${mntpoint}/var/tmp
mount /dev/mapper/vol_grp-lv_varlogaudit ${mntpoint}/var/log/audit
mount /dev/mapper/vol_grp-lv_home ${mntpoint}/home
mount /dev/mapper/vol_grp-lv_tmp ${mntpoint}/tmp


#Copy the data from the root volume to the Logical volume


rsync -qaxHAX --exclude={"/home/ubuntu/.ssh/authorized_keys","/var/log","/lost+found","/tmp/*","/var/lib/amazon/ssm/i-*"} / ${mntpoint}/  
rsync -qaxHAX /boot/ ${mntpoint}/boot/

fsck -y /dev/mapper/vol_grp-lv_root 
fsck -y /dev/mapper/vol_grp-lv_var 

#tar -cf ${mntpoint}/home/kitchen-sink.tar --acls --xattrs --exclude='./proc/*' --exclude='./sys/*' --exclude='./dev/*' \
#    --exclude='./var/run/acpid.scoket' --exclude='./var/rub/dbus/system_bus_socket' /
# cd ${mntpoint} && tar -xf ${mntpoint}/home/kitcken-sink.tar --acls --xattrs

#Remove the existing ${mntpoint}/etc/fstab file

rm -f ${mntpoint}/etc/fstab

#To mount all mounting points after instance reboot, update ${mntpoint}/etc/fstab file.
echo "/dev/mapper/vol_grp-lv_root / ext4 defaults 0 0" >> ${mntpoint}/etc/fstab
echo "/dev/mapper/vol_grp-lv_var /var ext4 rw,relatime   0 0" >> ${mntpoint}/etc/fstab
echo "/dev/mapper/vol_grp-lv_varlog /var/log ext4  rw,nodev,nosuid,noexec,relatime   0 0" >> ${mntpoint}/etc/fstab
echo "/dev/mapper/vol_grp-lv_tmp /tmp ext4 rw,nodev,nosuid,noexec,relatime 0 0" >> ${mntpoint}/etc/fstab
echo "/dev/mapper/vol_grp-lv_home /home ext4 rw,nodev,relatime 0 0" >> ${mntpoint}/etc/fstab
echo "/dev/mapper/vol_grp-lv_varlogaudit /var/log/audit ext4  rw,nodev,nosuid,noexec,relatime   0 0" >> ${mntpoint}/etc/fstab
echo "/dev/mapper/vol_grp-lv_vartmp /var/tmp ext4  rw,nodev,nosuid,noexec,relatime  0 0" >> ${mntpoint}/etc/fstab
echo "tmpfs /dev/shm tmpfs  rw,nosuid,nodev,noexec 0 0" >> ${mntpoint}/etc/fstab
