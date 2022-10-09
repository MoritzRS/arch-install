#!/bin/bash
SCRIPT=$(realpath "$0")
DIR=$(dirname "$SCRIPT")

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



########################
##### Time setup #####
########################
arch-chroot /mnt bash <<SHELL
# setup timezone
ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime

# enable hardware clock
hwclock --systohc
SHELL



#########################
##### Locales Setup #####
#########################
arch-chroot /mnt bash <<SHELL
# setup languages
echo "LANG=de_DE.UTF-8" >> /etc/locale.conf
echo "LC_ADDRESS=de_DE.UTF-8" >> /etc/locale.conf
echo "LC_IDENTIFICATION=de_DE.UTF-8" >> /etc/locale.conf
echo "LC_MEASUREMENT=de_DE.UTF-8" >> /etc/locale.conf
echo "LC_MONETARY=de_DE.UTF-8" >> /etc/locale.conf
echo "LC_NAME=de_DE.UTF-8" >> /etc/locale.conf
echo "LC_NUMERIC=de_DE.UTF-8" >> /etc/locale.conf
echo "LC_PAPER=de_DE.UTF-8" >> /etc/locale.conf
echo "LC_TELEPHONE=de_DE.UTF-8" >> /etc/locale.conf
echo "LC_TIME=de_DE.UTF-8" >> /etc/locale.conf

# setup vconsole
echo "KEYMAP=de" >> /etc/vconsole.conf
echo "FONT=" >> /etc/vconsole.conf
echo "FONT_MAP=" >> /etc/vconsole.conf

# configure locales
echo "# Autoinstaller" >> /etc/locale.gen
echo "de_DE.UTF-8 UTF-8" >> /etc/locale.gen
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen

# generate locales
locale-gen
SHELL



#######################
##### Hosts Setup #####
#######################
arch-chroot /mnt bash <<SHELL
# set hostname
echo archlinux > /etc/hostname

# set hosts
echo "127.0.0.1    localhost" >> /etc/hosts
echo "::1          localhost" >> /etc/hosts
echo "127.0.1.1    archlinux.localdomain    archlinux" >> /etc/hosts
SHELL



######################
##### Setup GRUB #####
######################
arch-chroot /mnt bash <<SHELL
# install tools
pacman -S grub-efi-x86_64 efibootmgr dosfstools os-prober mtools --needed --noconfirm

# install grub (might need to try --efi-directory=/boot/efi)
grub-install --target=x86_64-efi --bootloader-id=grub_uefi --recheck

# update configuration
sed -i s/GRUB_TIMEOUT=5/GRUB_TIMEOUT=3/ /etc/default/grub
sed -i s/GRUB_TIMEOUT_STYLE=menu/GRUB_TIMEOUT_STYLE=hidden/ /etc/default/grub

# make grub configuration
grub-mkconfig -o /boot/grub/grub.cfg
SHELL



############################
##### Install Services #####
############################
arch-chroot /mnt bash <<SHELL
# install network tools
pacman -S networkmanager network-manager-applet dhcpcd avahi --needed --noconfirm
systemctl enable NetworkManager
systemctl enable dhcpcd
systemctl enable avahi-daemon

# install bluetooth tools
pacman -S bluez bluez-utils --needed --noconfirm
systemctl enable bluetooth

# install internal tools
pacman -S dbus acpid --needed --noconfirm
systemctl enable acpid
SHELL



#######################
##### Install ZSH #####
#######################
arch-chroot /mnt bash <<SHELL
pacman -S zsh --needed --noconfirm
SHELL



###########################
##### Install Desktop #####
###########################
arch-chroot /mnt bash <<SHELL
# install xorg
pacman -S xorg xorg-drivers --needed --noconfirm

# install i3
pacman -S i3-gaps i3lock numlockx --needed --noconfirm

# install needed applications
pacman -S rofi rxvt-unicode polybar lxappearance xfce4-power-manager nitrogen --needed --noconfirm

# install login manager
pacman -S lightdm lightdm-slick-greeter --needed --noconfirm
systemctl enable lightdm
sed -i s/\#greeter-session=example-gtk-gnome/greeter-session=lightdm-slick-greeter/ /etc/lightdm/lightdm.conf


# install fonts
pacman -S noto-fonts ttf-ubuntu-font-family ttf-dejavu ttf-freefont ttf-liberation ttf-droid ttf-inconsolata ttf-roboto terminus-font ttf-font-awesome --needed --noconfirm

# sound support
pacman -S alsa-utils alsa-plugins alsa-lib pavucontrol --needed --noconfirm
SHELL



######################
##### Copy Files #####
######################
cp -r ${DIR}/files/. /mnt


###############################
##### Setup User Accounts #####
###############################
arch-chroot /mnt bash <<SHELL
## change root password
rootpass="password"
echo -e "${PASS}\n${PASS}" | passwd

## add normal user
useradd -m -g users -G wheel,storage,power,audio,video -s /usr/bin/zsh ${USER}
echo -e "${PASS}\n${PASS}" | passwd ${USER}

## install sudo
pacman -S sudo --needed --noconfirm

## add wheel group to sudoers
echo "%wheel ALL=(ALL) ALL" > /etc/sudoers.d/10-installer
SHELL