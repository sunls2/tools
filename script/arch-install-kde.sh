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
cat >/etc/pacman.d/mirrorlist <<EOF
Server = https://mirrors.ustc.edu.cn/archlinux/\$repo/os/\$arch
EOF

echo -e '\033[32m==>\033[0m install linux system'
pacstrap /mnt base base-devel linux linux-firmware \
    vim wget curl docker git \
	intel-ucode grub efibootmgr networkmanager \
    plasma-desktop kwallet-pam plasma-nm plasma-pa sddm-kcm \
    konsole dolphin ark okular gwenview kate kcalc kscreen kde-gtk-config kinfocenter plasma-systemmonitor plasma-thunderbolt \
    # materia-kde kvantum-theme-materia materia-gtk-theme qt6ct
	zsh zsh-autosuggestions zsh-syntax-highlighting zsh-theme-powerlevel10k \
	adobe-source-han-sans-cn-fonts papirus-icon-theme

cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist

echo -e '\033[32m==>\033[0m fstab settings'
genfstab -U /mnt > /mnt/etc/fstab

echo -e '\033[32m==>\033[0m arch-chroot';
arch-chroot /mnt /bin/bash -c "

echo -e '\033[32m==>\033[0m pacman settings';
sed -i 's|#Color|Color|g' /etc/pacman.conf;
cat >>/etc/pacman.conf <<EOF

[archlinuxcn]
Server = https://mirrors.ustc.edu.cn/archlinuxcn/\\\$arch
EOF

pacman -Syyu
pacman -S --noconfirm archlinuxcn-keyring

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
if command -v yay >/dev/null 2>&1; then
    true
else
    git clone https://aur.archlinux.org/yay-bin.git
    cd yay-bin
    makepkg -si --noconfirm
    cd ~
    yay --noconfirm
    rm -rf yay-bin
fi

# zsh
if [ ! -e .zshrc ]; then
    wget https://raw.githubusercontent.com/sunls24/config/main/.zshrc
fi

# vim
[ -e .vimrc ] || curl -s https://raw.githubusercontent.com/sunls24/config/main/one.vim | bash

# ssh
[ -e .ssh ] || (mkdir .ssh && chmod 700 .ssh)
[ -e .ssh/authorized_keys ] || (touch .ssh/authorized_keys && chmod 600 .ssh/authorized_keys)
EOF

echo -e '\033[32m==>\033[0m edit sshd_config'
sed -i 's|#Port 22|Port 23|' /etc/ssh/sshd_config
sed -i 's|PermitRootLogin yes|#PermitRootLogin yes|' /etc/ssh/sshd_config
sed -i 's|UsePAM yes|UsePAM no|' /etc/ssh/sshd_config
sed -i 's|#ClientAliveInterval 0|ClientAliveInterval 60|' /etc/ssh/sshd_config
sed -i 's|#ClientAliveCountMax 3|ClientAliveCountMax 10|' /etc/ssh/sshd_config

echo -e '\033[32m==>\033[0m enable service'
systemctl enable sddm NetworkManager bluetooth
"