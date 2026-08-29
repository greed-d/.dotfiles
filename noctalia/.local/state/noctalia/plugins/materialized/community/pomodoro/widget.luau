local isVertical = barWidget.isVertical()
local hasResetAllBeenCalled = true

function onClick()
    noctalia.togglePanel("thepunkoff/pomodoro:panel")
end

local function render(state)
    local color = if state.isRunning then "primary" else "on_surface"
    local name =
        if hasResetAllBeenCalled then 
            noctalia.getConfig("widget-glyph-main")
        else
            if state.sessionPtr.stage == 1 then
                noctalia.getConfig("widget-glyph-work")
            else noctalia.getConfig("widget-glyph-break")

    local content = { ui.glyph ({ color = color, name = name }) }

    local hours = math.floor(state.secondsLeft / 3600)
    local mins = math.floor((state.secondsLeft % 3600) / 60)
    local secs = state.secondsLeft % 60

    local labelTime =
        if not isVertical then
            if hours == 0 then
                string.format("%02d:%02d", mins, secs)
            else
                string.format("%d:%02d:%02d", hours, mins, secs)
        else
            if hours == 0 then
                string.format("%02d\n%02d", mins, secs)
            else
                string.format("%02d\n%02d\n%02d", hours, mins, secs)

    if not hasResetAllBeenCalled then
        table.insert(content, ui.label({
            text = labelTime,
            textAlign = "center",
            color = color
        }))
    end

    local container = if isVertical then ui.column else ui.row
    barWidget.render(container({ gap = 4, align = "center", justify = "center" }, content))
end

--- main
render(noctalia.state.get("pomodoro.state"))

noctalia.state.watch("pomodoro.nextCommand", function(command)
    if command == "toggle" then
        hasResetAllBeenCalled = false
    elseif command == "resetAll" then
        hasResetAllBeenCalled = true
        render(noctalia.state.get("pomodoro.state"))
    end
end)

noctalia.state.watch("pomodoro.state", function(state)
    render(state)
end)
