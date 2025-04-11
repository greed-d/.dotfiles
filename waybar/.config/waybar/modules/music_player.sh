#!/bin/sh

if [ -z "$1" ]; then
  echo "No argument provided. Usage: $0 [grep|pause|other]"
  exit 1
fi

if pgrep -x "spotify" > /dev/null
then
    music_player="spotify"
else
    music_player="ncspot"
fi

icon=""

action=$1

case "$action" in
    grep)
        class=$(playerctl metadata --player=$music_player --format '{{lc(status)}}')
        if [[ $class == "playing" ]]; then
        info=$(playerctl metadata --player=$music_player --format '{{artist}} - {{title}}')
        
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
        info=$(playerctl metadata --player=$music_player --format '{{artist}} - {{title}}')
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
        ;;
    
    pause)
        playerctl --player=$music_player play-pause
        ;;
    
    previous)
        playerctl --player=$music_player previous
        ;;

    next)
        playerctl --player=$music_player next
        ;;  
    *)
        echo "Unknown action: $action. Please use 'grep', 'pause', 'previous', or 'next'."
        exit 1
        ;;
esac
