#!/usr/bin/env bash
# dependencies: pipewire (pw-dump), v4l2loopback-dkms, jq, dbus-send (dbus)
set -euo pipefail

JQ_BIN="${JQ:-jq}"
PW_DUMP_CMD="${PW_DUMP:-pw-dump}"

mic=0
cam=0
loc=0
scr=0

mic_app=""
cam_app=""
loc_app=""
scr_app=""

# mic & camera
if command -v "$PW_DUMP_CMD" >/dev/null 2>&1 && command -v "$JQ_BIN" >/dev/null 2>&1; then
  dump="$($PW_DUMP_CMD 2>/dev/null || true)"

  mic="$(
    printf '%s' "$dump" \
    | $JQ_BIN -r '
      [ .[]
        | select(.type=="PipeWire:Interface:Node")
        | select((.info.props."media.class"=="Audio/Source" or .info.props."media.class"=="Audio/Source/Virtual"))
        | select((.info.state=="running") or (.state=="running"))
      ] | (if length>0 then 1 else 0 end)
    ' 2>/dev/null || echo 0
  )"

  if [[ "$mic" -eq 1 ]]; then
    mic_app="$(
      printf '%s' "$dump" \
      | $JQ_BIN -r '
        [ .[]
          | select(.type=="PipeWire:Interface:Node")
          | select((.info.props."media.class"=="Stream/Input/Audio"))
          | select((.info.state=="running") or (.state=="running"))
          | .info.props["node.name"]
        ] | unique | join(", ")
      ' 2>/dev/null || echo ""
    )"
  fi

  if command -v fuser >/dev/null 2>&1; then
      cam=0
      for dev in /dev/video*; do
          if [ -e "$dev" ] && fuser "$dev" >/dev/null 2>&1; then
              cam=1
              break
          fi
      done
  else
      cam=0
  fi

  if command -v fuser >/dev/null 2>&1; then
      for dev in /dev/video*; do
          if [ -e "$dev" ] && fuser "$dev" >/dev/null 2>&1; then
              pids=$(fuser "$dev" 2>/dev/null)
              for pid in $pids; do
                  pname=$(ps -p "$pid" -o comm=)
                  if [[ -n "$pname" ]]; then
                      cam_app+="$pname, "
                  fi
              done
          fi
      done
      cam_app="${cam_app%, }"
  fi

fi

# location
if command -v gdbus >/dev/null 2>&1; then
  loc="$(
    if ps aux | grep [g]eoclue >/dev/null 2>&1; then
      echo 1
    else
      echo 0
    fi
  )"
fi

if command -v gdbus >/dev/null 2>&1; then
    if pids=$(pgrep -x geoclue); then
        loc=1
        for pid in $pids; do
            pname=$(ps -p "$pid" -o comm=)
            [[ -n "$pname" ]] && loc_app+="$pname, "
        done
        loc_app="${loc_app%, }"
    else
        loc=0
    fi
fi

# screen sharing
if command -v "$PW_DUMP_CMD" >/dev/null 2>&1 && command -v "$JQ_BIN" >/dev/null 2>&1; then
  if [[ -z "${dump:-}" ]]; then
    dump="$($PW_DUMP_CMD 2>/dev/null || true)"
  fi

  scr="$(
      printf '%s' "$dump" \
      | $JQ_BIN -e '
          [ .[]
            | select(.info?.props?)
            | select(
                (.info.props["media.name"]? // "")
                | test("^(xdph-streaming|gsr-default|game capture)")
            )
          ]
          | (if length > 0 then true else false end)
        ' >/dev/null && echo 1 || echo 0
    )"
fi

if [[ "$scr" -eq 1 ]]; then
    scr_app="$(
    printf '%s' "$dump" \
    |   $JQ_BIN -r '
        [ .[]
          | select(.type=="PipeWire:Interface:Node")
          | select((.info.props."media.class"=="Stream/Input/Video") or (.info.props."media.name"=="gsr-default_output") or (.info.props."media.name"=="game capture"))
          | select((.info.state=="running") or (.state=="running"))
          | .info.props["media.name"]
        ] | unique | join(", ")
      ' 2>/dev/null || echo ""
    )"
fi

# output
green="#30D158"
orange="#FF9F0A"
blue="#0A84FF"
purple="#9B32FA"

dot() {
  local on="$1" color="$2"
  if [[ "$on" -eq 1 ]]; then
    printf '<span foreground="%s">●</span>' "$color"
  else
    printf ''
  fi
}

dots=()
mic_dot="$(dot "$mic" "$green")"; [[ -n "$mic_dot" ]] && dots+=("$mic_dot")
cam_dot="$(dot "$cam" "$orange")"; [[ -n "$cam_dot" ]] && dots+=("$cam_dot")
loc_dot="$(dot "$loc" "$blue")"; [[ -n "$loc_dot" ]] && dots+=("$loc_dot")
scr_dot="$(dot "$scr" "$purple")"; [[ -n "$scr_dot" ]] && dots+=("$scr_dot")

text="${dots[*]}"

if [[ -n "$mic_app" ]]; then
  mic_status="Mic: $mic_app"
else
  mic_status="Mic: off"
fi

if [[ -n "$cam_app" ]]; then
  cam_status="Cam: $cam_app"
else
  cam_status="Cam: off"
fi

if [[ -n "$loc_app" ]]; then
  loc_status="Location: $loc_app"
else
  loc_status="Location: off"
fi

if [[ -n "$scr_app" ]]; then
  scr_status="Screen sharing: $scr_app"
else
  scr_status="Screen sharing: off"
fi

tooltip="$mic_status  |  $cam_status  |  $loc_status  |  $scr_status"

classes="privacydot"
[[ $mic -eq 1 ]] && classes="$classes mic-on" || classes="$classes mic-off"
[[ $cam -eq 1 ]] && classes="$classes cam-on" || classes="$classes cam-off"
[[ $loc -eq 1 ]] && classes="$classes loc-on" || classes="$classes loc-off"
[[ $scr -eq 1 ]] && classes="$classes scr-on" || classes="$classes scr-off"

jq -c -n --arg text "$text" --arg tooltip "$tooltip" --arg class "$classes" \
  '{text:$text, tooltip:$tooltip, class:$class}'
