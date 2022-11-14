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
    read -p "SSD? (y/n): " SSD;
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
# Confirm user settings
##
confirm_selection() {
    clear;
    echo "Drive: ${DRIVE}";
    echo "SSD: ${SSD}";
    echo "Username: ${USER}";
    echo "Password: ${PASS}";
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
    if [ "${SSD}" != "y" ] && [ "${SSD}" != "Y"]; then
        mkfs.fat -F32 ${DRIVE}1
        mkswap ${DRIVE}2
        mkfs.ext4 ${DRIVE}3
    else
        mkfs.fat -F32 ${DRIVE}p1
        mkswap ${DRIVE}p2
        mkfs.ext4 ${DRIVE}p3
    fi
}

##
# Mount created filesystems
##
mount_partitions() {
    if [ "${SSD}" != "y" ] && [ "${SSD}" != "Y"]; then
        swapon ${DRIVE}2
        mount ${DRIVE}3 /mnt
        mkdir /mnt/{boot,home}
        mkdir /mnt/boot/efi
        mount ${DRIVE}1 /mnt/boot/efi
    else
        swapon ${DRIVE}p2
        mount ${DRIVE}p3 /mnt
        mkdir /mnt/{boot,home}
        mkdir /mnt/boot/efi
        mount ${DRIVE}p1 /mnt/boot/efi
    fi  
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
    
    git clone --depth=1 https://github.com/catppuccin/grub.git /mnt/cp-grub;
    cp -r /mnt/cp-grub/src/catppuccin-macchiato-grub-theme /mnt/usr/share/grub/themes/catppuccin-macchiato-grub-theme;
    rm -rf /mnt/cp-grub;

    sed -i s+\#GRUB_THEME=\"/path/to/gfxtheme\"+GRUB_THEME=\"/usr/share/grub/themes/catppuccin-macchiato-grub-theme/theme.txt\"+ /mnt/etc/default/grub;
    
    arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg;
}

##
# Install network, bluetooth and power
##
install_services() {
    local PACKAGES="networkmanager nm-connection-editor blueman dhcpcd bluez bluez-utils acpid";
    PACKAGES+=" pipewire pipewire-alsa pipewire-jack pipewire-pulse pavucontrol pamixer";
    arch-chroot /mnt pacman -S ${PACKAGES} --needed --noconfirm;
    arch-chroot /mnt systemctl enable NetworkManager;
    arch-chroot /mnt systemctl enable dhcpcd;
    arch-chroot /mnt systemctl enable bluetooth;
    arch-chroot /mnt systemctl enable acpid;
    arch-chroot /mnt systemctl enable fstrim.timer;
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
    arch-chroot /mnt pacman -S ttf-hack-nerd ttf-sourcecodepro-nerd ttf-terminus-nerd --needed --noconfirm;
}

##
# Installs Themes based on Catppuccin
##
install_themes() {
    git clone --depth=1 https://github.com/catppuccin/gtk.git /mnt/cp-gtk
    unzip /mnt/cp-gtk/Releases/Catppuccin-Macchiato.zip -d /mnt/usr/share/themes
    rm -rf /mnt/cp-gtk

    git clone --depth=1 https://github.com/catppuccin/cursors.git /mnt/cp-cursors
    unzip /mnt/cp-cursors/cursors/Catppuccin-Macchiato-Light-Cursors.zip -d /mnt/usr/share/icons
    rm -rf /mnt/cp-cursors

    arch-chroot /mnt pacman -S papirus-icon-theme --needed --noconfirm;
}

##
# Install bspwm Desktop
##
install_desktop() {
    local PACKAGES="xorg xorg-drivers light xf86-input-synaptics";
    PACKAGES+=" lightdm lightdm-slick-greeter"
    PACKAGES+=" bspwm picom sxhkd i3lock numlockx dex";
    PACKAGES+=" noto-fonts";
    PACKAGES+=" rofi alacritty polybar dunst nitrogen xcolor maim pcmanfm-gtk3 xarchiver unzip";
    PACKAGES+=" ristretto xdotool xdg-utils lxrandr-gtk3 lxappearance-gtk3 lxtask-gtk3 lxinput-gtk3 xfce4-power-manager";
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
# Install common packages and applications
##
install_common() {
    # Applications
    arch-chroot /mnt pacman -S git lazygit php php-sqlite code gnome-keyring neovim godot flatpak xdg-desktop-portal-gtk obsidian firefox epiphany chromium totem --needed --noconfirm;

    # setup php sqlite
    sed -i s/\;extension=pdo_sqlite/extension=pdo_sqlite/ /mnt/etc/php/php.ini 
    sed -i s/\;extension=sqlite3/extension=sqlite3/ /mnt/etc/php/php.ini 

    # add flatpak repository
    arch-chroot /mnt flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo;
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

    # make bspwmrc executable
    chmod +x /mnt/etc/skel/.config/bspwm/bspwmrc

    # autodetect backlight for polybar
    sed -i s/amdgpu_bl0/$(ls /sys/class/backlight/)/ /mnt/etc/skel/.config/polybar/modules/backlight.ini

    # create folder structure
    mkdir /mnt/etc/skel/{Bilder,Dev,Dokumente,Downloads,Musik,Videos}
    mkdir /mnt/etc/skel/Bilder/Screenshots

    # download neovim config
    git clone --depth=1 https://github.com/MoritzRS/neovim-config.git /mnt/etc/skel/.config/nvim
}




############################
##### Install Schedule #####
############################

prepare_setup;
select_drive;
select_user;
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

install_desktop;

install_nerd_fonts;
install_themes;
install_nvm;
install_common;
install_configs;

setup_users;
