#!/usr/bin/env bash

set -e

USERNAME=sunls
HOSTNAME=archlinux

echo -e '\033[32m==>\033[0m checking'

ls /sys/firmware/efi/efivars > /dev/null 2>&1 || (echo 'Not booting in UEFI mode.' && exit 1)

mount | grep /mnt > /dev/null 2>&1 || (echo '/mnt is not mounted.' && exit 1)
mount | grep /mnt/efi > /dev/null 2>&1 || (echo '/mnt/efi is not mounted.' && exit 1)

timedatectl set-ntp true
systemctl stop reflector.service

echo -e '\033[32m==>\033[0m install linux system'
# rygel 媒体共享，gnome-user-share 文件共享 gnome-remote-desktop 远程桌面 gnome-connections 连接
pacstrap /mnt base base-devel linux linux-firmware \
    vim wget curl docker git jq \
	intel-ucode grub efibootmgr \
	gdm nautilus gnome-text-editor gnome-keyring gnome-disk-utility gnome-control-center gnome-clocks gnome-characters gnome-calendar gnome-calculator xdg-user-dirs-gtk baobab loupe evince gnome-font-viewer gnome-system-monitor \
    gnome-tweaks ibus-rime networkmanager tilix \
	zsh zsh-autosuggestions zsh-syntax-highlighting zsh-theme-powerlevel10k \
	adobe-source-han-sans-cn-fonts papirus-icon-theme gnome-shell-extension-appindicator gnome-browser-connector

echo -e '\033[32m==>\033[0m fstab settings'
genfstab -U /mnt > /mnt/etc/fstab

echo -e '\033[32m==>\033[0m arch-chroot';
arch-chroot /mnt /bin/bash -c "

echo -e '\033[32m==>\033[0m pacman settings';
sed -i 's|#Color|Color|g' /etc/pacman.conf;
pacman -Syy

echo -e '\033[32m==>\033[0m timezone settings';
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime;
hwclock --systohc;

echo -e '\033[32m==>\033[0m language settings';
echo $HOSTNAME > /etc/hostname;
sed -i 's|#en_US.UTF-8|en_US.UTF-8|g' /etc/locale.gen;
sed -i 's|#zh_CN.UTF-8|zh_CN.UTF-8|g' /etc/locale.gen;
locale-gen;
echo 'LANG=en_US.UTF-8'  > /etc/locale.conf;

echo -e '\033[32m==>\033[0m hosts settings';
cat >/etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME
EOF

echo -e '\033[32m==>\033[0m GRUB settings';
grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=$HOSTNAME;
sed -i 's|GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3 quiet\"|GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3 nowatchdog\"|g' /etc/default/grub
sed -i 's|GRUB_TIMEOUT=5|GRUB_TIMEOUT=0|g' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg;

echo -e '\033[32m==>\033[0m passwd root';
passwd root;

echo -e '\033[32m==>\033[0m passwd $USERNAME'
useradd -m -G wheel -s /usr/bin/zsh $USERNAME
passwd $USERNAME
sed -i 's|# %wheel ALL=(ALL:ALL) NOPASSWD: ALL|%wheel ALL=(ALL:ALL) NOPASSWD: ALL|' /etc/sudoers

echo -e '\033[32m==>\033[0m $USERNAME settings'

sudo -i -u $USERNAME bash <<EOF
# yay
git clone https://aur.archlinux.org/yay-bin.git
cd yay-bin
makepkg -si --noconfirm
cd ~
rm -rf yay-bin
    
# zsh
wget https://raw.githubusercontent.com/sunls24/config/main/.zshrc

# vim
curl -s https://raw.githubusercontent.com/sunls24/config/main/one.vim | bash

# ssh
[ -e .ssh ] || (mkdir .ssh && chmod 700 .ssh)
[ -e .ssh/authorized_keys ] || (touch .ssh/authorized_keys && chmod 600 .ssh/authorized_keys)

# theme
mkdir -p theme && cd theme
git clone --depth 1 https://github.com/vinceliuice/Orchis-theme.git && cd Orchis-theme
./install.sh -t default -c light -s standard --round 5px --tweaks solid --tweaks compact && cd ..
git clone --depth 1 https://github.com/vinceliuice/Matcha-gtk-theme.git && cd Matcha-gtk-theme
./install.sh -t azul -c light
cd ~ && rm -rf theme

wget -qO- https://git.io/papirus-folders-install | sh
papirus-folders -C breeze
wget -qO- https://git.io/papirus-folders-install | env uninstall=true sh

yay -S --noconfirm sing-box-bin xcursor-breeze google-chrome
EOF

curl https://pan.sunls.de/d/x/sync/sing-box.json > /etc/sing-box/config.json

echo -e '\033[32m==>\033[0m edit sshd_config'
sed -i 's|#Port 22|Port 24|' /etc/ssh/sshd_config
sed -i 's|PermitRootLogin yes|#PermitRootLogin yes|' /etc/ssh/sshd_config
sed -i 's|UsePAM yes|UsePAM no|' /etc/ssh/sshd_config
sed -i 's|#ClientAliveInterval 0|ClientAliveInterval 60|' /etc/ssh/sshd_config
sed -i 's|#ClientAliveCountMax 3|ClientAliveCountMax 10|' /etc/ssh/sshd_config

echo -e '\033[32m==>\033[0m enable service'
systemctl enable gdm NetworkManager sing-box
"

# yay -S apple-fonts
