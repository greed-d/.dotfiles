#!/usr/bin/env bash
# capture-niri.sh <action>
#
# Niri window capture for Screen Toolkit. Niri screenshots the focused window
# directly via its IPC, so no slurp crosshair or geometry math is needed.
#
# Actions:
#   annotate-window          — capture the focused niri window
#                              output: /tmp/screen-toolkit-annotate.png
#                              stdout: "X,Y WxH" geometry string
#
# Exit codes:
#   1 — missing / invalid arguments
#   2 — capture failed
#   3 — missing dependency (niri)
#
# Used by: service.luau

set -euo pipefail

ACTION="${1:-}"

_require() {
    command -v "$1" >/dev/null 2>&1 \
        || { echo "ERROR: missing dependency: $1" >&2; exit 3; }
}

case "$ACTION" in

  annotate-window)
    _require niri
    # niri msg needs the compositor's IPC socket. Prefer the ambient env var;
    # fall back to auto-discovering the socket in the user runtime dir.
    if [ -z "${NIRI_SOCKET:-}" ]; then
        export NIRI_SOCKET
        NIRI_SOCKET=$(ls /run/user/$(id -u)/niri*.sock 2>/dev/null | head -1) \
            || { echo "ERROR: could not find niri socket" >&2; exit 2; }
    fi
    _tmp="/tmp/screen-toolkit-annotate-tmp-$$.png"
    rm -f "$_tmp"
    # niri writes the screenshot asynchronously; poll until the file appears.
    niri msg action screenshot-window --path "$_tmp" \
        || { rm -f "$_tmp"; echo "ERROR: niri screenshot-window failed" >&2; exit 2; }
    _i=0; while [ ! -s "$_tmp" ] && [ "$_i" -lt 50 ]; do
        sleep 0.1
        _i=$((_i + 1))
    done
    [ -s "$_tmp" ] \
        || { rm -f "$_tmp"; echo "ERROR: niri screenshot timed out" >&2; exit 2; }
    mv "$_tmp" /tmp/screen-toolkit-annotate.png
    printf '%s\n' "0,0 0x0"
    ;;

  *)
    echo "ERROR: unknown action '${ACTION}'. Expected: annotate-window" >&2
    exit 1
    ;;

esac