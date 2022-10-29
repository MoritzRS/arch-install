#!/bin/bash
SCRIPT=$(realpath "$0")
DIR=$(dirname "$SCRIPT")

##############################################
########## Arch Base Install Script ##########
##############################################


##
# Loads keymaps, time and mirrors
##
prepare_setup() {
    loadkeys de-latin1;
    timedatectl set-ntp true;
    reflector \
        --latest 5 \
        --sort rate \
        --country Austria,France,Germany,Switzerland \
        --save /etc/pacman.d/mirrorlist;
    pacman -Syy git wget unzip --noconfirm --needed;
    clear;
}


##
# Select Hard Drive to install
##
select_drive() {
    clear;
    lsblk;
    read -p "Drive (eg. /dev/sda): " DRIVE;
    clear;
}

##
# Select Username and Password
##
select_user() {
    clear;
    read -p "Username: " USER;
    clear;
    read -p "Password: " PASS;
    clear;
}

##
# Select Desktop Environment
##
select_desktop() {
    clear;
    read -p "Desktop (i3,bspwm): " DESKTOP;
    clear;
}

##
# Confirm user settings
##
confirm_selection() {
    clear;
    echo "Drive: ${DRIVE}";
    echo "Username: ${USER}";
    echo "Password: ${PASS}";
    echo "Desktop: ${DESKTOP}";
    echo "";

    local CORRECTOPTIONS;
    read -p "Are these options correct? (y/n): " CORRECTOPTIONS
    if [ "${CORRECTOPTIONS}" != "y" ] && [ "${CORRECTOPTIONS}" != "Y" ]; then
        exit 1
    fi
    clear;
}

##
# Partition the selected disk
##
parition_disk() {
    # partition
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
}

##
# Create needed filesystems
##
create_filesystems() {
    mkfs.fat -F32 ${DRIVE}1
    mkswap ${DRIVE}2
    mkfs.ext4 ${DRIVE}3
}

##
# Mount created filesystems
##
mount_partitions() {
    swapon ${DRIVE}2
    mount ${DRIVE}3 /mnt
    mkdir /mnt/{boot,home}
    mkdir /mnt/boot/efi
    mount ${DRIVE}1 /mnt/boot/efi
}

##
# Install basic Archlinux system
##
install_base() {
    pacstrap /mnt base base-devel linux linux-firmware;
    genfstab -U /mnt >> /mnt/etc/fstab;
}

##
# Setup Time configuration
##
setup_time() {
    arch-chroot /mnt ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime;
    arch-chroot /mnt hwclock --systohc;
}

##
# Setup German Locale
##
setup_locale() {
    echo "LANG=de_DE.UTF-8" >> /mnt/etc/locale.conf;
    echo "LC_ADDRESS=de_DE.UTF-8" >> /mnt/etc/locale.conf;
    echo "LC_IDENTIFICATION=de_DE.UTF-8" >> /mnt/etc/locale.conf;
    echo "LC_MEASUREMENT=de_DE.UTF-8" >> /mnt/etc/locale.conf;
    echo "LC_MONETARY=de_DE.UTF-8" >> /mnt/etc/locale.conf;
    echo "LC_NAME=de_DE.UTF-8" >> /mnt/etc/locale.conf;
    echo "LC_NUMERIC=de_DE.UTF-8" >> /mnt/etc/locale.conf;
    echo "LC_PAPER=de_DE.UTF-8" >> /mnt/etc/locale.conf;
    echo "LC_TELEPHONE=de_DE.UTF-8" >> /mnt/etc/locale.conf;
    echo "LC_TIME=de_DE.UTF-8" >> /mnt/etc/locale.conf;

    echo "KEYMAP=de" >> /mnt/etc/vconsole.conf;
    echo "FONT=" >> /mnt/etc/vconsole.conf;
    echo "FONT_MAP=" >> /mnt/etc/vconsole.conf;

    echo "# Autoinstaller" >> /mnt/etc/locale.gen;
    echo "de_DE.UTF-8 UTF-8" >> /mnt/etc/locale.gen;
    echo "en_US.UTF-8 UTF-8" >> /mnt/etc/locale.gen;
    
    arch-chroot /mnt locale-gen;
}

