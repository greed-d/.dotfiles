--!nonstrict
-- GPU Screen Recorder - bar widget (thin presentation client).
--
-- The recording logic lives in the [[service]] (recorder_service.luau), which runs
-- for the whole session. This widget only reflects the published "status" and
-- drives the recorder by writing to the "command" channel.
--
-- Click mapping:
--   Left click   - start/stop recording
--   Right click  - toggle replay buffer, or save replay (when one is running)
--   Middle click - save replay buffer

local state = "idle" -- idle | pending | recording | replay_pending | replaying
local available = false
local RECORDING_STATES = { "recording", "pending" }
local PENDING_STATES = { "pending", "replay_pending" }

local function send(action)
    noctalia.state.set("command", { action = action, focusedOutputName = noctalia.focusedOutputName() })
end

-- Glyph per state, configurable. The fallback passed to each lookup is the
-- value this widget used before the settings existed, so an unset or blank
-- glyph keeps the previous appearance.
local function glyphFor(key, fallback)
    local configured = noctalia.getConfig(key)
    if type(configured) == "string" and configured ~= "" then
        return configured
    end
    return fallback
end

local function applyStatus(status)
    if type(status) == "table" then
        state = status.state or "idle"
        available = if status.available then true else false
    end

    local hideInactive = noctalia.getConfig("hide_inactive")

    if not available then
        barWidget.setGlyph(glyphFor("glyph_unavailable", "video-off"))
        barWidget.setGlyphColor("on_surface_variant")
        barWidget.setVisible(not hideInactive)
        return
    end

    if state == "recording" then
        barWidget.setGlyph(glyphFor("glyph_recording", "video"))
        barWidget.setGlyphColor("error")
        barWidget.setColor("error")
        barWidget.setVisible(true)
    elseif table.find(PENDING_STATES, state) then
        barWidget.setGlyph(glyphFor("glyph_pending", "video"))
        barWidget.setGlyphColor("primary")
        barWidget.setColor("primary")
        barWidget.setVisible(true)
    elseif state == "replaying" then
        barWidget.setGlyph(glyphFor("glyph_replaying", "repeat"))
        barWidget.setGlyphColor("secondary")
        barWidget.setColor("secondary")
        barWidget.setVisible(true)
    else
        barWidget.setGlyph(glyphFor("glyph_idle", "video"))
        barWidget.setGlyphColor("on_surface")
        barWidget.setVisible(not hideInactive)
    end
end

function onClick()
    if not available then return end
    if table.find(RECORDING_STATES, state) then
        send("stop")
    elseif state == "idle" then
        send("start")
    end
end

function onRightClick()
    if not available then return end
    if state == "replaying" then
        send("replay-save")
    elseif state == "idle" and noctalia.getConfig("replay_enabled") then
        send("replay-start")
    elseif state == "replay_pending" then
        send("replay-stop")
    end
end

function onMiddleClick()
    if state == "replaying" then
        send("replay-save")
    end
end

-- Sync the current status on load, then track changes.
applyStatus(noctalia.state.get("status"))
noctalia.state.watch("status", applyStatus)
