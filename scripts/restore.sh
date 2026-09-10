#!/usr/bin/env bash
# Unpacks a tarball produced by backup.sh into ./config on a new host.
set -euo pipefail
cd "$(dirname "$0")/.."

if [ $# -ne 1 ]; then
  echo "Usage: $0 <valheim-world-backup-....tar.gz>" >&2
  exit 1
fi

if [ ! -f "$1" ]; then
  echo "File not found: $1" >&2
  exit 1
fi

mkdir -p config
tar xzf "$1" -C .

echo "Restored world data into ./config"
echo "Make sure .env on this host has the SAME WORLD_NAME as the original host,"
echo "then run: docker compose up -d"
