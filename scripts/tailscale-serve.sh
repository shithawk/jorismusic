#!/bin/bash
# Expose both music sites on one Mac over Tailscale (tailnet only).
#   Jori's  → https://<machine>.<tailnet>.ts.net/          (Caddy :8090)
#   Wayne's → https://<machine>.<tailnet>.ts.net:8443/   (Caddy :8091)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WAYNE="$(cd "$ROOT/../waynesmusic" 2>/dev/null && pwd || true)"

echo "Tailscale Serve: Jori's on :8090 (HTTPS /), Wayne's on :8091 (HTTPS :8443)"
tailscale serve --bg http://127.0.0.1:8090
tailscale serve --bg --https=8443 http://127.0.0.1:8091
tailscale serve status

if ! lsof -iTCP:8090 -sTCP:LISTEN >/dev/null 2>&1; then
  echo "Starting Caddy for Jori's (8090)…"
  (cd "$ROOT" && caddy run --config Caddyfile) &
fi

if [[ -n "$WAYNE" && -f "$WAYNE/Caddyfile" ]]; then
  if ! lsof -iTCP:8091 -sTCP:LISTEN >/dev/null 2>&1; then
    echo "Starting Caddy for Wayne's (8091)…"
    (cd "$WAYNE" && caddy run --config Caddyfile) &
  fi
else
  echo "Note: waynesmusic not found at $ROOT/../waynesmusic — only Jori's URL is set up."
fi

DNS="$(tailscale status --json 2>/dev/null | python3 -c 'import json,sys; print(json.load(sys.stdin)["Self"]["DNSName"].rstrip("."))' 2>/dev/null || true)"
if [[ -n "$DNS" ]]; then
  echo ""
  echo "Jori's on iPhone (or iPad):"
  echo "  1. Install Tailscale, sign in to the same account, turn VPN on."
  echo "  2. Safari → https://${DNS}/"
  echo "  3. Share → Add to Home Screen (for the Jori's Music icon)."
fi