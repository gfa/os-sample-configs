#!/bin/sh
set -e
set -x

# replace for your directory where you keep your chroots
cd /storage/vm/lxc

DISTRIB=${1:-ubuntu}
RELEASE=${2:-trusty}
openstack_release=${3:-juno}

mountpoint -q config-gen/proc && sudo umount config-gen/proc

mountpoint -q config-gen/dev/pts && sudo umount config-gen/dev/pts
mountpoint -q config-gen/dev &&  sudo umount config-gen/dev

sudo rm -rf config-gen

sudo cp -r config-gen.${RELEASE}.base config-gen

sudo cp -f $OLDPWD/gplhost.gpg config-gen/etc/apt/trusted.gpg.d/
sudo cp -f $OLDPWD/cloud-archive.gpg config-gen/etc/apt/trusted.gpg.d/

sudo cp -f $OLDPWD/config-gen.sh config-gen/config-gen.sh
sudo chmod 755 config-gen/config-gen.sh
sudo sed -i "s/DISTRIB=.*/DISTRIB=$DISTRIB/" config-gen/config-gen.sh
sudo sed -i "s/RELEASE=.*/RELEASE=$RELEASE/" config-gen/config-gen.sh
sudo sed -i "s/openstack_release=.*/openstack_release=$openstack_release/" config-gen/config-gen.sh
sudo mount -t proc none config-gen/proc
sudo mount -o bind /dev/ config-gen/dev
sudo mount -t devpts none config-gen/dev/pts
echo exit 101 | sudo tee config-gen/usr/sbin/policy-rc.d
sudo chmod 755 config-gen/usr/sbin/policy-rc.d
sudo mkdir -p config-gen/tmp/user/0 # thank you systemD
sudo chroot config-gen /config-gen.sh
cp -r config-gen/storage/tmp/* $OLDPWD/results/
sudo umount config-gen/proc
sudo umount config-gen/dev/pts
sudo umount config-gen/dev

