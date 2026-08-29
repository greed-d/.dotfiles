#!/usr/bin/env bash
# capture.sh <action> [args...]
#
# Actions:
#   annotate-window          — capture the focused Hyprland window with grim
#                              output: /tmp/screen-toolkit-annotate.png
#                              stdout: "X,Y WxH" geometry string
#   palette   <geometry>     — extract 8 dominant hex colours from a captured region
#                              stdout: one "#RRGGBB" per line
#   qr        <geometry>     — capture a region and decode any QR / barcode found
#                              stdout: decoded text
#
# Exit codes:
#   1 — missing / invalid arguments
#   2 — capture or decode failed
#   3 — missing dependency (hyprctl, jq, grim, magick, zbarimg)
#
# Used by: service.luau

set -euo pipefail

ACTION="${1:-}"
GRIM_CURSOR_ARGS=()
[ "${SCREEN_TOOLKIT_CAPTURE_CURSOR:-0}" = "1" ] && GRIM_CURSOR_ARGS+=(-c)

_require() {
    command -v "$1" >/dev/null 2>&1 \
        || { echo "ERROR: missing dependency: $1" >&2; exit 3; }
}

case "$ACTION" in

  annotate-window)
    _require slurp
    _require hyprctl
    _require jq
    _require grim
    # Crosshair: click the window you want to annotate. slurp blocks until the
    # click, so there is no timeout and its overlay is never captured.
    PT=$(slurp -p 2>/dev/null) || { echo "ERROR: cancelled" >&2; exit 1; }
    X=$(printf '%s' "$PT" | awk -F'[, ]+' '{print int($1)}')
    Y=$(printf '%s' "$PT" | awk -F'[, ]+' '{print int($2)}')
    # Snap to the smallest mapped window containing the clicked point.
    WIN=$(hyprctl clients -j 2>/dev/null | jq -c --argjson x "$X" --argjson y "$Y" '
        [ .[] | select(.mapped == true)
          | { at: (.at // [0, 0]), size: (.size // [0, 0]) }
          | select(.at[0] <= $x and (.at[0] + .size[0]) >= $x
               and .at[1] <= $y and (.at[1] + .size[1]) >= $y) ]
        | sort_by(.size[0] * .size[1]) | first' 2>/dev/null)
    [ -n "$WIN" ] && [ "$WIN" != "null" ] \
        || { echo "ERROR: no window at that point" >&2; exit 2; }
    GEOM=$(printf '%s' "$WIN" | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"' 2>/dev/null)
    [ -n "$GEOM" ] \
        || { echo "ERROR: could not parse window geometry" >&2; exit 2; }
    # grim excludes the cursor by default; moving it would make the picker
    # unreliable and is compositor-specific.
     sleep 0.15
     grim "${GRIM_CURSOR_ARGS[@]}" -g "$GEOM" /tmp/screen-toolkit-annotate.png 2>/dev/null \
        || { echo "ERROR: grim capture failed" >&2; exit 2; }
    printf '%s\n' "$GEOM"
    ;;

  palette)
    GEOMETRY="${2:-}"
    [ -n "$GEOMETRY" ] || { echo "ERROR: palette: missing <geometry>" >&2; exit 1; }
    _require grim
    _require magick

    FILE="/tmp/screen-toolkit-palette.png"

     sleep 0.15
     grim "${GRIM_CURSOR_ARGS[@]}" -g "$GEOMETRY" "$FILE" 2>/dev/null \
        || { echo "ERROR: palette: grim capture failed" >&2; exit 2; }

    magick "$FILE" -alpha off +dither -colors 8 -unique-colors txt:- 2>/dev/null \
        | grep -v '^#' \
        | grep -oP '#[0-9a-fA-F]{6}' \
        | head -8
    ;;

  qr)
    GEOMETRY="${2:-}"
    [ -n "$GEOMETRY" ] || { echo "ERROR: qr: missing <geometry>" >&2; exit 1; }
    _require grim
    _require zbarimg

     sleep 0.15
     grim "${GRIM_CURSOR_ARGS[@]}" -g "$GEOMETRY" /tmp/screen-toolkit-qr.png 2>/dev/null \
        || { echo "ERROR: qr: grim capture failed" >&2; exit 2; }

    zbarimg -q --raw /tmp/screen-toolkit-qr.png 2>/dev/null
    ;;

  *)
    echo "ERROR: unknown action '${ACTION}'. Expected: annotate-window | palette | qr" >&2
    exit 1
    ;;

esac
