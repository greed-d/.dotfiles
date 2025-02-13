#!/bin/bash

# Set this variable to control the output
# Set to "true" to show SSID, "false" to show "Connected"
# show_ssid=false

# Read the wifi-mode alias from hyprlock.conf
show_ssid=$(grep -oP '^\$wifi-mode\s*=\s*\K\S+' ~/.config/hypr/hyprlock.conf)

# Check if the username was successfully extracted
if [ -z "$show_ssid" ]; then
  echo "Username not found in hyprlock.conf."
  exit 1
fi

# Get Wi-Fi connection status
wifi_status=$(nmcli -t -f WIFI g)

# Check if Wi-Fi is enabled
if [ "$wifi_status" != "enabled" ]; then
  echo "󰤮  Wi-Fi Off"
  exit 0
fi

# Get active Wi-Fi connection details
wifi_info=$(nmcli -t -f ACTIVE,SSID,SIGNAL dev wifi | grep '^yes')

# If no active connection, show "Disconnected"
if [ -z "$wifi_info" ]; then
  echo "󰤮  No Wi-Fi"
  exit 0
fi

# Extract SSID
ssid=$(echo "$wifi_info" | cut -d':' -f2)

# Extract signal strength
signal_strength=$(echo "$wifi_info" | cut -d':' -f3)

# Define Wi-Fi icons based on signal strength
wifi_icons=("󰤯 " "󰤟 " "󰤢 " "󰤥 " "󰤨 ") # From low to high signal

# Ensure signal_strength is within bounds (0 to 100)
signal_strength=$((signal_strength < 0 ? 0 : (signal_strength > 100 ? 100 : signal_strength)))

# Calculate the icon index based on signal strength (0–100 -> 0–4)
icon_index=$((signal_strength / 25))

# Get the corresponding icon
wifi_icon=${wifi_icons[$icon_index]}

# Output based on show_ssid variable
if [ "$show_ssid" = true ]; then
  # Show SSID
  echo "$wifi_icon $ssid"
else
  # Show "Connected"
  echo "$wifi_icon Connected"
fi
