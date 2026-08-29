--!nonstrict
-- GPU Screen Recorder — control-center quick tile.
--
-- This tile holds no recording logic of its own. It mirrors the recorder widget
-- through the plugin's shared state:
--   reads  noctalia.state "status"  -> { state = ..., available = ... }
--   writes noctalia.state "command" -> "toggle" / "replay-toggle"
--
-- The recorder widget must be placed on a bar — it owns the recording process
-- and reacts to the command channel.

local recording = false
local replaying = false
local available = false
local RECORDING_STATES = { "recording", "pending" }
local REPLAY_STATES = { "replaying", "replay_pending" }

local function applyStatus(status)
    local hasStatus = type(status) == "table"
    local st = if hasStatus then status.state or "idle" else "idle"
    available = if hasStatus and status.available then true else false
    recording = table.find(RECORDING_STATES, st) ~= nil
    replaying = table.find(REPLAY_STATES, st) ~= nil

    shortcut.setLabel(
        if recording then noctalia.tr("shortcut.recording")
        elseif replaying then noctalia.tr("shortcut.replay-buffer")
        else noctalia.tr("shortcut.record-screen")
    )
    shortcut.setIcon("video", "video-off")
    shortcut.setActive(recording or replaying)
    shortcut.setEnabled(available)
end

-- Reflect whatever the recorder last published, then track live changes.
applyStatus(noctalia.state.get("status"))
noctalia.state.watch("status", applyStatus)

function onClick()
    noctalia.state.set("command", { action = "toggle", focusedOutputName = noctalia.focusedOutputName() })
end

function onRightClick()
    noctalia.state.set("command", { action = "replay-toggle", focusedOutputName = noctalia.focusedOutputName() })
end
