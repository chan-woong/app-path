#!/bin/sh
set -eu
P="${APP_PATH_PREFIX:-/var/jb}"
D=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
mkdir -p "$P/usr/local/bin" "$P/usr/local/libexec"
cp "$D/bin/app-path" "$P/usr/local/bin/app-path"
cp "$D/libexec/app-path-bplist.awk" "$P/usr/local/libexec/app-path-bplist.awk"
chmod 755 "$P/usr/local/bin/app-path"
chmod 644 "$P/usr/local/libexec/app-path-bplist.awk"
echo "Installed app-path to $P/usr/local"
