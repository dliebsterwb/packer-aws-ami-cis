#! /bin/bash

# apt-get update
# apt-get install libpam-pwquality libpam-cracklib



# Add cracklib PAM config

# echo 'password        requisite                       pam_cracklib.so retry=3 minlen=16 difok=3 ucredit=-1 lcredit=-2 dcredit=-2 ocredit=-2' >> /etc/pam.d/common-password

echo 'password        requisite                       pam_pwquality.so retry=3 minlen=8 maxrepeat=3 ucredit=-1 lcredit=-1 dcredit=-1 ocredit=-1 difok=3 gecoscheck=1 reject_username enforce_for_root >> /etc/pam.d/common-password'

echo 'PermitRootLogin no' >> e/etc/ssh/sshd_config