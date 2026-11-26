#!/bin/bash
# Keep Jori's Music Caddy on :8090 and Tailscale HTTPS / pointed at it.
# WorkingDirectory must be jorismusic so relative roots (music/, youtube/, web/) work.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$ROOT/caddy-data"
cd "$ROOT"
bash "$ROOT/scripts/ensure-suggest-api.sh" >/dev/null 2>&1 || true

# Ensure Tailscale Serve (root URL) proxies here. Ignore failures if Tailscale is off.
# Do not touch :8443/:8444 — those are Wayne/Jacob.
tailscale serve --bg http://127.0.0.1:8090 >/dev/null 2>&1 || true
# Public Funnel on 443 (root) — only Funnel ports are 443/8443/10000; 10000 is Samantha.
tailscale funnel --bg --yes --https=443 http://127.0.0.1:8090 >/dev/null 2>&1 || true

exec /usr/bin/caffeinate -is /opt/homebrew/bin/caddy run --config "$ROOT/Caddyfile"
