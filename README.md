# Hermes Agent on Railway (free tier, no volume)

Latest Hermes with every feature enabled. No persistent volume — long-term
memory lives in [mem0](https://mem0.ai). Built-in CLI / terminal is exposed
through the dashboard's Chat tab (PTY over WebSocket at `/api/pty`).

## Deploy

1. Push this repo. In Railway, create a new service from it.
2. Set **Root Directory** to `railway`.
3. **Environment variables** (Service → Variables):
   - `ADMIN_USERNAME` — default `admin`
   - `ADMIN_PASSWORD` — pick a strong one (required, otherwise a random
     one is printed in logs and changes on every restart)
   - `MEM0_API_KEY` — your mem0 key (`m0-...`) — handles persistent memory
     so you don't need a Railway volume
   - Add any provider keys you want available (e.g. `OPENAI_API_KEY`,
     `ANTHROPIC_API_KEY`, `GOOGLE_API_KEY`)
4. Deploy. First build is ~5–8 min (clones Hermes, installs all extras,
   pre-builds dashboard + TUI).

## Using the CLI in the dashboard

After login (`/login`), open `/` — the native Hermes React dashboard.
The **Chat** tab is a full terminal running `hermes` (PTY-backed), so
every CLI command works there: `/help`, `/model`, `/memory`, `/skills`,
`/mcp`, `/cron`, `/plan`, etc.

The setup wizard at `/setup` lets you edit `config.yaml`, manage env
vars, view logs, and pair external clients — all behind cookie auth.

## What's bundled

Installed extras: `all,messaging,tts-premium,honcho,bedrock,anthropic,edge-tts,hindsight`
plus `mem0ai`. That covers gateway, cron, cli, dev, pty, mcp, acp, web,
google, youtube, sms, home-assistant, every messaging platform, every TTS
engine, every model provider, and memory/observability backends.

## Ephemeral filesystem warning

`/app/.hermes` is **not persisted**. Sessions, local memories, logs, and
pairing tokens reset on every redeploy. Use mem0 for anything you need to
remember across deploys. `config.yaml` is re-seeded from the upstream
example on every boot — bake long-term config into env vars or commit a
custom `config.yaml` into the image if you need it stable.

If you want persistence later, add a Railway volume mounted at
`/app/.hermes` (paid plans) — no other changes needed.

## Files

- `Dockerfile` — Python 3.12 + Node 22, tini PID 1, all Hermes extras
- `start.sh` — seeds ephemeral `$HERMES_HOME`, injects `MEM0_API_KEY`
- `server.py` — Starlette admin + reverse proxy + PTY WebSocket
- `templates/index.html` — setup wizard
- `requirements.txt` / `railway.toml` — deps + Railway config
