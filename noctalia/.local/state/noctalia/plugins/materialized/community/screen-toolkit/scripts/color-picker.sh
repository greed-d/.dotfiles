#!/usr/bin/env bash
# color-picker.sh <output-png>
# Picks a color from screen, outputs "R G B" to stdout.
# Uses hyprpicker (preferred) or falls back to slurp+grim.
FILE="$1"
[ -z "$FILE" ] && exit 1
GRIM_CURSOR_ARGS=()
[ "${SCREEN_TOOLKIT_CAPTURE_CURSOR:-0}" = "1" ] && GRIM_CURSOR_ARGS+=(-c)
# ── hyprpicker ────────────────────────────────────────────────────────────────
if command -v hyprpicker >/dev/null 2>&1; then
    HYPRCTL=$(command -v hyprctl 2>/dev/null || true)
    if [ -n "$HYPRCTL" ]; then
        PRE_POS=$(hyprctl cursorpos 2>/dev/null)
    fi
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
    if [ -n "$HYPRCTL" ]; then
        sleep 0.08
        POST_POS=$(hyprctl cursorpos 2>/dev/null)
    fi
    CAPTURED=0
    if [ -n "$HYPRCTL" ] && command -v grim >/dev/null 2>&1; then
        # If cursor moved, we have the real pick position
        # If it didn't move, hyprland restored it — coordinates are useless, skip capture
        if [ "$PRE_POS" != "$POST_POS" ] && [ -n "$POST_POS" ]; then
            X=$(echo "$POST_POS" | awk -F'[, ]+' '{print int($1)}')
            Y=$(echo "$POST_POS" | awk -F'[, ]+' '{print int($2)}')
            if [ -n "$X" ] && [ -n "$Y" ] && [ "$X" -ge 0 ] && [ "$Y" -ge 0 ] 2>/dev/null; then
                # Capture 21x21 area centered on picked pixel for more context
                GX=$((X > 10 ? X - 10 : 0))
                GY=$((Y > 10 ? Y - 10 : 0))
                sleep 0.15
                grim "${GRIM_CURSOR_ARGS[@]}" -g "${GX},${GY} 21x21" "$FILE" 2>/dev/null && CAPTURED=1
            fi
        fi
    fi
    # Fallback: solid swatch
    if [ "$CAPTURED" -eq 0 ] && command -v magick >/dev/null 2>&1; then
        magick -size 21x21 "xc:rgb($R,$G,$B)" "$FILE" 2>/dev/null
    fi
    printf '%d %d %d\n' "$R" "$G" "$B"
    exit 0
fi
# ── fallback: slurp + grim + magick ──────────────────────────────────────────
for dep in slurp grim magick; do
    command -v "$dep" >/dev/null 2>&1 || exit 1
done
COORDS=$(slurp -p 2>/dev/null) || exit 1
X=${COORDS%%,*}; REST=${COORDS#*,}; Y=${REST%% *}
GX=$((X > 10 ? X - 10 : 0)); GY=$((Y > 10 ? Y - 10 : 0))
sleep 0.15
grim "${GRIM_CURSOR_ARGS[@]}" -g "${GX},${GY} 21x21" "$FILE" 2>/dev/null || exit 1
magick "$FILE" -alpha off \
    -format '%[fx:int(255*u.p{10,10}.r)] %[fx:int(255*u.p{10,10}.g)] %[fx:int(255*u.p{10,10}.b)]' \
    info:- 2>/dev/null
