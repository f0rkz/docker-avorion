# Docker Avorion

An Avorion dedicated-server image built on
[`ghcr.io/f0rkz/docker-steamcmd:2`](https://github.com/f0rkz/docker-steamcmd).
The container updates Steam App ID 565060 at startup, then runs the server as the
non-root `steam` user.

## Quick start

The included Compose file uses a named volume so Docker initializes `/data` with
the correct ownership:

```console
SERVER_ADMIN=76561198000000000 GALAXY_NAME=my-galaxy docker compose up --detach
docker compose logs --follow avorion
```

`SERVER_ADMIN` is the SteamID64 of the initial administrator. `GALAXY_NAME` is
optional; when omitted, Avorion's launcher default of `avorion_galaxy` is used.

## Configuration

| Variable | Default | Description |
| --- | --- | --- |
| `SERVER_ADMIN` | `0` | Initial administrator SteamID64; omitted from the server command when zero. |
| `GALAXY_NAME` | `avorion_galaxy` | Galaxy name; the table value is used when the environment variable is empty. |
| `STEAMCMD_VALIDATE` | `false` | Run SteamCMD validation during the startup update. |
| `STEAMCMD_RETRIES` | `3` | SteamCMD attempts before startup fails. |
| `AVORION_INSTALL_DIR` | `/data/avorion` | Dedicated-server installation directory. |
| `AVORION_DATA_PATH` | `/data/save` | Galaxy, configuration, and save-data directory. |
| `AVORION_USER_DIR` | `/data/home` | Persistent Avorion user data, including server backups. |
| `WORKSHOP_MODS` | empty | Comma- or space-separated Workshop IDs enabled server-side. |
| `ALLOWED_CLIENT_MODS` | empty | Comma- or space-separated Workshop IDs permitted client-side. |
| `FORCE_ENABLE_MODS` | `false` | Set Avorion's `forceEnabling` mod option. |

Additional arguments passed to the container are appended to Avorion's server
command. For example:

```console
docker run --rm ghcr.io/f0rkz/docker-avorion:1 --max-players 12
```

## Persistent data

The image intentionally does not declare a Docker volume. The supplied Compose
file mounts the `avorion-data` named volume at `/data`, preserving both the game
installation and galaxy data across container replacements.

For a bind mount, copy `docker-compose.yml.example` to a local Compose file and
make the directory writable by UID/GID 1000 before starting:

```console
mkdir --parents data
sudo chown 1000:1000 data
```

Avorion creates `server.ini` beneath
`/data/save/<galaxy-name>/server.ini`. Stop the server before editing it, or copy
the included `server.ini` as a starting point after the galaxy directory exists.

## Steam Workshop mods

Provide Workshop item IDs through `WORKSHOP_MODS`; setting `GALAXY_NAME` chooses
which galaxy receives the generated configuration:

```console
GALAXY_NAME=my-galaxy \
WORKSHOP_MODS="1691539727,1691591293" \
docker compose up --detach
```

The entrypoint writes the galaxy's `modconfig.lua`; Avorion then downloads and
updates those items under `/data/save/my-galaxy/workshop`. Connecting players are
told which Workshop items they need. `ALLOWED_CLIENT_MODS` adds client-side-only
items to the `allowed` table.

Environment-managed files start with a `Managed by docker-avorion` comment and
may be regenerated on later starts. The entrypoint refuses to overwrite a
hand-authored file. For local mods, custom paths, or mixed configurations, leave
the mod environment variables empty and copy `modconfig.lua.example` to
`/data/save/<galaxy-name>/modconfig.lua` instead.

Workshop mods execute third-party code. Review compatibility, dependencies, and
publisher trust before enabling an item, and back up a galaxy before changing its
mod set.

## Ports

The Compose configuration publishes TCP and UDP ports 27000, 27003, 27020, and
27021. Adjust the host-side mappings if multiple servers share a host.

## Updates and shutdown

Every container start runs `app_update 565060` before launching Avorion. Set
`STEAMCMD_VALIDATE=true` only when a full file validation is needed. The server
process replaces the entrypoint process, and Docker sends `SIGINT` with a
two-minute Compose grace period so Avorion can save before shutdown.

## Tags and releases

Merges to `master` are processed by semantic-release after container validation.
A release publishes full, minor, major, and `latest` image tags. For example,
`v1.2.3` publishes `1.2.3`, `1.2`, `1`, and `latest`.

For reproducible deployments, pin an immutable image digest.

## Local development

Until the SteamCMD v2 image is published, build its repository locally as
`docker-steamcmd:test`, then override the base image:

```console
docker build --tag docker-steamcmd:test ../docker-steamcmd
docker build \
  --build-arg STEAMCMD_IMAGE=docker-steamcmd:test \
  --tag docker-avorion:test \
  .
```

The scheduled/manual integration test downloads Avorion into a disposable named
volume and verifies that the dedicated server reaches its startup-complete state:

```console
bash tests/integration.sh
```

## Security

See [SECURITY.md](SECURITY.md) for private vulnerability reporting instructions.
