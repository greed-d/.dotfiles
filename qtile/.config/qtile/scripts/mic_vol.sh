#!/bin/sh

DEFAULT_SOURCE_INDEX=$(pacmd list-sources | grep "\* index:" | cut -d' ' -f5)

display_volume() {
	if [ -z "$volume" ]; then
	  echo "No Mic Found"
	else
	  volume="${volume//[[:blank:]]/}" 
	  if [[ "$mute" == *"yes"* ]]; then
	    echo "[$volume]"
	  elif [[ "$mute" == *"no"* ]]; then
	    echo "$volume"
	  else
	    echo "$volume !"
	  fi
	fi
}

case $1 in
	"show-vol")
		if [ -z "$2" ]; then
  			volume=$(pacmd list-sources | grep "index: $DEFAULT_SOURCE_INDEX" -A 7 | grep "volume" | awk -F/ '{print $2}')
  			mute=$(pacmd list-sources | grep "index: $DEFAULT_SOURCE_INDEX" -A 11 | grep "muted")
			display_volume
		else
  			volume=$(pacmd list-sources | grep "$2" -A 6 | grep "volume" | awk -F/ '{print $2}')
  			mute=$(pacmd list-sources | grep "$2" -A 11 | grep "muted" )
			display_volume
		fi
		;;
	"inc-vol")
		if [ -z "$2" ]; then
			pactl set-source-volume $DEFAULT_SOURCE_INDEX +7%
		else
			pactl set-source-volume $2 +7%
		fi
		;;
	"dec-vol")
		if [ -z "$2" ]; then
			pactl set-source-volume $DEFAULT_SOURCE_INDEX -7%
		else
			pactl set-source-volume $2 -7%
		fi
		;;
	"mute-vol")
		if [ -z "$2" ]; then
			pactl set-source-mute $DEFAULT_SOURCE_INDEX toggle
		else
			pactl set-source-mute $2 toggle
		fi
		;;
	*)
		echo "Invalid script option"
		;;
esac
