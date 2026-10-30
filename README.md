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

## SSH

Login as `node` on port 2222, inside the same container the agents use.
Works for VS Code Remote-SSH, T3 Code over SSH and plain `ssh`/`scp`.

```sh
# Authorize your key (once; stored in home/.ssh)
docker compose exec -T t3code sh -c 'cat >> ~/.ssh/authorized_keys' < ~/.ssh/id_ed25519.pub
```

Or set `SSH_PASSWORD` in `.env` to log in with a password as well
(then `docker compose up -d` to apply). Agents can read it, so make it unique.

```
# ~/.ssh/config
Host t3code
  HostName 127.0.0.1
  Port 2222
  User node
```

Only this machine can connect by default. For other machines, set `SSH_BIND=0.0.0.0` in `.env`
(or jump through the host: `ProxyJump yourhost` with `HostName 127.0.0.1`).
Forwarded ports go through the same firewall as the agents. Agent forwarding is off,
so your SSH keys stay out of reach of the agents.

## Multiple instances

One instance per person or purpose, each fully separate (own logins, keys,
projects and firewall). Clone into another folder and give it other ports:

```sh
git clone https://github.com/JonasBechler/T3-Docker-Firewalled.git t3-second
cd t3-second
printf 'T3_PORT=3774\nSSH_PORT=2223\n' > .env
docker compose up -d --build
```

Containers are named after the folder; `docker compose` commands work as usual from inside it.
All instances share one image, so pin versions the same way in each (or not at all).
With another `T3_PORT`, use it in the pairing `--base-url` below too.

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
