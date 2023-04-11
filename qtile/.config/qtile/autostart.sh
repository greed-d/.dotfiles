#!/bin/sh

#Blurring
# picom --experimental-backends --config ~/.config/picom/picom.conf.qtile &

# systray battery icon
cbatticon -u 5 &

# systray volume
volctl &

#nitrogen
nitrogen --restore &

#Discord
discord & 

