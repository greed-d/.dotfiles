#!/bin/sh

picom --experimental-backends --config ~/.config/picom/picom.conf &
# systray battery icon
cbatticon -u 5 &
# systray volume
volumeicon &
#nitrogen
nitrogen --restore &
#Discord
armcord & 
#freedownloadmanager
# fdm &
#for Wifi
# sudo systemctl start iwd
