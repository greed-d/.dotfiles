--!nonstrict
-- Screen Toolkit — control-center [[shortcut]] tile.
--
-- Mirrors the bar widget: shows the recording state and toggles the main
-- panel. Drives the [[service]] through the "command"
-- state channel — no shell-out, no IPC PATH dependency.

local recording = false

local function apply()
  shortcut.setLabel(recording and noctalia.tr("shortcut.recording") or noctalia.tr("shortcut.label"))
  shortcut.setIcon("crosshair", "crosshair")
  shortcut.setActive(recording)
end

noctalia.state.watch("recording", function(value)
  recording = value == true
  apply()
end)

function onClick()
  -- The shortcut tile never stops a recording; it just opens the panel so
  -- the stop button (in the panel header, next to the close X) is reachable.
  local mode = noctalia.getConfig("panel-mode")
  local id = (mode == "legacy") and "alexander/screen-toolkit:panel-legacy" or "alexander/screen-toolkit:panel"
  noctalia.togglePanel(id)
end

apply()
