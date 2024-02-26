#!/usr/bin/env bash

set -e

BASE="$HOME/rclone/mount"

diskutil umount "$BASE"
rm -rf "$HOME"/rclone/cache/*

echo 'done.'
