#!/usr/bin/env bash

set -e

BASE="$HOME/rclone/mount"

ARGS="--allow-other --attr-timeout 1m --vfs-cache-mode writes --vfs-cache-max-size 60G --vfs-read-chunk-size-limit 512M --buffer-size 128M --cache-dir=$HOME/rclone/cache --vfs-fast-fingerprint --no-checksum --no-modtime --daemon"

echo "$ARGS" | xargs rclone mount alist-dc:/ali/Movie "$BASE" --no-update-modtime

echo 'done.'
