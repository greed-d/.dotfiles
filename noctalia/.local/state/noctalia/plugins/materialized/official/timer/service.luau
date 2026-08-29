--!nonstrict
-- Countdown timer service — the headless [[service]] entry.
--
-- The service owns the timer state and handles the countdown logic.
-- It publishes state changes to other entries via noctalia.state,
-- and listens for commands (START, PAUSE, RESET) from panel and bar.
--
--   noctalia.setUpdateInterval(ms)     set tick rate for countdown
--   noctalia.state.set(key, value)     publish state to other entries
--   noctalia.state.watch(key, fn)      react to commands from UI entries
--   noctalia.notify(title, body)       alert user when timer completes

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

noctalia.state.watch("timer.cmd", function(cmd)

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
      noctalia.state.set("timer.remaining", 0)
      noctalia.state.set("timer.duration", 0)
      noctalia.state.set("timer.state", "IDLE")
    end
  }


  local action = actions[cmd]
  if action then
    action()
  else
    noctalia.log(`Unknown command: {cmd}`)
  end

end)

-- send notification and sound when implemented
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
    end

  end
end
