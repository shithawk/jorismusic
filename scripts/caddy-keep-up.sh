#!/bin/bash
# Keep Jori's Music Caddy on :8090 and Tailscale HTTPS / pointed at it.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$ROOT/caddy-data"
bash "$ROOT/scripts/ensure-suggest-api.sh" >/dev/null 2>&1 || true

# Ensure Tailscale Serve (root URL) proxies here. Ignore failures if Tailscale is off.
tailscale serve --bg http://127.0.0.1:8090 >/dev/null 2>&1 || true

exec /opt/homebrew/bin/caddy run --config "$ROOT/Caddyfile"
