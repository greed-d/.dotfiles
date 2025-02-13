#!/bin/bash

# Path to the Hyprland configuration file
config_file="$HOME/.config/hypr/hyprlock.conf"

# Read the bt-mode value from the configuration file
bt_mode=$(grep -oP '^\$bt-mode\s*=\s*\K\S+' ~/.config/hypr/hyprlock.conf)

# Get Bluetooth power status
bluetooth_status=$(bluetoothctl show | grep "Powered:" | awk '{print $2}')

# Check if Bluetooth is powered on
if [ "$bluetooth_status" != "yes" ]; then
    echo "󰂯 Bluetooth Off"
    exit 0
fi

# Initialize connected devices
connected_devices=$(echo "$connected_devices" | sed 's/[[:space:]]*$//')

# Process Bluetooth devices
while read -r line; do
    echo "Processing line: $line" >&2
    device_mac=$(echo "$line" | awk '{print $2}')
    device_name=$(echo "$line" | cut -d' ' -f3-)
    echo "Device MAC: $device_mac" >&2
    echo "Device Name: $device_name" >&2
    if bluetoothctl info "$device_mac" | grep -q "Connected: yes"; then
        connected_devices+="$device_name "
    fi
    echo "Finished processing $device_mac" >&2
    echo "---" >&2
done < <(bluetoothctl devices)

# If no connected devices, show "No Devices"
if [ -z "$connected_devices" ]; then
    echo "󰂲 No Devices"
    exit 0
fi

# Display output based on bt-mode
if [ "$bt_mode" = "true" ]; then
    echo "󰂯 $connected_devices"
else
    echo "󰂯 Connected"
fi

