FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim

# Latest Hermes (bleeding edge). Pin to a release tag like v2026.5.16 if you
# want reproducible builds.
ARG HERMES_REF=main

# tini = PID 1 zombie reaper + SIGTERM forwarder for Railway graceful stops.
# Node 22 needed at build time to compile the React dashboard + TUI bundle.
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl ca-certificates git tini && \
    curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    rm -rf /var/lib/apt/lists/*

# Install hermes-agent with EVERY extras bundle so every command/feature in
# the admin dashboard works out of the box (gateway, cron, mcp, acp, pty,
# web, google, youtube, sms, homeassistant, messaging platforms, all TTS
# engines, all model providers, memory + observability).
RUN git clone --depth 1 --branch ${HERMES_REF} https://github.com/NousResearch/hermes-agent.git /opt/hermes-agent && \
    cd /opt/hermes-agent && \
    uv pip install --system --no-cache -e ".[all,messaging,tts-premium,honcho,bedrock,anthropic,edge-tts,hindsight]" && \
    cd /opt/hermes-agent/web && \
    npm install --silent --no-fund --no-audit --progress=false && \
    npm run build && \
    cd /opt/hermes-agent/ui-tui && \
    npm install --silent --no-fund --no-audit --progress=false && \
    npm run build && \
    rm -rf /opt/hermes-agent/web /opt/hermes-agent/.git /root/.npm /tmp/*

# Pre-built TUI bundle for instant /chat WebSocket connect (no first-call
# npm install/build).
ENV HERMES_TUI_DIR=/opt/hermes-agent/ui-tui

COPY requirements.txt /app/requirements.txt
RUN uv pip install --system --no-cache -r /app/requirements.txt

COPY server.py /app/server.py
COPY templates/ /app/templates/
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

# No persistent volume — Railway free tier doesn't include one.
# HERMES_HOME lives inside the container filesystem. Long-term memory is
# delegated to mem0 (set MEM0_API_KEY in Railway env).
# NOTE: sessions, logs, and pairing tokens are EPHEMERAL — they reset on
# every redeploy. Config is re-seeded from cli-config.yaml.example on boot.
ENV HOME=/app
ENV HERMES_HOME=/app/.hermes
ENV PYTHONUNBUFFERED=1

RUN mkdir -p /app/.hermes

ENTRYPOINT ["/usr/bin/tini", "-g", "--"]
CMD ["/app/start.sh"]
