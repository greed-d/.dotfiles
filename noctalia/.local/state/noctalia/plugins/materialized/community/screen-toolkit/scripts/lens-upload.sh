#!/usr/bin/env bash
set -euo pipefail
# Args: $1=gx $2=gy $3=gw $4=gh
# Captures a region and opens it in Google Lens via a temporary upload.
# Exit 1 — missing dependency (dep name written to stdout)
# Exit 2 — capture failed
# Exit 3 — upload failed

GX="$1"; GY="$2"; GW="$3"; GH="$4"
FILE="/tmp/screen-toolkit-lens.png"
GRIM_CURSOR_ARGS=()
[ "${SCREEN_TOOLKIT_CAPTURE_CURSOR:-0}" = "1" ] && GRIM_CURSOR_ARGS+=(-c)

for dep in grim curl jq xdg-open; do
    command -v "$dep" >/dev/null 2>&1 || { echo "$dep"; exit 1; }
done

sleep 0.15

# Capture the requested region. Without this the upload would send whatever
# stale image happens to be left at $FILE (or nothing at all).
grim "${GRIM_CURSOR_ARGS[@]}" -g "${GX},${GY} ${GW}x${GH}" "$FILE" 2>/dev/null \
    || { echo "ERROR: grim capture failed" >&2; exit 2; }

RESP=$(curl -sS -f -A 'Mozilla/5.0' --connect-timeout 20 --max-time 60 \
  -F "files[]=@$FILE" 'https://uguu.se/upload' 2>/dev/null) || \
RESP=$(curl -sS -A 'Mozilla/5.0' --connect-timeout 20 --max-time 60 \
  -F "files[]=@$FILE" 'https://uguu.se/upload.php' 2>/dev/null)

rm -f "$FILE"

URL=$(printf '%s' "$RESP" | jq -r '.files[0].url // empty' 2>/dev/null)
if [ -n "$URL" ] && [[ "$URL" == http* ]]; then
    xdg-open "https://lens.google.com/uploadbyurl?url=$URL" >/dev/null 2>&1 &
else
    exit 3
fi
