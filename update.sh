#!/bin/sh
# Rebuild with the newest T3 Code, Codex and Claude Code, then restart.
#   ./update.sh         refresh base image + CLIs (fast, keeps apt layer cache)
#   ./update.sh --full  rebuild everything from scratch (also refreshes apt packages)
# Versions are "latest" unless pinned in .env (see .env.example).
set -eu
cd "$(dirname "$0")"

if [ "${1:-}" = "--full" ]; then
  docker compose build --pull --no-cache
else
  CLI_CACHE_BUST="$(date +%s)" docker compose build --pull
fi

docker compose up -d
docker image prune -f >/dev/null

echo "Installed versions:"
docker compose exec -T t3code npm ls -g --depth=0 \
  | grep -E 't3@|@openai/codex@|@anthropic-ai/claude-code@' || true
