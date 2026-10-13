#!/usr/bin/env bash
# capture.sh <action> <image_file>
#
# Pixel processing over images captured through the shell's screenshot stack
# (see shell-capture.sh). Capture is the shell's job now; these actions only
# read the given file.
#
# Actions:
#   palette <file>     — extract up to 8 dominant hex colours
#                        stdout: one "#RRGGBB" per line
#   qr      <file>     — decode any QR / barcode found
#                        stdout: decoded text
#
# Exit codes:
#   1 — missing dependency (dep name written to stdout)
#   2 — missing / invalid arguments
#   3 — processing failed
#
# Used by: service.luau

set -euo pipefail

ACTION="${1:-}"
FILE="${2:-}"

_require() {
    command -v "$1" >/dev/null 2>&1 \
        || { echo "$1"; exit 1; }
}

[ -n "$FILE" ] && [ -f "$FILE" ] || { echo "ERROR: missing <image_file>" >&2; exit 2; }

case "$ACTION" in

  palette)
    _require magick
    magick "$FILE" -alpha off +dither -colors 8 -unique-colors txt:- 2>/dev/null \
        | grep -v '^#' \
        | grep -oP '#[0-9a-fA-F]{6}' \
        | head -8 || exit 3
    ;;

  qr)
    _require zbarimg
    zbarimg -q --raw "$FILE" 2>/dev/null || exit 3
    ;;

  *)
    echo "ERROR: unknown action '${ACTION}'. Expected: palette | qr" >&2
    exit 2
    ;;

esac
