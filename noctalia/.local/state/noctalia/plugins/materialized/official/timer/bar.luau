--!nonstrict
-- Timer bar widget — the [[widget]] entry for the status bar.
--
-- The bar widget displays the timer's current state: an hourglass
-- icon when idle, or the formatted countdown when running. Click
-- the widget to open the panel for duration input and controls.
--
--   barWidget.render(tree)             declarative UI tree
--   barWidget.isVertical()             branch on bar orientation
--   noctalia.getConfig(key)            per-placement widget settings
--   noctalia.togglePanel(id)           open/close the timer panel

local STATE = "IDLE"
local formattedTime = "00:00"
local isVertical = false

local Tooltip = {
  hasTooltip = false,
}

function Tooltip.show()
  barWidget.setTooltip(formattedTime)
  Tooltip.hasTooltip = true
end

function Tooltip.hide()
  -- trying to clear a tooltip when there is none is crashing the plugin
  if Tooltip.hasTooltip then
    barWidget.clearTooltip()
    Tooltip.hasTooltip = false
  end
end

local HOURGLASS_COLORS = {
  IDLE = "on_surface",
  RUNNING = "primary",
  NOTIFY = "error",
}

local function getHourglassColor()
  return HOURGLASS_COLORS[STATE] or HOURGLASS_COLORS.IDLE
end

local function render()
  local showCounterWhenIdle = noctalia.getConfig("show_idle_on_horizontal")
  local hourGlassColor = getHourglassColor()

  if isVertical then
      barWidget.render(ui.column({ align = "center" }, {
        ui.glyph({ name = "hourglass", color = hourGlassColor }),
      }))

      if STATE == "RUNNING" then
        Tooltip.show()
      end
  else
    -- Idle state: timer at zero, just show hourglass icon when showCounterWhenIdle in widget settings was set false
    if STATE == "IDLE" and showCounterWhenIdle == false then
      barWidget.render(ui.row({ align = "center" }, {
        ui.glyph({ name = "hourglass", color = hourGlassColor }),
      }))
      return
    end

    -- Running or paused with time remaining
    barWidget.render(ui.row({ gap = 6, align = "center" }, {
      ui.glyph({ name = "hourglass", color = hourGlassColor }),
      ui.label({ text = formattedTime, fontWeight = "bold", color = hourGlassColor }),
    }))
  end
end

-- update needed for initial load
function update()
  isVertical = barWidget.isVertical()
  render()
end

noctalia.state.watch("timer.state", function(value)
  -- if state was RUNNING and is updated to something else,
  -- we disable the tooltip
  if isVertical and STATE == "RUNNING" and value ~= "RUNNING" then
    Tooltip.hide()
  end

  STATE = value
  render()
end)

noctalia.state.watch("timer.formattedTime", function(value)
  formattedTime = value
  if STATE == "RUNNING" then
    render()
  end
end)

function onClick()
  if STATE == "NOTIFY" then
    -- click on the bar when timer is done should stop NOTIFY state and
    -- should not open the panel. the user most likely don't want to set another timer
    noctalia.state.set("timer.cmd", "RESET")
    return
  end
  noctalia.togglePanel("noctalia/timer:panel")
end
