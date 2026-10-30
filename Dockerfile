# ---------- firewall: small image that only sets the network rules ----------
FROM debian:bookworm-slim AS firewall

RUN apt-get update && apt-get install -y --no-install-recommends iptables \
    && rm -rf /var/lib/apt/lists/*

COPY --chmod=755 firewall.sh /usr/local/bin/firewall.sh
ENTRYPOINT ["/usr/local/bin/firewall.sh"]


# ---------- t3code: T3 Code server plus the agent CLIs it drives ----------
FROM node:24-bookworm-slim AS t3code

RUN apt-get update && apt-get install -y --no-install-recommends \
      git openssh-client ca-certificates curl ripgrep python3 make g++ \
      sudo iptables \
    && rm -rf /var/lib/apt/lists/*

# Versions come from .env via docker-compose.yml ("latest" or a pinned version).
ARG T3_VERSION=latest
ARG CODEX_VERSION=latest
ARG CLAUDE_CODE_VERSION=latest
# update.sh sets this to a fresh value so Docker re-runs the install below
# instead of reusing the cached layer (which would keep the old "latest").
ARG CLI_CACHE_BUST=0
RUN echo "cli cache bust: ${CLI_CACHE_BUST}" \
    && npm install -g \
      t3@${T3_VERSION} \
      @openai/codex@${CODEX_VERSION} \
      @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION} \
    && npm cache clean --force

# Agents run as "node" and can use sudo (apt-get etc.) inside the container.
RUN echo 'node ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/node \
    && chmod 0440 /etc/sudoers.d/node \
    && mkdir -p /workspace && chown node:node /workspace

USER node
WORKDIR /workspace
EXPOSE 3773

CMD ["t3", "serve", "--host", "0.0.0.0"]
