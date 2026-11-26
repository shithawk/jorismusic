#!/bin/bash
# Public HTTPS for Jori's Music (mobile data, no Tailscale app required).
#   https://<machine>.<tailnet>.ts.net:10000/
# Public funnel ports are only 443, 8443, 10000.
# Requires Tailscale Funnel enabled for this node in the admin console.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FUNNEL_PORT=10000

if ! curl -sf --max-time 3 "http://127.0.0.1:8090/" >/dev/null; then
  echo "Jori's Caddy is not responding on :8090. Start keep-up first:" >&2
  echo "  bash $ROOT/scripts/caddy-keep-up.sh" >&2
  exit 1
fi

echo "Funnel: port $FUNNEL_PORT → http://127.0.0.1:8090 (Jori's Music)"
# Take over public :10000 (Samantha LaunchAgent should be unloaded while Jori owns Funnel).
tailscale funnel --bg --yes --https="$FUNNEL_PORT" "http://127.0.0.1:8090"
# Keep Tailscale-only root URL on Jori too.
tailscale serve --bg "http://127.0.0.1:8090" >/dev/null 2>&1 || true
tailscale funnel status

DNS="$(tailscale status --json 2>/dev/null | python3 -c 'import json,sys; print(json.load(sys.stdin)["Self"]["DNSName"].rstrip("."))' 2>/dev/null || true)"
if [[ -n "$DNS" ]]; then
  echo ""
  echo "Jori (cellular / no VPN):"
  echo "  https://${DNS}:${FUNNEL_PORT}/"
  echo "iPhone: Safari → Share → Add to Home Screen"
fi
