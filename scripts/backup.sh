#!/usr/bin/env bash
# Packages the world save + server config into one tarball you can hand off
# to whoever is taking over hosting (send it any way you like - it's not
# meant to go through git).
set -euo pipefail
cd "$(dirname "$0")/.."

timestamp=$(date +%Y%m%d-%H%M%S)
outfile="valheim-world-backup-${timestamp}.tar.gz"

if [ ! -d config ]; then
  echo "No ./config directory found - has the server been started at least once?" >&2
  exit 1
fi

tar czf "$outfile" --exclude='config/backups' config

echo "Created ${outfile}"
echo "Send this file to the new host, then on that machine run:"
echo "  scripts/restore.sh ${outfile}"
