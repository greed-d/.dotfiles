#!/bin/sh

picom --experimental-backends &
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
