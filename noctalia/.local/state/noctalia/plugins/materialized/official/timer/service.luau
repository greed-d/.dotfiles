--!nonstrict
-- Countdown timer service - the headless [[service]] entry.
--
-- The service owns the timer state and handles the countdown logic.
-- It publishes state changes to other entries via noctalia.state,
-- and listens for commands (START, PAUSE, RESET) from panel and bar.
--
--   noctalia.setUpdateInterval(ms)     set tick rate for countdown
--   noctalia.state.set(key, value)     publish state to other entries
--   noctalia.state.watch(key, fn)      react to commands from UI entries
--   noctalia.notify(title, body)       alert user when timer completes
--   noctalia.sound.load/play           optional repeating completion alarm

noctalia.setUpdateInterval(1000)

local function formatTime(seconds)
  local m = seconds // 60
  local s = seconds % 60
  if m >= 60 then
    return `{m // 60}:{string.format("%02d", m % 60)}:{string.format("%02d", s)}`
  end
  return `{m}:{string.format("%02d", s)}`
end

---- Initialize state
noctalia.state.set("timer.state", "IDLE") -- IDLE, NOTIFY, RUNNING, PAUSED
noctalia.state.set("timer.remaining", 0)
noctalia.state.set("timer.formattedTime", "0")
-- The countdown total captured when the timer starts, so UI entries can render
-- a progress bar (remaining / duration). Reset to 0 when the timer is cleared.
noctalia.state.set("timer.duration", 0)

noctalia.state.watch("timer.remaining", function (value)
  noctalia.state.set("timer.formattedTime", formatTime(value))
end)

local function resetTimer()
  noctalia.state.set("timer.remaining", 0)
  noctalia.state.set("timer.duration", 0)
  noctalia.state.set("timer.state", "IDLE")
end

-- Countdown state transitions, shared by the timer.cmd watcher (panel and bar
-- commands) and the IPC handler below.
local actions = {
  PAUSE = function()
    noctalia.state.set("timer.state", "PAUSED")
  end,
  START = function ()
    local remaining = noctalia.state.get("timer.remaining")
    local STATE = noctalia.state.get("timer.state")

    if (STATE == "IDLE" or STATE == "PAUSED") and remaining > 0 then
      -- Capture the total on a fresh start so progress bars have a baseline;
      -- leave it untouched when resuming from PAUSED.
      if STATE == "IDLE" then
        noctalia.state.set("timer.duration", remaining)
      end
      noctalia.state.set("timer.state", "RUNNING")
    end
  end,
  RESET = function ()
    resetTimer()
  end,
}

noctalia.state.watch("timer.cmd", function (cmd)
  local action = actions[cmd]
  if action then
    action()
  else
    noctalia.log(`Unknown command: {cmd}`)
  end

end)

-- Completion alarm: the tick replays the sound while NOTIFY for alarm_duration
-- seconds (0 silences it), then the timer returns to idle; the alarm bool keeps
-- it beeping in NOTIFY until dismissed.
local ALARM_SOUND = "alarm"
local alarmEnabled = noctalia.getConfig("alarm") == true
local alarmReady = false
local alarmDuration = noctalia.getConfig("alarm_duration") or 10
local notifyElapsed = 0

local function playAlarm()
  if alarmReady and (alarmEnabled or notifyElapsed < alarmDuration) then
    noctalia.sound.play(ALARM_SOUND)
  end
end

local function loadAlarm()
  if alarmReady or (not alarmEnabled and alarmDuration <= 0) then
    return
  end
  local accepted = noctalia.sound.load(ALARM_SOUND, "sounds/alarm.wav", function(ok, err)
    if ok then
      alarmReady = true
    else
      noctalia.log(`Timer alarm sound failed to load: {err}`)
    end
  end)
  if not accepted then
    noctalia.log("Timer alarm sound load was rejected")
  end
end

loadAlarm()

function onConfigChanged()
  alarmEnabled = noctalia.getConfig("alarm") == true
  alarmDuration = noctalia.getConfig("alarm_duration") or 10
  loadAlarm()
end

-- send notification and start the optional alarm when the timer completes
local function notifyUser()
  noctalia.notify(noctalia.tr("ui.notify_title"), noctalia.tr("ui.notify_body"))
end

function update()
  local STATE = noctalia.state.get("timer.state")
  local remaining = noctalia.state.get("timer.remaining")

  if STATE == "RUNNING" then
    if remaining > 0 then
      noctalia.state.set("timer.remaining", remaining - 1)
    else
      noctalia.state.set("timer.state", "NOTIFY")
      notifyUser()
      notifyElapsed = 0
      playAlarm()
    end

  elseif STATE == "NOTIFY" then
    notifyElapsed = notifyElapsed + 1
    playAlarm()
    if not alarmEnabled and notifyElapsed >= alarmDuration then
      resetTimer()
    end
  end
end

-- Begin a fresh countdown of the given duration, replacing whatever the timer
-- shows: an idle timer, a paused one (also refreshing the progress baseline so
-- bars do not divide by the old duration), or a ringing completion alarm,
-- which this dismisses on the way to the new countdown. Used by the IPC
-- handler only, which runs synchronously; queueing a timer.cmd event instead
-- would apply the transition through the mailbox, letting a second queued
-- call observe IDLE and bypass the running-timer guard.
local function startCountdown(seconds)
  notifyElapsed = 0
  noctalia.state.set("timer.remaining", seconds)
  noctalia.state.set("timer.duration", seconds)
  noctalia.state.set("timer.state", "RUNNING")
end

-- IPC entry point: noctalia msg plugin noctalia/timer:timer all <event> [payload].
--   start <minutes>   e.g. start 40 = 40:00; ignored while a countdown is running,
--                     so repeated calls (keybinds, shell aliases) cannot clobber
--                     a running timer. Otherwise it replaces the countdown with
--                     the new duration (while paused too, refreshing the progress
--                     baseline) and restarts out of the completion alarm.
--   pause             pause the countdown, or resume it when paused
--   cancel | reset    back to idle
function onIpc(event, payload)
  local STATE = noctalia.state.get("timer.state")
  if event == "start" then
    -- Applied synchronously; a queued START would let a second queued call
    -- observe IDLE and bypass the running-timer guard.
    local mins = tonumber(payload)
    local seconds = mins and math.floor(mins * 60)
    if seconds and seconds > 0 and seconds < math.huge and STATE ~= "RUNNING" then
      startCountdown(seconds)
    end
  elseif event == "pause" then
    if STATE == "RUNNING" then
      actions.PAUSE()
    elseif STATE == "PAUSED" then
      actions.START()
    end
  elseif event == "cancel" or event == "reset" then
    actions.RESET()
  end
end
