#!/bin/sh
set -eu
P="${APP_PATH_PREFIX:-/var/jb}"
rm -f "$P/usr/local/bin/app-path" "$P/usr/local/libexec/app-path-bplist.awk"
echo "Removed app-path"