##
# Setup Host Information
##
setup_host() {
    echo "archlinux" > /mnt/etc/hostname;

    echo "127.0.0.1    localhost" >> /mnt/etc/hosts;
    echo "::1          localhost" >> /mnt/etc/hosts;
    echo "127.0.1.1    archlinux.localdomain    archlinux" >> /mnt/etc/hosts;
}

##
# Install GRUB with Catppuccin Macchiato
##
install_bootloader() {
    arch-chroot /mnt pacman -S grub-efi-x86_64 efibootmgr dosfstools os-prober mtools --needed --noconfirm;
    arch-chroot /mnt grub-install --target=x86_64-efi --bootloader-id=grub_uefi --recheck;
    
    git clone https://github.com/catppuccin/grub.git /mnt/cp-grub;
    cp -r /mnt/cp-grub/src/catppuccin-macchiato-grub-theme /mnt/usr/share/grub/themes/catppuccin-macchiato-grub-theme;
    rm -rf /mnt/cp-grub;

    sed -i s+\#GRUB_THEME=\"/path/to/gfxtheme\"+GRUB_THEME=\"/usr/share/grub/themes/catppuccin-macchiato-grub-theme/theme.txt\"+ /mnt/etc/default/grub;
    
    arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg;
}

##
# Install network, bluetooth and power
##
install_services() {
    arch-chroot /mnt pacman -S networkmanager nm-connection-editor blueman dhcpcd bluez bluez-utils acpid --needed --noconfirm;
    arch-chroot /mnt systemctl enable NetworkManager;
    arch-chroot /mnt systemctl enable dhcpcd;
    arch-chroot /mnt systemctl enable bluetooth;
    arch-chroot /mnt systemctl enable acpid;
}

##
# Install and setup zsh with ohmyzsh and powerlevel10k
##
install_zsh() {
    arch-chroot /mnt pacman -S zsh starship --needed --noconfirm;

    # install autosuggestions
    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions /mnt/usr/local/zsh-plugins/zsh-autosuggestions;

    # install syntax highlighting
    git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git /mnt/usr/local/zsh-plugins/zsh-syntax-highlighting;
}

##
# Install selection of nerd fonts
##
install_nerd_fonts() {
    wget https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Hack.zip -P /mnt/;
    unzip /mnt/Hack.zip -d /mnt/usr/share/fonts/Hack\ Nerd\ Font;
    rm /mnt/Hack.zip;

    wget https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip -P /mnt/;
    unzip /mnt/JetBrainsMono.zip -d /mnt/usr/share/fonts/JetBrainsMono\ Nerd\ Font;
    rm /mnt/JetBrainsMono.zip;

    wget https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.zip -P /mnt/;
    unzip /mnt/Meslo.zip -d /mnt/usr/share/fonts/Meslo\ Nerd\ Font;
    rm /mnt/Meslo.zip;

    wget https://github.com/ryanoasis/nerd-fonts/releases/latest/download/SourceCodePro.zip -P /mnt/;
    unzip /mnt/SourceCodePro.zip -d /mnt/usr/share/fonts/SourceCodePro\ Nerd\ Font;
    rm /mnt/SourceCodePro.zip;
}

##
# Installs Themes based on Catppuccin
##
install_themes() {
    git clone https://github.com/catppuccin/gtk.git /mnt/cp-gtk
    unzip /mnt/cp-gtk/Releases/Catppuccin-Macchiato.zip -d /mnt/usr/share/themes
    rm -rf /mnt/cp-gtk

    git clone https://github.com/catppuccin/cursors.git /mnt/cp-cursors
    unzip /mnt/cp-cursors/cursors/Catppuccin-Macchiato-Light-Cursors.zip -d /mnt/usr/share/icons
    rm -rf /mnt/cp-cursors

    arch-chroot /mnt pacman -S papirus-icon-theme --needed --noconfirm;
}

