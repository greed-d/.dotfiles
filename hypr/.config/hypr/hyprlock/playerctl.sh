#!/bin/bash

if [ $# -eq 0 ]; then
	echo "Usage: $0 --title | --artist | --album | --source | --source-symbol"
	exit 1
fi

# Function to get metadata using playerctl
get_metadata() {
	key=$1
	playerctl metadata --player=%any,chromium,firefox --format "{{ $key }}" 2>/dev/null
}

# Check for arguments

# Function to determine the source and return an icon and text
get_source_info_symbol() {
	trackid=$(get_metadata "mpris:trackid")
	if [[ "$trackid" == *"firefox"* ]]; then
		echo -e "󰈹"
	elif [[ "$trackid" == *"spotify"* ]]; then
		echo -e ""
	elif [[ "$trackid" == *"chromium"* ]]; then
		echo -e ""
	else
		echo ""
	fi
}

get_source_info() {
	trackid=$(get_metadata "mpris:trackid")
	if [[ "$trackid" == *"firefox"* ]]; then
		echo -e "Firefox"
	elif [[ "$trackid" == *"spotify"* ]]; then
		echo -e "Spotify"
	elif [[ "$trackid" == *"chromium"* ]]; then
		echo -e "Chrome"
	else
		echo ""
	fi
}

# Function to truncate text with ellipsis if necessary
truncate_with_ellipsis() {
	text=$1
	max_length=$2
	if [ ${#text} -gt $max_length ]; then
		echo "${text:0:$((max_length - 3))}..."
	else
		echo "$text"
	fi
}

# Parse the argument
case "$1" in
--title)
	title=$(get_metadata "xesam:title")
	if [ -z "$title" ]; then
		echo ""
	else
		truncate_with_ellipsis "$title" 28 # Limit the output to 50 characters
	fi
	;;
--artist)
	artist=$(get_metadata "xesam:artist")
	if [ -z "$artist" ]; then
		echo ""
	else
		truncate_with_ellipsis "$artist" 28 # Limit the output to 50 characters
	fi
	;;
--status-symbol)
	status=$(playerctl status 2>/dev/null)
	if [[ $status == "Playing" ]]; then
		echo "󰎆"
	elif [[ $status == "Paused" ]]; then
		echo "󰏥"
	else
		echo ""
	fi
	;;
--status)
	status=$(playerctl status 2>/dev/null)
	if [[ $status == "Playing" ]]; then
		echo "Playing Now"
	elif [[ $status == "Paused" ]]; then
		echo "Paused"
	else
		echo ""
	fi
	;;
--album)
	album=$(playerctl metadata --player=%any,chromium,firefox --format "{{ xesam:album }}" 2>/dev/null)
	if [[ -n $album ]]; then
		echo "$album"
	else
		status=$(playerctl status 2>/dev/null)
		if [[ -n $status ]]; then
			echo "Not album"
		else
			truncate_with_ellipsis "$album" 28 # Limit the output to 50 characters
		fi
	fi
	;;
--source-symbol)
	get_source_info_symbol
	;;
--source)
	get_source_info
	;;
*)
	echo "Invalid option: $1"
	echo "Usage: $0 --title | --artist | --album | --source | --source-symbol"
	exit 1
	;;
esac
