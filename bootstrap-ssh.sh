#!/bin/bash

set -e

usage() {
    echo "Usage: $0 <image>"
    echo "Change pi's password and enable SSH before writing the image to SD card."
    echo 
    echo -e "  image\t\tdecompressed Raspberry OS image (.img)"
    echo
}
if [ -z "$1" ]; then (usage; exit 1); fi

image="$1"
loop_device=$(sudo losetup --show -f "$image")
sudo partx -a $loop_device
root=$(lsblk $loop_device -o NAME -lnp | head -n3 | tail -n1)
mount_dir=$(mktemp -d -t rpi-root-XXXXXX)
echo "Mounting Rasberry OS image in: $mount_dir"
sudo mount $root $mount_dir
echo "Setting new password for user pi"
pass=$(openssl passwd -1)
sudo sed -i -e "s@\(^pi:\)\([^:]*\)\(.*$\)@\1${pass}\3@" $mount_dir/etc/shadow
echo "Removing nopasswd access from user pi"
sudo rm -f $mount_dir/etc/sudoers.d/010_pi-nopasswd
echo "Enabling SSH"
sudo ln -sf $mount_dir/lib/systemd/system/ssh.service $mount_dir/etc/systemd/system/sshd.service
sudo ln -sf $mount_dir/lib/systemd/system/ssh.service $mount_dir/etc/systemd/system/multi-user.target.wants/ssh.service
for d in rc2.d rc3.d rc4.d rc5.d; do (cd $mount_dir/etc/$d; sudo ln -sf ../init.d/ssh S01ssh); done
find $mount_dir/etc/rc* -name 'K*ssh' -exec sudo rm {} +

# cleanup
sudo umount $root
sudo partx -d $loop_device
sudo losetup -d $loop_device
rmdir $mount_dir
echo "Done"
