#!/bin/bash
# Keep family music Caddys alive. Samantha Funnel :10000; Jori on Tailscale root.
set -uo pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
UID_NUM="$(id -u)"
LOG="/Users/jacobward/jorismusic/caddy-data/music-watchdog.log"
mkdir -p "$(dirname "$LOG")"
ts() { date "+%Y-%m-%d %H:%M:%S"; }

kick() {
  local label="$1"
  launchctl kickstart -k "gui/${UID_NUM}/${label}" >/dev/null 2>&1 || \
    launchctl kickstart "gui/${UID_NUM}/${label}" >/dev/null 2>&1 || true
}

ensure_port() {
  local port="$1" label="$2"
  if curl -sf --max-time 2 "http://127.0.0.1:${port}/" >/dev/null; then
    return 0
  fi
  echo "$(ts) :${port} down — restart ${label}" >>"$LOG"
  kick "$label"
  sleep 2
  if curl -sf --max-time 3 "http://127.0.0.1:${port}/" >/dev/null; then
    echo "$(ts) :${port} back" >>"$LOG"
  else
    echo "$(ts) :${port} still down after restart" >>"$LOG"
  fi
}

# Hold idle/system sleep while this watchdog tick runs (and while caddys run under caffeinate).
/usr/bin/caffeinate -is -t 90 >/dev/null 2>&1 &

ensure_port 8090 com.jacobward.jorismusic-caddy
ensure_port 8091 com.jacobward.waynesmusic-caddy
ensure_port 8092 com.jacobward.jacobsmusic-caddy
ensure_port 8093 com.jacobward.dansmusic-caddy
ensure_port 8094 com.jacobward.stefsmusic-caddy
ensure_port 8095 com.jacobward.samanthasmusic-caddy

# Funnel ports only: 443 / 8443 / 10000. Jori=443, Samantha=10000.
if curl -sf --max-time 2 "http://127.0.0.1:8090/" >/dev/null; then
  tailscale funnel --bg --yes --https=443 "http://127.0.0.1:8090" >/dev/null 2>&1 || true
fi
if curl -sf --max-time 2 "http://127.0.0.1:8095/" >/dev/null; then
  tailscale funnel --bg --yes --https=10000 "http://127.0.0.1:8095" >/dev/null 2>&1 || true
fi
# Keep Wayne/Jacob ports mapped if their caddys are up.
curl -sf --max-time 1 "http://127.0.0.1:8091/" >/dev/null && \
  tailscale serve --bg --https=8443 "http://127.0.0.1:8091" >/dev/null 2>&1 || true
curl -sf --max-time 1 "http://127.0.0.1:8092/" >/dev/null && \
  tailscale serve --bg --https=8444 "http://127.0.0.1:8092" >/dev/null 2>&1 || true

exit 0
