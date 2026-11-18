#!/bin/bash
# Ensure `import qrcode` works for Tailscale/guest QR scripts (user site-packages).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if python3 -c "import qrcode" >/dev/null 2>&1; then
  exit 0
fi

echo "Installing qrcode for Python 3 (see scripts/requirements-qr.txt)…" >&2
if ! python3 -m pip install --user -q -r "$ROOT/scripts/requirements-qr.txt"; then
  echo "pip install failed. Try: python3 -m pip install --user 'qrcode[pil]'" >&2
  exit 1
fi

if ! python3 -c "import qrcode" >/dev/null 2>&1; then
  echo "qrcode still not importable. Check PATH / python3." >&2
  exit 1
fi