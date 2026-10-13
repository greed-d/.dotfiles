#!/usr/bin/env bash
# color-picker.sh <output-png>
# Picks a color from screen with hyprpicker, outputs "R G B" to stdout.
# The preview swatch is a solid render of the picked color (no capture step).
# Exit 1 — missing dependency (dep name written to stdout)

FILE="$1"
[ -z "$FILE" ] && exit 1

for dep in hyprpicker magick; do
    command -v "$dep" >/dev/null 2>&1 || { echo "$dep"; exit 1; }
done

if hyprpicker --help 2>&1 | grep -q '\-\-radius'; then
    HEX=$(hyprpicker --no-fancy --format=hex --radius=65 2>/dev/null) || exit 1
else
    HEX=$(hyprpicker --no-fancy --format=hex 2>/dev/null) || exit 1
fi
HEX="${HEX#\#}"
[ ${#HEX} -eq 6 ] || exit 1
R=$((16#${HEX:0:2}))
G=$((16#${HEX:2:2}))
B=$((16#${HEX:4:2}))
magick -size 21x21 "xc:rgb($R,$G,$B)" "$FILE" 2>/dev/null
printf '%d %d %d\n' "$R" "$G" "$B"
