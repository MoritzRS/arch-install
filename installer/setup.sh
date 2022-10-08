#!/bin/bash

####################
### Pre Setup ####
####################

# load keymap
loadkeys de-latin1

# time and date from network
timedatectl set-ntp true

# get latest mirrors
reflector --latest 5 --country Germany,France,Switzerland,Austria --sort rate --save /etc/pacman.d/mirrorlist

# update packages
pacman -Syyu --noconfirm