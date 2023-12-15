#!/usr/bin/env bash

set -e

yay -S --noconfirm --needed rclone fuse2
sudo sed -i 's|#user_allow_other|user_allow_other|' /etc/fuse.conf

# ---
rclone mount alist:/123 rclone/mount/123 --allow-other --attr-timeout 1m --vfs-cache-mode writes --vfs-cache-max-size 10G --vfs-read-chunk-size-limit 256M --buffer-size 128M --cache-dir="$HOME"/rclone/cache --vfs-fast-fingerprint --no-checksum --no-modtime --no-seek --daemon

# no cache
rclone mount alist:/123 rclone/mount/123 --allow-other --attr-timeout 1m --vfs-cache-mode off --buffer-size 128M --no-checksum --no-modtime --no-seek --daemon

# macOS
rclone mount cc:/video rclone/mount/ --allow-other --transfers 24 --attr-timeout 1m --vfs-cache-mode writes --vfs-cache-max-size 100G --vfs-read-chunk-size-limit 512M --buffer-size 128M --cache-dir="$HOME"/rclone/cache --vfs-fast-fingerprint --no-checksum --no-modtime --no-seek --daemon

./aliyundrive-fuse --allow-other -r 6dda5f2861a44522a433e6a50ca6ef2a rclone/mount/ali

# fstab
REMOTE="alist:/ali/video"
MOUNT="$HOME/rclone/mount/ali"
cat <<EOF | sudo tee -a /etc/fstab
$REMOTE $MOUNT rclone attr_timeout=1m,vfs_cache_max_size=10G,vfs_read_chunk_size_limit=256M,buffer_size=128M,uid=$UID,gid=$GID,allow_other,rw,noauto,nofail,noexec,_netdev,args2env,vfs_cache_mode=writes,vfs_fast_fingerprint,no_checksum,no_modtime,no_seek,config=$HOME/.config/rclone/rclone.conf,cache_dir=$HOME/rclone/cache 0 0
EOF
