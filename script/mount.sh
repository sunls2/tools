#!/usr/bin/env bash

set -e

rclone mount local:/ali "$HOME"/rclone/mount \
--allow-other --attr-timeout 1m --buffer-size 128M --vfs-read-chunk-size-limit 512M \
--vfs-cache-mode full --vfs-cache-max-age 2w --vfs-cache-max-size 30G --cache-dir="$HOME"/rclone/cache \
--vfs-fast-fingerprint --no-checksum --no-modtime --no-seek --daemon

echo 'done.'
