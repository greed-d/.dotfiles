#!/bin/bash

# Get location data using IP Geolocation

# Recommended with API, but you can try w/o API [IPINFO.IO]
# API_TOKEN="YOUR_API_TOKEN"
# location_data=$(curl -s "https://ipinfo.io?token=$API_TOKEN" 2>/dev/null)
# location_data=$(curl -s https://ipinfo.io 2>/dev/null) #[Limited requests. Require API to send 50k request/month]

# Extract city and country code (ISO 3166-1 alpha-2 code)
# CITY=$(echo "$location_data" | jq -r '.city // empty')
# COUNTRY=$(echo "$location_data" | jq -r '.country // empty')

# IPINFO Alternative [IP-API.COM]
location_data=$(curl -s "http://ip-api.com/json/" 2>/dev/null)

# Extract city and country code
CITY=$(echo "$location_data" | jq -r '.city // empty')
COUNTRY=$(echo "$location_data" | jq -r '.countryCode // empty')
# Visit http://ip-api.com/json/ to find other variables

# HARDCODE Location
# CITY=$(grep -oP '^\$CITY\s*=\s*\K.+' ~/.config/hypr/hyprlock.conf)
# COUNTRY=$(grep -oP '^\$COUNTRY\s*=\s*\K.+' ~/.config/hypr/hyprlock.conf)

# Check if CITY and COUNTRY are valid
if [[ -n "$CITY" && -n "$COUNTRY" ]]; then
    # Fetch weather info for the detected city from wttr.in
    weather_info=$(curl -s "wttr.in/$CITY?format=%c+%C+%t" 2>/dev/null)

    # Check if the weather info is valid
    if [[ -n "$weather_info" ]]; then
        echo "$COUNTRY, $CITY: $weather_info"
    else
        echo "Weather info unavailable for $COUNTRY, $CITY"
    fi
else
    echo "Unable to determine your location"
fi
