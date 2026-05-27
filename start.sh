#!/bin/bash
set -e

# HERMES_HOME is ephemeral (no Railway volume on free tier). Long-term
# memory is offloaded to mem0 via MEM0_API_KEY. Recreate the directory
# layout hermes expects on every boot.
mkdir -p "$HERMES_HOME"/cron "$HERMES_HOME"/sessions "$HERMES_HOME"/logs \
         "$HERMES_HOME"/memories "$HERMES_HOME"/skills "$HERMES_HOME"/pairing \
         "$HERMES_HOME"/hooks "$HERMES_HOME"/image_cache "$HERMES_HOME"/audio_cache \
         "$HERMES_HOME"/workspace "$HERMES_HOME"/skins "$HERMES_HOME"/plans \
         "$HERMES_HOME"/home

# Always seed config from the upstream example on boot (filesystem is
# ephemeral — no state survives between deploys).
if [ ! -f "$HERMES_HOME/config.yaml" ] && [ -f /opt/hermes-agent/cli-config.yaml.example ]; then
  cp /opt/hermes-agent/cli-config.yaml.example "$HERMES_HOME/config.yaml"
fi

[ ! -f "$HERMES_HOME/.env" ] && touch "$HERMES_HOME/.env"

# Propagate the mem0 key into hermes's env file so the mem0 backend picks it
# up automatically without needing a config edit.
if [ -n "${MEM0_API_KEY:-}" ] && ! grep -q '^MEM0_API_KEY=' "$HERMES_HOME/.env" 2>/dev/null; then
  echo "MEM0_API_KEY=$MEM0_API_KEY" >> "$HERMES_HOME/.env"
fi

# No stale PID/lock files to clear — filesystem is fresh on every container.

echo "[start.sh] Starting Hermes Agent server..."
exec python /app/server.py
