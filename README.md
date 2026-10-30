# T3 Code in Docker

T3 Code plus the Codex and Claude Code CLIs, behind an outbound firewall.
Agents reach the internet but not your LAN, host or other containers.
The one host exception is Ollama on port 11434.

## Start

```sh
docker compose up -d --build
```

Open http://127.0.0.1:3773. State lives in `home/`, projects in `workspace/`.

## Update

```sh
./update.sh          # newest T3 Code, Codex, Claude Code and base image
./update.sh --full   # same, plus rebuild apt packages from scratch
```

The CLIs' own auto-updaters are off, so this script is the only update path.
To pin a version, copy `.env.example` to `.env` and set it there.

## Pairing

```sh
# Link for a client (all permissions)
docker compose exec t3code t3 auth pairing create --label "my laptop" --base-url http://127.0.0.1:3773

# QR code for a phone (all permissions)
docker compose exec t3code t3 pair --label "my phone"

# List and remove paired clients
docker compose exec t3code t3 auth session list
docker compose exec t3code t3 auth session revoke <id>

# Only some permissions (each --scope replaces the full default set)
docker compose exec t3code t3 auth pairing create \
  --scope orchestration:read --scope orchestration:operate \
  --scope terminal:operate --scope terminal:read \
  --scope filesystem:read --scope filesystem:write \
  --scope source-control:write --scope relay:read
```

Tokens expire after 5 minutes unless you pass `--ttl`.
