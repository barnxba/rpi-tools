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

function mount_image {
    loop_device=$(sudo losetup --show -f "$image")
    sudo partx -a $loop_device
    root=$(lsblk $loop_device -o NAME -lnp | head -n3 | tail -n1)
    mount_dir=$(mktemp -d -t rpi-root-XXXXXX)
    echo "Mounting Raspberry OS image in: $mount_dir"
    sudo mount $root $mount_dir
}

function update_passwd {
    echo "Setting new password for user pi"
    pass=$(openssl passwd -1)
    sudo sed -i -e "s@^pi:[^:]\+@pi:${pass}@" $mount_dir/etc/shadow
}

function remove_nopasswd_sudo {
    echo "Removing nopasswd access from user pi"
    sudo rm -f $mount_dir/etc/sudoers.d/010_pi-nopasswd
}

function enable_ssh {
    echo "Enabling SSH"
    sudo ln -sf $mount_dir/lib/systemd/system/ssh.service $mount_dir/etc/systemd/system/sshd.service
    sudo ln -sf $mount_dir/lib/systemd/system/ssh.service $mount_dir/etc/systemd/system/multi-user.target.wants/ssh.service
    for d in rc2.d rc3.d rc4.d rc5.d; do (cd $mount_dir/etc/$d; sudo ln -sf ../init.d/ssh S01ssh); done
    find $mount_dir/etc/rc* -name 'K*ssh' -exec sudo rm {} +
}

function disable_root_ssh {
    echo "Disabling root login via SSH"
    sudo sed -e 's@^[# ]*PermitRootLogin.*$@PermitRootLogin no@g' -i $mount_dir/etc/ssh/sshd_config
}

function copy_ssh_key {
    keyfile=~/.ssh/id_rsa.pub
    if [ ! -f $keyfile ]; then
        echo "Skipping SSH key copy -> no id_rsa.pub found in ~/.ssh"
        return
    fi
    echo "Copying public key from $(whoami)"
    ssh_dir=$mount_dir/home/pi/.ssh
    auth_file=$ssh_dir/authorized_keys
    if [ ! -d $ssh_dir ]; then
        sudo mkdir $ssh_dir
        sudo chmod 0700 $ssh_dir
        sudo chown 1000:1000 $ssh_dir
    fi
    sudo cat $keyfile >> $auth_file
    sudo chmod 0600 $auth_file
    sudo chown 1000:1000 $auth_file
}

function cleanup {
    sudo umount $root
    sudo partx -d $loop_device
    sudo losetup -d $loop_device
    rmdir $mount_dir
    echo "Done"
}

function burn_info {
    echo
    echo "To burn the image to sdcard (e.g. /dev/mmcblk0) use:"
    echo
    echo "dd if=$image of=/dev/mmcblk0 bs=4M oflag=dsync progress=status"
    echo
    echo "Bye!"
}

function wait_for_keypress {
    read -n1 -p "Press any key to continue..."
}

image="$1"
mount_image
update_passwd
remove_nopasswd_sudo
enable_ssh
disable_root_ssh
copy_ssh_key
cleanup
burn_info
