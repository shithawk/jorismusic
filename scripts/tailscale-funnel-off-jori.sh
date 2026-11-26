#!/bin/bash
# Turn off Jori's public Tailscale Funnel (:10000).
set -euo pipefail

tailscale funnel --https=10000 off
tailscale funnel status || echo "Jori funnel off."
