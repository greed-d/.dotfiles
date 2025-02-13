#!/bin/bash

# Get the current battery percentage
battery_percentage=$(cat /sys/class/power_supply/BAT1/capacity)

# Get the battery status (Charging or Discharging)
battery_status=$(cat /sys/class/power_supply/BAT1/status)

# Define the battery icons for each 10% segment
battery_icons=("󰂃" "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰁹")

# Define the charging icon
charging_icon="󰂄"

# Calculate the index for the icon array
# Ensure the index is within bounds (0 to 9) for battery percentages 0 to 100
icon_index=$((battery_percentage / 10))

# If the battery is 100%, use the last icon (index 9)
if [ "$battery_percentage" -eq 100 ]; then
  icon_index=9
fi

# Get the corresponding icon
battery_icon=${battery_icons[$icon_index]}

# Check if the battery is charging
if [ "$battery_status" = "Charging" ]; then
  battery_icon="$charging_icon"
fi

# Output the battery percentage and icon
echo "$battery_percentage% $battery_icon"
