#!/bin/bash

######################
##### Pre Setup ######
######################

# load keymap
loadkeys de-latin1

# time and date from network
timedatectl set-ntp true

# get latest mirrors
reflector --latest 5 --country Germany,France,Switzerland,Austria --sort rate --save /etc/pacman.d/mirrorlist

# update packages
pacman -Syyu --noconfirm

clear
#########################
##### User Settings #####
#########################

# show devices
lsblk

# select device
read -p "Drive (eg. /dev/sda) :" DRIVE
clear

# select username
read -p "Username: " USER
clear

# select password
read -p "Password: " PASS
clear

# confirm options
echo "Drive: ${DRIVE}"
echo "Username: ${USER}"
echo "Password: ${PASS}"
echo ""
read -p "Are these options correct? (y/n): " CORRECTOPTIONS
if [ "${CORRECTOPTIONS}" != "y" ] && [ "${CORRECTOPTIONS}" != "Y" ]; then
    exit 1
fi
clear
echo "Starting Install Process..."



#######################
##### Drive Setup #####
#######################

## partition selected device
gdisk ${DRIVE} <<EOL
o
y
n
1

+500M
ef00
n
2

+16G
8200
n
3


8304
w
y
EOL

## create file systems
mkfs.fat -F32 ${DRIVE}1
mkswap ${DRIVE}2
mkfs.ext4 ${DRIVE}3

## mount partitions
swapon ${DRIVE}2
mount ${DRIVE}3 /mnt
mkdir /mnt/{boot,home}
mkdir /mnt/boot/efi
mount ${DRIVE}1 /mnt/boot/efi


#############################
##### Base Installation #####
#############################

# install system
pacstrap /mnt base base-devel linux linux-firmware

# generate fstab
genfstab -U /mnt >> /mnt/etc/fstab