local config = (function()
    return {
        workDuration = noctalia.getConfig("work-duration"),
        shortBreakDuration = noctalia.getConfig("short-break-duration"),
        longBreakDuration = noctalia.getConfig("long-break-duration"),
        sessionsBeforeLongBreak = noctalia.getConfig("sessions-before-long-break"),
        autoStartBreaks = noctalia.getConfig("auto-start-breaks"),
        autoStartWork = noctalia.getConfig("auto-start-work"),
        useBundledAlarmSound = noctalia.getConfig("use-bundled-alarm-sound"),
        bypassNoctaliaSoundGlobals = noctalia.getConfig("bypass-noctalia-sound-globals"),
    }
end)()
noctalia.state.set("pomodoro.config", config)

local function onAlarmSoundLoaded(ok, err)
    if not ok then
        noctalia.notifyError("Couldn't load alarm sound", err)
    end
end
local soundAccepted = noctalia.sound.load("alarm", "alarm.mp3", onAlarmSoundLoaded)
if not soundAccepted then
    noctalia.notifyError("Couldn't queue alarm sound")
end

local sessionData = {}
for i = 1, config.sessionsBeforeLongBreak do
    breakDuration = if i < config.sessionsBeforeLongBreak then config.shortBreakDuration else config.longBreakDuration
    table.insert(sessionData, { config.workDuration * 60, breakDuration * 60 })
end
noctalia.state.set("pomodoro.sessionData", sessionData)

local isRunning = false
local sessionPtr = { session = 1, stage = 1 }
local isDirty = false
local secondsLeft = 0

local function getStateSnapshot()
    return {
        isRunning = isRunning,
        secondsLeft = secondsLeft,
        sessionPtr = sessionPtr,
        isDirty = isDirty,
    }
end

local function getStageTotalSeconds()
    local sessionNumber = sessionPtr.session
    local session = sessionData[sessionNumber]
    local stageNumber = sessionPtr.stage
    return session[stageNumber]
end

--- main
secondsLeft = getStageTotalSeconds()

noctalia.state.watch("pomodoro.nextCommand", function(command)
    if command == "toggle" then
        isDirty = true
        isRunning = not isRunning
    elseif command == "skip" then
        isRunning = false
        if sessionPtr.stage == 1 then
            sessionPtr.stage = 2
        elseif sessionPtr.session < #sessionData then
            sessionPtr.session += 1
            sessionPtr.stage = 1
        elseif sessionPtr.session == #sessionData then
            sessionPtr = { session = 1, stage = 1 }
        end
        secondsLeft = getStageTotalSeconds()
    elseif command == "reset" then
        isRunning = false
        secondsLeft = getStageTotalSeconds()
    elseif command == "resetAll" then
        isRunning = false
        sessionPtr = { session = 1, stage = 1 }
        secondsLeft = getStageTotalSeconds()
        isDirty = false
    end

    local state = getStateSnapshot()
    noctalia.state.set("pomodoro.state", state)
end)

local state = getStateSnapshot()
noctalia.state.set("pomodoro.state", state)

noctalia.setUpdateInterval(1000)
function update()
    if isRunning then
        secondsLeft -= 1
        local state = getStateSnapshot()
        noctalia.state.set("pomodoro.state", state)
    end
end

local function notifyStageFinished(state, sessionData)
    local sessionNumber = state.sessionPtr.session
    local stageNumber = state.sessionPtr.stage
    local body =
        if stageNumber == 1 then
            noctalia.tr("notification.work-complete")
        elseif sessionNumber < #sessionData then
            noctalia.tr("notification.short-break-complete")
        else
            noctalia.tr("notification.long-break-complete")

    if config.useBundledAlarmSound then
        if config.bypassNoctaliaSoundGlobals then
            local pluginDir = noctalia.pluginDir()
            if pluginDir then
                local alarmDir = pluginDir .. "/alarm.mp3"
                noctalia.runAsync("pw-play " .. alarmDir)
            end
        else
            noctalia.sound.play("alarm")
        end
    end

    noctalia.notify("Pomodoro Timer", body)
end

noctalia.state.watch("pomodoro.state", function(state)
    if state.secondsLeft == 0 then
        notifyStageFinished(state, sessionData)
    end
end)
