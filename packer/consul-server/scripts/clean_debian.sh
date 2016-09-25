#!/usr/bin/env bash

sed -i '/ packer /d' /home/*/.ssh/authorized_keys /root/.ssh/authorized_keys

echo "Remove backup files"
find /etc -name '*-' -delete
find /etc -name '*~' -delete

echo "Remove server ssh keys"
rm /etc/ssh/ssh_host*

echo "Remove local configurations by cloudinit"
rm /etc/default/locale
rm /etc/hostname
rm /etc/sudoers.d/90-cloud-init-users
rm /etc/apt/apt.conf.d/90cloud-init-pipelining
rm -rf /var/lib/cloud/instances/*
rm -rf /var/lib/cloud/data/*

echo "Clean up apt cache"
apt-get --purge -y autoremove
apt-get clean -y
rm -rf /var/lib/apt/lists/*

echo "Remove log files"
for CLEAN in $(find /var/log/ -type f)
do
    cp /dev/null  $CLEAN
done
