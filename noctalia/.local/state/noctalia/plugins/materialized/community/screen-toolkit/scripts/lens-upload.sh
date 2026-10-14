#!/usr/bin/env bash
set -euo pipefail
# Args: $1=image_file
# Uploads an image captured through the shell's screenshot stack
# (see shell-capture.sh) and opens it in Google Lens.
# The source file belongs to the shell's screenshot dir and is never deleted.
# Exit 1 — missing dependency (dep name written to stdout)
# Exit 2 — file not found
# Exit 3 — upload failed

FILE="${1:-}"
[ -n "$FILE" ] && [ -f "$FILE" ] || exit 2

for dep in curl jq xdg-open; do
    command -v "$dep" >/dev/null 2>&1 || { echo "$dep"; exit 1; }
done

RESP=$(curl -sS -f -A 'Mozilla/5.0' --connect-timeout 20 --max-time 60 \
  -F "files[]=@$FILE" 'https://uguu.se/upload' 2>/dev/null) || \
RESP=$(curl -sS -A 'Mozilla/5.0' --connect-timeout 20 --max-time 60 \
  -F "files[]=@$FILE" 'https://uguu.se/upload.php' 2>/dev/null)

URL=$(printf '%s' "$RESP" | jq -r '.files[0].url // empty' 2>/dev/null)
if [ -n "$URL" ] && [[ "$URL" == http* ]]; then
    xdg-open "https://lens.google.com/uploadbyurl?url=$URL" >/dev/null 2>&1 &
else
    exit 3
fi
