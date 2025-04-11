#!/bin/sh

if [ -z "$1" ]; then
    echo "No argument provided. Usage: $0 [grep|pause|previous|next]"
    exit 1
fi

icon=""

action=$1
BASE_URL="http://localhost:10769"

send_request() {
    local endpoint=$1
    curl -s -X GET "$BASE_URL/$endpoint" -o /dev/null
}

case "$action" in
    grep)
        response=$(curl -s -X GET "$BASE_URL/isPlaying")
        is_playing=$(echo "$response" | jq -r '.is_playing')

        if [[ "$is_playing" == "true" ]]; then
            info=$(curl -s -X GET "$BASE_URL/currentPlayingSong" | jq -r '.info | "\(.artistName) - \(.name)"')

            if [[ ${#info} -gt 36 ]]; then
                trimmed_title="${info:0:36}.."
            else
                trimmed_title="$info"
            fi

            text="$icon  $trimmed_title"
            class="playing"
        elif [[ "$is_playing" == "false" ]]; then
            info=$(curl -s -X GET "$BASE_URL/currentPlayingSong" | jq -r '.info | "\(.artistName) - \(.name)"')

            if [[ ${#info} -gt 36 ]]; then
                trimmed_title="${info:0:36}.."
            else
                trimmed_title="$info"
            fi

            text="$icon  $trimmed_title"
            class="paused"
        else
            text=""
            class="stopped"
        fi

        echo -e "{\"text\":\""$text"\", \"class\":\""$class"\"}"
        ;;

    pause)
        send_request "playPause"
        ;;

    previous)
        send_request "previous"
        ;;

    next)
        send_request "next"
        ;;

    *)
        echo "Unknown action: $action. Please use 'grep', 'pause', 'previous', 'next', 'volume-up', or 'volume-down'."
        exit 1
        ;;
esac
