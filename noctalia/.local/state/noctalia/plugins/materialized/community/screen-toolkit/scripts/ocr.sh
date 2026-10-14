#!/usr/bin/env bash
# Args: $1=image_file $2=lang
#
# Runs tesseract over an image captured through the shell's screenshot stack
# (see shell-capture.sh). Capture is the shell's job now; this script only
# preprocesses and OCRs the given file.
#
# Exit codes:
#   1 — missing dependency (dep name written to stdout)
#   2 — bad/missing args (file not found)
#   4 — image processing failed
# Exit 0 with empty stdout = no text found (service handles this case)

FILE="${1:-}"
RAW_LANG="${2:-eng}"
TMP_BASE="/tmp/screen-toolkit-ocr-work-$$"
TMP="${TMP_BASE}.pnm"
TMP_NOISE="${TMP_BASE}-nr.pnm"

cleanup() { rm -f "$TMP" "$TMP_NOISE"; }
trap cleanup EXIT

for dep in magick tesseract; do
    command -v "$dep" >/dev/null 2>&1 || { echo "$dep"; exit 1; }
done

[ -n "$FILE" ] && [ -f "$FILE" ] || exit 2

LANG=$(echo "$RAW_LANG" | tr '+' '\n' \
    | grep -v '^osd$' \
    | grep -v '^$' \
    | tr '\n' '+' \
    | sed 's/+$//')
[ -z "$LANG" ] && LANG="eng"

AVAILABLE=$(tesseract --list-langs 2>/dev/null | tail -n +2)
VALID_LANGS=""
IFS='+' read -ra LANG_PARTS <<< "$LANG"
for l in "${LANG_PARTS[@]}"; do
    if echo "$AVAILABLE" | grep -qx "$l"; then
        VALID_LANGS="${VALID_LANGS}+${l}"
    fi
done
LANG="${VALID_LANGS#+}"
[ -z "$LANG" ] && LANG="eng"

read -r GW GH < <(magick identify -format '%w %h\n' "$FILE" 2>/dev/null) \
    || { GW=0; GH=0; }

# Upscale tiny captures and pick a page-segmentation mode from the geometry
# (ported from the service's ocrParams: ratio > 8 reads as a single line).
_heu=$(awk -v w="$GW" -v h="$GH" 'BEGIN {
    area = w * h
    up = ""
    if (h < 30) up = "-resize 400%"
    else if (area < 50000 || w < 200) up = "-resize 200%"
    ratio = w / (h > 0 ? h : 1)
    if (ratio > 8) psm = 7
    else if (area < 60000) psm = 6
    else if (h < 40) psm = 7
    else psm = 3
    extra = ""
    if (up == "" && w < 200 && w > 0) {
        s = int(300 / w + 0.5)
        extra = "-scale " s "00%"
    }
    printf "%s\n%d\n%s\n", up, psm, extra
}')
UPSCALE=$(printf '%s' "$_heu" | sed -n '1p')
USER_PSM=$(printf '%s' "$_heu" | sed -n '2p')
EXTRA_SCALE=$(printf '%s' "$_heu" | sed -n '3p')
[ -z "$USER_PSM" ] && USER_PSM=3
if [ -n "$EXTRA_SCALE" ]; then
    UPSCALE="$EXTRA_SCALE"
fi

magick "$FILE" $UPSCALE \
    -colorspace Gray \
    -normalize \
    -contrast-stretch 2%x1% \
    -sharpen 0x1.5 \
    +repage \
    "$TMP" 2>/dev/null || exit 4

MEAN=$(magick "$TMP" -format '%[fx:mean]' info: 2>/dev/null)
if awk "BEGIN{exit !($MEAN < 0.4)}"; then
    magick "$TMP" -negate "$TMP" 2>/dev/null
fi
magick "$TMP" -median 1 "$TMP_NOISE" 2>/dev/null

run_ocr() { tesseract "$1" stdout -l "$LANG" --psm "$2" --oem 1 2>/dev/null; }
count_chars() { printf '%s' "$1" | tr -d '[:space:]' | wc -c; }

TEXT=$(run_ocr "$TMP" "$USER_PSM")
BEST_LEN=$(count_chars "$TEXT")
BEST_TEXT="$TEXT"

if [ "$BEST_LEN" -lt 4 ] || [ "$USER_PSM" -ne 6 ]; then
    TEXT2=$(run_ocr "$TMP_NOISE" 6)
    LEN2=$(count_chars "$TEXT2")
    [ "$LEN2" -gt "$BEST_LEN" ] && { BEST_LEN=$LEN2; BEST_TEXT="$TEXT2"; }
fi
if [ "$BEST_LEN" -lt 4 ]; then
    TEXT3=$(run_ocr "$TMP_NOISE" 4)
    LEN3=$(count_chars "$TEXT3")
    [ "$LEN3" -gt "$BEST_LEN" ] && { BEST_LEN=$LEN3; BEST_TEXT="$TEXT3"; }
fi
if [ "$BEST_LEN" -lt 4 ]; then
    TEXT4=$(magick "$TMP" -threshold 85% stdout 2>/dev/null \
        | tesseract - stdout -l "$LANG" --psm 11 --oem 1 2>/dev/null)
    LEN4=$(count_chars "$TEXT4")
    [ "$LEN4" -gt "$BEST_LEN" ] && BEST_TEXT="$TEXT4"
fi

printf '%s' "$BEST_TEXT"
