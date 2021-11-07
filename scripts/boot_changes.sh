#!/bin/bash
set -x
readonly local dev="/dev/nvme1n1"

sed -i 's/GRUB_CMDLINE_LINUX\=\"\"/GRUB_CMDLINE_LINUX\=\"console\=ttyS0,115200n8 console\=tty0 audit\=1 ipv6.disable\=1 net.ifnames\=0 crashkernel\=auto rd.lvm.lv\=vol_grp\/lvroot root\=\/dev\/mapper\/vol_grp-lv_root\"/' /etc/default/grub
sed -i '/GRUB_PRELOAD_MODULES\=lvm/a GRUB_PRELOAD_MODULES\=lvm' /etc/default/grub

grub-install --modules 'part_gpt part_msdos lvm' ${dev}
grub-install --recheck --modules 'part_gpt part_msdos lvm' ${dev}

update-initramfs -c -k `uname -r`
update-grub2 -o /boot/grub/grub.cfg

exit 0
