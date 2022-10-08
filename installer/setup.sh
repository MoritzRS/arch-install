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

clean
#########################
##### User Settings #####
#########################

# show devices
lsblk

# select device
read -p "Drive (eg. /dev/sda) :" DRIVE
clean

# select username
read -p "Username: " USER
clean

# select password
read -p "Password: " PASS
clean

# confirm options
echo "Drive: ${DRIVE}"
echo "Username: ${USER}"
echo "Password: ${PASS}"
echo ""
echo -p "Are these options correct? (y/n): " CORRECTOPTIONS
if ["${CORRECTOPTIONS}" != "y" && "${CORRECTOPTIONS}" != "Y"]; then
    exit 1
fi
clean
echo "Starting Install Process..."