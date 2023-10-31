#!/bin/bash

# WOFI STYLES
# CONFIG="$HOME/.config/hypr/wofi/WofiBig/config"
# STYLE="$HOME/.config/hypr/wofi/style.css"
# COLORS="$HOME/.config/hypr/wofi/colors"
#
# if [[ ! $(pidof wofi) ]]; then
#   cliphist list | rofi --show dmenu --prompt 'Search...' \
#     --conf ${CONFIG} --style ${STYLE} --color ${COLORS} \
#     --width=600 --height=400 | cliphist decode | wl-copy
# else
# 	pkill wofi
# fi
cliphist list | rofi -dmenu | cliphist decode | wl-copy
