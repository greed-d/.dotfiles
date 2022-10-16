#!/bin/sh

picom --experimental-backends --config ~/.config/picom/picom.conf.example &
# systray battery icon
cbatticon -u 5 &
# systray volume
volumeicon &
#nitrogen
nitrogen --restore &
#Discord
discord & 
#freedownloadmanager
fdm &
#for Wifi
# sudo systemctl start iwd
