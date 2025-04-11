#!/bin/sh

class=$(playerctl metadata --player=ncspot --format '{{lc(status)}}')
icon=""

if [[ $class == "playing" ]]; then
  info=$(playerctl metadata --player=ncspot --format '{{artist}} - {{title}}')
  
  # Check if title length exceeds 36 characters
  if [[ ${#info} -gt 36 ]]; then
    # Trim title to 36 characters and add "..."
    trimmed_title="${info:0:36}.."
  else
    # Keep full title if less than or equal to 36 characters
    trimmed_title="$info"
  fi

  text="$icon  $trimmed_title"
elif [[ $class == "paused" ]]; then
  info=$(playerctl metadata --player=ncspot --format '{{artist}} - {{title}}')
  # Check if title length exceeds 36 characters
  if [[ ${#info} -gt 36 ]]; then
    # Trim title to 36 characters and add "..."
    trimmed_title="${info:0:36}.."
  else
    # Keep full title if less than or equal to 36 characters
    trimmed_title="$info"
  fi

  text="$icon  $trimmed_title"
elif [[ $class == "stopped" ]]; then
  text=""
fi

echo -e "{\"text\":\""$text"\", \"class\":\""$class"\"}"