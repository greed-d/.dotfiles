--!nonstrict
-- Screen Toolkit — bar [[widget]].
--
-- Crosshair glyph; a pulsing red dot appears while a recording is active.
-- Left click toggles the main panel; right click quick-picks a color.
-- Recording logic lives in the [[service]] — this widget
-- only reflects the published state and drives the service through the
-- "command" state channel.
-- When "hide-when-unused" is enabled, the widget is hidden until a
-- recording starts (issue #444).

local recording = noctalia.state.get("recording") == true
local hideWhenUnused = noctalia.getConfig("hide-when-unused") == true
local phase = 0
local startedAt = noctalia.state.get("recordStartedAt")

local function elapsed()
  if not startedAt then return "00:00" end
  local seconds = math.max(0, os.time() - startedAt)
  return string.format("%02d:%02d", math.floor(seconds / 60), seconds % 60)
end

local function render()
  if hideWhenUnused and not recording then
    barWidget.setVisible(false)
    return
  end
  barWidget.setVisible(true)

  local container = barWidget.isVertical() and ui.column or ui.row
  local children = {}
  if recording then
    table.insert(children, ui.box({
      key = "rec-dot",
      width = 7,
      height = 7,
      radius = 4,
      fill = (phase % 2 == 0) and "error" or "error/0.35",
    }))
    table.insert(children, ui.label({ text = `REC {elapsed()}`, fontSize = 11, fontWeight = "bold", color = "error" }))
  end
  table.insert(children, ui.glyph({ name = "crosshair", size = 14 }))
  barWidget.render(container({ gap = 6, align = "center" }, children))
  barWidget.setTooltip(recording and noctalia.tr("widget.recording") or noctalia.tr("widget.tooltip"))
end

-- Pulse the dot: the bar has no frame ticks, so re-render on a half-second cadence.
function update()
  noctalia.setUpdateInterval(500)
  phase += 1
  render()
end

noctalia.state.watch("recording", function(value)
  recording = value == true
  startedAt = noctalia.state.get("recordStartedAt")
  render()
end)
noctalia.state.watch("recordStartedAt", function(value)
  startedAt = value
  render()
end)

function onConfigChanged()
  hideWhenUnused = noctalia.getConfig("hide-when-unused") == true
  render()
end

function onClick()
  -- The bar icon never stops a recording; it just opens the panel so the
  -- stop button (in the panel header, next to the close X) is reachable.
  local mode = noctalia.getConfig("panel-mode")
  local id = (mode == "legacy") and "alexander/screen-toolkit:panel-legacy" or "alexander/screen-toolkit:panel"
  noctalia.togglePanel(id)
end

function onRightClick()
  -- Quick pick: copies the color and notifies, but never toggles the panel.
  noctalia.state.set("command", { action = "colorPicker", payload = { reopen = false } })
end

render()
