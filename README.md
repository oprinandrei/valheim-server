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

## Admin dev commands (Server Devcommands mod)

Vanilla dedicated servers block Valheim's dev/cheat console commands
entirely, even for players in `adminlist.txt` - `removekey`, `god`, `spawn`,
etc. all fail with an admin/permission error no matter what. The
[Server Devcommands](https://thunderstore.io/c/valheim/p/JereKuusela/Server_devcommands/)
mod (by JereKuusela) re-enables them for adminlist'd players. It's
**server-side only** - installed here via BepInEx, nobody connecting needs
to install anything on their end.

Not installed by default (`BEPINEX=false` in `.env`). To enable it:

1. Set `BEPINEX=true` in `.env`.
2. Download the mod's plugin DLL from Thunderstore and place it in
   `config/bepinex/plugins/`.
3. `docker compose down && docker compose up -d`.

To use it once installed:

1. Make sure your SteamID64 is in `ADMINLIST_IDS` (see `.env`).
2. In Valheim's Steam launch options, add `-console` (one-time, lets F5
   open the console at all).
3. Connect to the server, press **F5**, type `devcommands` and hit enter.
   This toggles cheat mode **for your session only** - it resets every time
   you reconnect, and only adminlist'd players can turn it on.
4. Run whichever commands you need (see table below).

| Command | Effect |
| --- | --- |
| `god` | Toggle invincibility |
| `ghost` | Enemies ignore you |
| `fly` | Toggle flight (Space up / Ctrl down) |
| `heal` | Full health/stamina/eitr |
| `spawn [entity] [amount] [level]` | Spawn an item/creature |
| `itemset [name]` | Spawn a premade gear set (Meadows, BlackForest, Mountains, ...) |
| `tame` | Tame all nearby tameable creatures |
| `killall` / `killenemies` / `killtame` | Remove nearby enemies/tames |
| `removedrops` | Clear nearby item drops on the ground |
| `raiseskill [skill] [amount]` | Set/boost a skill level |
| `exploremap` / `resetmap` | Reveal / hide the whole map |
| `goto [x] [z]` | Teleport to coordinates |
| `tod [0-1]` | Set time of day (0.5 = noon) |
| `skiptime [seconds]` | Fast-forward time |
| `listkeys` / `setkey [name]` / `removekey [name]` / `resetkeys` | List/add/remove/clear global world keys (e.g. `removekey nobuildcost`) |
| `nocost` | Toggle no-cost building for your session |
| `clearcheats` | Clears your character's cheat-tracking status (mod command, added in Server Devcommands v1.111) |
| `yesiuseddevcommandsbutiwantmyachievementsanyway` | Opts back into Steam achievements even though devcommands/mods were used - added in game version 1.0.12, so the server needs to be updated to at least that version first (see below) |

`yesiuseddevcommandsbutiwantmyachievementsanyway` is a vanilla Valheim
devcommand (not part of the mod above), from the 1.0.12 hotfix. Iron Gate's
own note on it: *"We will leave it to your own judgement whether or not to
activate this function - Oden will surely know if you use it dishonourably."*

Note: mod versions are tied to the game version. The Server Devcommands mod
that worked on game version 1.0.7 threw a `MissingFieldException` and
failed to load at all after the server updated to 1.0.12 - the mod needed
its own matching update (v1.112, "Fixed for the new update") before it
would load again. If dev commands stop working after a game update, check
for a newer mod release first.

Full reference: <https://valheim.weirdgloop.org/w/Console_Commands>

## Notes

- `SERVER_PUBLIC=false` keeps the server off the public browser list
  (LAN/invite-only). Set it to `true` if you want it discoverable.
- Port `2456-2457/udp` needs to be reachable by whoever's connecting. For
  LAN play that's automatic; for internet play you'd forward that port on
  whichever router is in front of the host, and the firewall would need to
  allow it too.