##
# Install i3 Desktop
##
install_i3() {
    local PACKAGES="xorg xorg-drivers xorg-xbacklight";
    PACKAGES+=" lightdm lightdm-slick-greeter"
    PACKAGES+=" alsa-utils alsa-plugins pulseaudio pavucontrol"
    PACKAGES+=" i3-gaps i3lock numlockx";
    PACKAGES+=" noto-fonts";
    PACKAGES+=" rofi rxvt-unicode polybar dunst nitrogen gnome-backgrounds maim";
    PACKAGES+=" ristretto xdotool xdg-utils lxrandr-gtk3 lxappearance-gtk3 lxtask-gtk3 xfce4-power-manager";
    arch-chroot /mnt pacman -S ${PACKAGES} --needed --noconfirm;



    sed -i s/\#greeter-session=example-gtk-gnome/greeter-session=lightdm-slick-greeter/ /mnt/etc/lightdm/lightdm.conf
    arch-chroot /mnt systemctl enable lightdm;
}

##
# Install bspwm Desktop
##
install_bspwm() {
    local PACKAGES="xorg xorg-drivers xorg-xbacklight";
    PACKAGES+=" lightdm lightdm-slick-greeter"
    PACKAGES+=" alsa-utils alsa-plugins pulseaudio pavucontrol"
    PACKAGES+=" bspwm sxhkd i3lock numlockx";
    PACKAGES+=" noto-fonts";
    PACKAGES+=" rofi rxvt-unicode polybar dunst nitrogen gnome-backgrounds maim";
    PACKAGES+=" ristretto xdotool xdg-utils lxrandr-gtk3 lxappearance-gtk3 lxtask-gtk3 xfce4-power-manager";
    arch-chroot /mnt pacman -S ${PACKAGES} --needed --noconfirm;


    sed -i s/\#user-session=default/user-session=bspwm/ /mnt/etc/lightdm/lightdm.conf
    sed -i s/\#greeter-session=example-gtk-gnome/greeter-session=lightdm-slick-greeter/ /mnt/etc/lightdm/lightdm.conf
    arch-chroot /mnt systemctl enable lightdm;
}

##
# Installs NVM Globally with node v18
##
install_nvm() {
    local NVM_DIR="/mnt/usr/local/nvm";
    git clone https://github.com/nvm-sh/nvm.git ${NVM_DIR};
    cd ${NVM_DIR};
    git checkout `git describe --abbrev=0 --tags --match "v[0-9]*" $(git rev-list --tags --max-count=1)`;
    \. ${NVM_DIR}/nvm.sh;
    chmod 777 ${NVM_DIR};

    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

    nvm install 18; 
}


##
# Setup User Account with default shell
##
setup_users() {
    arch-chroot /mnt bash <<SHELL
pacman -S sudo --needed --noconfirm;
useradd -m -g users -G wheel,storage,power,audio,video -s /usr/bin/zsh ${USER};
echo -e "${PASS}\n${PASS}" | passwd;
echo -e "${PASS}\n${PASS}" | passwd ${USER};
echo "%wheel ALL=(ALL) ALL" > /etc/sudoers.d/10-installer;
SHELL
}

##
# installs configuration files
##
install_configs() {
    cp -r ${DIR}/files/. /mnt
    chmod +x /mnt/etc/skel/.config/bspwm/bspwmrc
}




############################
##### Install Schedule #####
############################

prepare_setup;
select_drive;
select_user;
select_desktop;
confirm_selection;

parition_disk;
create_filesystems;
mount_partitions;

install_base;
setup_time;
setup_locale;
setup_host;
install_services;
install_zsh;
install_bootloader;

if [ "${DESKTOP}" = "i3" ]; then
    install_i3;
fi

if [ "${DESKTOP}" = "bspwm" ]; then
    install_bspwm;
fi

install_nerd_fonts;
install_themes;
install_nvm;
install_configs;

setup_users;