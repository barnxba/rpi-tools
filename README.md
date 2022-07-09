# rpi-tools

Repository for helper scripts pertaining to my Raspberry Pi.

## bootstrap-ssh.sh

If you want want to enable SSH without having to use a monitor and a keyboard, this script will automatically modify the Raspberry OS image for you.

Download the official image from the [Raspberry OS site](https://www.raspberrypi.com/software/operating-systems/) and unzip it with:

    xz -dk 2022-04-04-raspios-bullseye-armhf-lite.img.xz
Run the script:

    ./bootstrap-ssh.sh 2022-04-04-raspios-bullseye-armhf-lite.img
Burn the image onto your SD card:
    
    sudo dd if=2022-04-04-raspios-bullseye-armhf-lite.img of=/dev/mmcblk0 \
        bs=4M oflag=dsync status=progress 
It will also remove the default *nopasswd* sudo access from **pi**.
