# Valheim server

A portable, docker-compose-based Valheim dedicated server. The repo holds
only the *setup* (compose file, config template, migration scripts) - the
world save and game binaries live outside git in `config/` and `data/`, so
the repo stays small and safe to push anywhere (including a friend's fork).

## Layout

- `docker-compose.yml` - the service definition. No secrets in it; it reads
  everything from `.env`.
- `.env.example` - template for server name / world name / password /
  timezone. Copy to `.env` and edit; `.env` itself is gitignored.
- `config/` (gitignored) - world saves, backups, admin/ban lists. Created on
  first run.
- `data/` (gitignored) - the Valheim dedicated server binaries, downloaded
  automatically by the container. Never needs to be backed up or moved.
- `scripts/backup.sh` / `scripts/restore.sh` - package and unpack the world
  save for moving to a new machine.

## Requirements

Docker Engine with the Compose plugin (`docker compose version` should work)
on whatever machine is hosting - WSL, native Linux, or a friend's box.

## First-time setup

```bash
git clone <this-repo-url>
cd valheim-server
cp .env.example .env
# edit .env: set SERVER_NAME, WORLD_NAME, SERVER_PASS to what you want
docker compose up -d
docker compose logs -f valheim   # first boot downloads ~2GB, watch it here
```

Connect from Valheim using "join by IP/password", pointed at this machine's
IP, port 2456.

## Day to day

```bash
docker compose logs -f valheim   # watch server output
docker compose down              # stop the server (saves before shutting down)
docker compose up -d             # start it again
docker compose pull && docker compose up -d   # update the server image itself
```

## Moving to another host (e.g. a friend takes over hosting)

1. On the current host, stop the server and take a fresh backup:
   ```bash
   docker compose down
   scripts/backup.sh
   ```
   This produces `valheim-world-backup-<timestamp>.tar.gz`.

2. Send the new host two things: this git repo (they `git clone` it) and
   that tarball (any way you like - it's not part of git history).

3. On the new host:
   ```bash
   git clone <this-repo-url>
   cd valheim-server
   cp .env.example .env
   # IMPORTANT: WORLD_NAME must match exactly what it was on the old host,
   # or the server generates a brand new empty world instead of loading
   # your progress. SERVER_NAME and SERVER_PASS can be anything.
   scripts/restore.sh /path/to/valheim-world-backup-<timestamp>.tar.gz
   docker compose up -d
   ```

That's it - same repo, same world, new machine.

## Notes

- `SERVER_PUBLIC=false` keeps the server off the public browser list
  (LAN/invite-only). Set it to `true` if you want it discoverable.
- Port `2456-2457/udp` needs to be reachable by whoever's connecting. For
  LAN play that's automatic; for internet play you'd forward that port on
  whichever router is in front of the host, and the firewall would need to
  allow it too.
