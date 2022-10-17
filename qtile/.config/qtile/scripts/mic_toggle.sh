#!/bin/bash
# With icon indicating the state of the mic

state=`amixer -D pulse sset Capture toggle | gawk 'match($0, /Front Left.*\[(.*)\]/, a) {print a[1]}'`
micStatus=""
if [ $state = "off" ]; then
  micStatus="OFF"
  icon="~/.config/qtile/icons/microphone-disabled-symbolic.svg"
else
  micStatus="ON"
  icon="~/.config/qtile/icons/audio-input-microphone-symbolic.svg"
fi
notify-send --hint=int:transient:1 -t 800 -i $icon "MIC STATUS : $micStatus"
