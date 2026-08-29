local timeFontFamily = noctalia.loadFont("JetBrainsMono-Regular.ttf")

local function formatTime(seconds, total)
  local showingHours = total >= 3600 or seconds >= 3600
  local hours = math.floor(seconds / 3600)
  local mins = math.floor((seconds % 3600) / 60)
  local secs = seconds % 60
  
  if showingHours then
    return string.format("%d:%02d:%02d", hours, mins, secs)
  else
    return string.format("%02d:%02d", mins, secs)
  end
end

function onStartButtonClick()
    noctalia.state.set("pomodoro.nextCommand", "toggle")
end

function onSkipButtonClick()
    noctalia.state.set("pomodoro.nextCommand", "skip")
end

function onResetButtonClick()
    noctalia.state.set("pomodoro.nextCommand", "reset")
end

function onResetAllButtonClick()
    noctalia.state.set("pomodoro.nextCommand", "resetAll")
end

local function render(state, sessionData)
    local sessionNumber = state.sessionPtr.session
    local session = sessionData[sessionNumber]
    local stageNumber = state.sessionPtr.stage
    local stageTotalSeconds = session[stageNumber]

    local stageName =
        if stageNumber == 1 then
            noctalia.tr("work")
        else if sessionNumber < #sessionData then 
            noctalia.tr("short-break")
        else 
            noctalia.tr("long-break")

    local startButtonText =
        if state.isRunning then
            noctalia.tr("button.pause")
        else if state.secondsLeft > 0 and state.secondsLeft < stageTotalSeconds then
            noctalia.tr("button.resume")
        else
            noctalia.tr("button.start")

    local startButtonGlyph = if state.isRunning then "player-pause" else "player-play"

    local skipButtonEnabled = state.isDirty and (if state.isRunning then state.secondsLeft > 0 else stageTotalSeconds > 0)

    local resetButtonEnabled = state.isDirty and state.secondsLeft > 0

    local resetAllButtonEnabled = state.isDirty and (state.isRunning or state.secondsLeft > 0 or (state.sessionPtr.session > 1 and state.sessionPtr.stage > 1))

    local stageIcon = if state.sessionPtr.stage == 1 then "brain" else "coffee"

    panel.render(
        ui.column({ flexGrow = 1, gap = 16 }, {
            -- header
            ui.row({ align = "center", gap = 8 }, {
                ui.glyph({ name = stageIcon, color = "primary" }),

                ui.label({
                    text = "Pomodoro",
                    fontSize = 18,
                    fontWeight = "bold",
                    color = "on_surface",
                    flexGrow = 1,
                }),

                ui.label({
                    text = string.format("%s %d/%d", noctalia.tr("session"), sessionNumber, #sessionData),
                    fontSize = 12,
                    color = "on_surface_variant",
                }),
            }),

            -- time
            ui.column({ flexGrow = 1, align = "center", justify = "center", }, {
                ui.label({
                    text = stageName,
                    fontSize = 18,
                    fontWeight = "medium",
                    color = "primary",
                }),

                ui.label({
                    text = formatTime(state.secondsLeft, stageTotalSeconds),
                    fontSize = 42,
                    fontWeight = "bold",
                    fontFamily = timeFontFamily,
                    color = "primary",
                }),
            }),

            -- buttons
            ui.column({ gap = 8 }, {
                ui.row({ gap = 8 }, {
                    ui.button({
                        variant = "primary",
                        text = startButtonText,
                        glyph = startButtonGlyph,
                        onClick = "onStartButtonClick",
                        width = 157,
                        height = 35
                    }),

                    ui.button({
                        text = noctalia.tr("button.skip"),
                        glyph = "player-skip-forward",
                        onClick = "onSkipButtonClick",
                        enabled = skipButtonEnabled,
                        width = 157,
                        height = 35
                    }),
                }),

                ui.row({ gap = 8 }, {
                    ui.button({
                        text = noctalia.tr("button.reset"),
                        glyph = "refresh",
                        onClick = "onResetButtonClick",
                        enabled = resetButtonEnabled,
                        width = 157,
                        height = 35
                    }),

                    ui.button({
                        text = noctalia.tr("button.reset-all"),
                        glyph = "rotate",
                        onClick = "onResetAllButtonClick",
                        enabled = resetAllButtonEnabled,
                        width = 157,
                        height = 35
                    }),
                }),
            }),
        }) -- column
    ) -- panel
end

function onOpen(context)
    local state = noctalia.state.get("pomodoro.state")
    local sessionData = noctalia.state.get("pomodoro.sessionData")
    render(state, sessionData)
end

--- main
noctalia.state.watch("pomodoro.state", function(state)
    local config = noctalia.state.get("pomodoro.config")
    local sessionData = noctalia.state.get("pomodoro.sessionData")

    if state.secondsLeft == 0 then
        noctalia.state.set("pomodoro.nextCommand", "skip")
        if (config.autoStartWork and state.sessionPtr.stage == 2) or (config.autoStartBreaks and state.sessionPtr.stage == 1) then
            noctalia.state.set("pomodoro.nextCommand", "toggle")
        end
    end

    render(state, sessionData)
end)
