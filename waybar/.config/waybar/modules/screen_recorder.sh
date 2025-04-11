#!/bin/sh

action=$1

case "$action" in
stop)
  pkill -f wf-recorder
  notify-send "Screen Recorder" "Recording stopped."
  ;;
restart)
  sh ~/.config/hypr/scripts/gpu_recorder.sh
  ;;
save)
  killall -SIGUSR1 gpu-screen-recorder
  notify-send "Screen Recorder" "Recording saved."
  ;;
*)
  echo "Unknown action. Please use 'stop', 'restart', or 'save'."
  exit 1
  ;;
esac
