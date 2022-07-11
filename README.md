# rpi-tools

Repository with helper scripts for setting up my Raspberry Pi.

## bootstrap-ssh.sh

If you want to enable SSH without having to use a monitor and a keyboard, this script will automatically modify the Raspberry OS image for you.

Download the official image from the [Raspberry OS site](https://www.raspberrypi.com/software/operating-systems/) and unzip it with:

    xz -dk 2022-04-04-raspios-bullseye-armhf-lite.img.xz
Run the script:

    ./bootstrap-ssh.sh 2022-04-04-raspios-bullseye-armhf-lite.img
Burn the image onto your SD card:
    
    sudo dd if=2022-04-04-raspios-bullseye-armhf-lite.img of=/dev/mmcblk0 \
        bs=4M oflag=dsync status=progress

It will also:
- update **pi**'s password
- remove the default *nopasswd* sudo access from **pi**
- copy your local SSH key for easy access
- enable CLI autocomplete for **root**.

## ansible

This folder contains an Ansible inventory file with my pi defined, next to it are playbook folders.
Playbooks can be run using:

    ansible-playbook -i ./inventory -l rpi -K [playbook-folder]/playbook.yml

### rpi-bootstrap

1. Update APT cache
2. Upgrade software with dist-upgrade
3. Install basic requirements
4. Install basic software
5. Install Docker from official Docker repos
6. Copy *vimrc* settings
