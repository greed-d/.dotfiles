#!/usr/bin/env bash
# record.sh <action> [args...]
#
# Actions:
#   thumb        <src>                    — extract mid-frame thumbnail → /tmp/screen-toolkit-record-thumb.png
#   convert-mp4  <input> <output>         — finalize MP4: stream-copy (fast path)
#   convert-mp4  <input> <output> --recode — finalize MP4: re-encode audio to AAC 128k + faststart
#   convert-gif  <input> <output> [maxsec] — convert MP4 → palette-optimized GIF at 15 fps
#   convert-mov  <input> <output>           — remux MP4 → MOV (stream copy)
#   stop         <recorder-bin>           — send SIGINT to the named recorder process
#
# Exit codes:
#   1 — missing / invalid arguments
#   2 — input file not found
#   3 — missing dependency (ffmpeg, ffprobe, pkill)
#   4 — conversion or process command failed
#
# Used by: service.luau
set -euo pipefail
ACTION="${1:-}"
THUMB_OUT="/tmp/screen-toolkit-record-thumb.png"
PALETTE="/tmp/screen-toolkit-record-palette-$$.png"
_require() {
    command -v "$1" >/dev/null 2>&1 \
        || { echo "ERROR: missing dependency: $1" >&2; exit 3; }
}
_thumb() {
    local src="$1"
    _require ffprobe
    _require ffmpeg
    local dur
    dur=$(ffprobe -v error \
        -show_entries format=duration \
        -of default=noprint_wrappers=1:nokey=1 \
        "$src" 2>/dev/null) || dur=""
    [[ -z "$dur" || "$dur" == "N/A" ]] && dur=1
    local mid
    mid=$(echo "$dur / 2" | bc -l 2>/dev/null) || mid="0.5"
    ffmpeg -y -ss "$mid" -i "$src" -frames:v 1 "$THUMB_OUT" 2>/dev/null
}
case "$ACTION" in
  thumb)
    SRC="${2:-}"
    [ -n "$SRC" ] || { echo "ERROR: thumb: missing <src>"           >&2; exit 1; }
    [ -f "$SRC" ] || { echo "ERROR: thumb: file not found: $SRC"   >&2; exit 2; }
    _thumb "$SRC"
    ;;
  convert-mp4)
    INPUT="${2:-}"
    OUTPUT="${3:-}"
    RECODE="${4:-}"
    [ -n "$INPUT"  ] || { echo "ERROR: convert-mp4: missing <input>"          >&2; exit 1; }
    [ -n "$OUTPUT" ] || { echo "ERROR: convert-mp4: missing <output>"         >&2; exit 1; }
    [ -f "$INPUT"  ] || { echo "ERROR: convert-mp4: file not found: $INPUT"   >&2; exit 2; }
    _require ffmpeg
    if [ "$RECODE" = "--recode" ]; then
        ffmpeg -y -i "$INPUT" \
            -c:v copy -c:a aac -b:a 128k -movflags +faststart \
            "$OUTPUT" 2>/dev/null \
        || { echo "ERROR: convert-mp4: ffmpeg recode failed" >&2; exit 4; }
        rm -f "$INPUT"
    else
        mv "$INPUT" "$OUTPUT" \
        || { echo "ERROR: convert-mp4: mv failed" >&2; exit 4; }
    fi
    _thumb "$OUTPUT"
    ;;
  convert-gif)
    INPUT="${2:-}"
    OUTPUT="${3:-}"
    MAXSEC="${4:-}"
    [ -n "$INPUT"  ] || { echo "ERROR: convert-gif: missing <input>"          >&2; exit 1; }
    [ -n "$OUTPUT" ] || { echo "ERROR: convert-gif: missing <output>"         >&2; exit 1; }
    [ -f "$INPUT"  ] || { echo "ERROR: convert-gif: file not found: $INPUT"   >&2; exit 2; }
    _require ffmpeg
    DURATION=""
    if [ -n "$MAXSEC" ] && [ "$MAXSEC" -gt 0 ] 2>/dev/null; then
        DURATION="-t $MAXSEC"
    fi
    ffmpeg -y $DURATION -i "$INPUT" \
        -vf 'fps=15,scale=trunc(iw/2)*2:trunc(ih/2)*2:flags=bilinear,palettegen=stats_mode=diff' \
        "$PALETTE" 2>/dev/null \
    || { echo "ERROR: convert-gif: palettegen pass failed" >&2; exit 4; }
    ffmpeg -y $DURATION -i "$INPUT" -i "$PALETTE" \
        -lavfi 'fps=15,scale=trunc(iw/2)*2:trunc(ih/2)*2:flags=bilinear[x];[x][1:v]paletteuse=dither=bayer:bayer_scale=5' \
        "$OUTPUT" 2>/dev/null \
    || { echo "ERROR: convert-gif: paletteuse pass failed" >&2; exit 4; }
    rm -f "$PALETTE" "$INPUT"
    _thumb "$OUTPUT"
    ;;
  convert-mov)
    INPUT="${2:-}"
    OUTPUT="${3:-}"
    [ -n "$INPUT"  ] || { echo "ERROR: convert-mov: missing <input>"          >&2; exit 1; }
    [ -n "$OUTPUT" ] || { echo "ERROR: convert-mov: missing <output>"         >&2; exit 1; }
    [ -f "$INPUT"  ] || { echo "ERROR: convert-mov: file not found: $INPUT"   >&2; exit 2; }
    _require ffmpeg
    ffmpeg -y -i "$INPUT" -c copy -movflags +faststart "$OUTPUT" 2>/dev/null \
        || { echo "ERROR: convert-mov: ffmpeg failed" >&2; exit 4; }
    rm -f "$INPUT"
    _thumb "$OUTPUT"
    ;;
  stop)
    BIN="${2:-}"
    [ -n "$BIN" ] || { echo "ERROR: stop: missing <recorder-bin>" >&2; exit 1; }
    _require pkill
    pkill -INT "$BIN" 2>/dev/null || true
    ;;
  *)
    echo "ERROR: unknown action '${ACTION}'. Expected: thumb | convert-mp4 | convert-gif | convert-mov | stop" >&2
    exit 1
    ;;
esac
