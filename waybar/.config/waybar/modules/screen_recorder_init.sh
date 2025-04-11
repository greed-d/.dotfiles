#!/bin/bash

if ps aux | grep -v grep | grep wf-recorder >/dev/null; then
  echo "{\"text\": \"  Recording\", \"tooltip\": \"GPU Screen Recorder is running\", \"class\": \"recording\"}"
else
  echo "{\"text\": \"  Not Recording\", \"tooltip\": \"GPU Screen Recorder is not running\", \"class\": \"not-recording\"}"
fi
