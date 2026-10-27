--!nonstrict
-- GPU Screen Recorder - headless service.
-- Owns all recording / replay-buffer logic and runs for the whole session, so a
-- recording can be started from the control-center shortcut with no bar widget
-- placed. The widget and shortcut are thin clients: they read the published
-- "status" and drive the recorder by writing to the "command" channel.
--
-- Settings come from the plugin's root-level [[setting]] block, seeded into
-- noctalia.getConfig and shared by every entry of the plugin.

noctalia.setUpdateInterval(250)

local CHECK_TICKS = 8 -- 8 * 250ms = 2s between process checks
local PENDING_TICKS = 8

local state = "idle" -- idle | pending | recording | replay_pending | replaying
local RECORDING_STATES = { "recording", "pending" }
local REPLAY_STATES = { "replaying", "replay_pending" }
local outputPath = ""
local isAvailable = false
local tickCount = 0
-- tickCount when the current start began; the pending verdict waits a full
-- check interval from here, so a process check already in flight at start
-- (or the next periodic one, up to 2s away) cannot decide on its own.
local pendingSince = 0
local checkedAvailability = false
local processCheckPending = false
local stateGeneration = 0
local regionGeometry = nil
local pickInProcess = false
local updateDisplay
local lastStatusKey

-- ── Helpers ──────────────────────────────────────────────────────────────

local function cfg(key)
    return noctalia.getConfig(key)
end

local function log(msg)
    noctalia.log(`screen_recorder: {msg}`)
end

local function scaledVideoQp(codec, qp)
    return qp * (if codec == "vp8" then 2 elseif codec == "av1" or codec == "vp9" then 4 else 1)
end

local function buildVideoBitrateFlags(codec)
    local mode = cfg("video_bitrate_mode")
    if mode == "qp" then
        local qp = scaledVideoQp(codec, cfg("video_qp"))
        return `-bm qp -ffmpeg-video-opts qp={qp}`
    end

    if mode == "vbr" then
        return `-bm vbr -q {cfg("video_quality")}`
    end

    if mode == "cbr" then
        local bitrate = tonumber(cfg("video_bitrate"))
        if not bitrate or bitrate <= 0 or bitrate ~= math.floor(bitrate) then
            log(`invalid video bitrate: {cfg("video_bitrate")}`)
            return nil
        end
        return `-bm cbr -q {bitrate}`
    end
    return ""
end

-- Where gpu-screen-recorder's own stdout/stderr is captured so its failure reason
-- can be echoed back through noctalia.log (the process is detached, so this file is
-- the only way to see why it never started or died early).
local function gsrLogPath()
    local base = noctalia.getenv("XDG_STATE_HOME")
    if base == nil or base == "" then
        base = "~/.local/state"
    end
    return noctalia.expandPath(`{base}/noctalia/screen_recorder`)
end

local logDir = gsrLogPath()
local logFile = `{logDir}/gpu-screen-recorder.log`
noctalia.mkdirAll(logDir)

-- Read the tail of the capture file and echo it, line by line, through noctalia.log.
local function logGsrTail(reason)
    local contents = noctalia.readFile(logFile)
    if contents == nil or contents == "" then
        log(`{reason}; no gpu-screen-recorder output was captured`)
        return
    end
    if #contents > 1500 then
        contents = contents:sub(-1500)
    end
    log(`{reason}; last gpu-screen-recorder output:`)
    for line in contents:gmatch("[^\n]+") do
        log(`  {line}`)
    end
end

-- Portal target selection cancelled by user shouldn't be a failure.
-- Exits silently to idle with no error popup and writes a "cancelled by the user" line to logFile.
local function portalCaptureCancelled()
    local contents = noctalia.readFile(logFile)
    if contents == nil or contents == "" then return false end
    return contents:find("canceled by the user", 1, true) ~= nil
     or contents:find("cancelled by the user", 1, true) ~= nil
end

-- Publish the recorder's status so the widget and shortcut can mirror it.
local function publishStatus()
    local key = `{state}/{if isAvailable then "1" else "0"}`
    if key == lastStatusKey then return end
    lastStatusKey = key
    noctalia.state.set("status", { state = state, available = isAvailable })
end

local function setState(nextState)
    if state == nextState then return end
    state = nextState
    stateGeneration += 1
    if nextState == "idle" then
        regionGeometry = nil
    end
end

local function detectProcessStateAsync(callback)
    local pending = 6
    local isReplaying = false
    local isRecording = false

    local function finish(kind, matched)
        if matched then
            if kind == "replaying" then
                isReplaying = true
            elseif kind == "recording" then
                isRecording = true
            end
        end

        pending -= 1
        if pending > 0 then return end

        callback(if isReplaying then "replaying" elseif isRecording then "recording" else nil)
    end

    local function queue(kind, name, token)
        local ok = noctalia.processMatches(function(matched)
            finish(kind, matched)
        end, name, token)
        if not ok then
            finish(kind, false)
        end
    end

    queue("replaying", "gpu-screen-recorder", " -r ")
    queue("replaying", "com.dec05eba.gpu_screen_recorder", " -r ")
    queue("recording", "gpu-screen-recorder", " -w ")
    queue("recording", "com.dec05eba.gpu_screen_recorder", " -w ")
    queue("recording", "gpu-screen-recorder", " -o ")
    queue("recording", "com.dec05eba.gpu_screen_recorder", " -o ")
end

local function flatpakGsrInstalled()
    if not noctalia.flatpakAppInstalled then
        return nil
    end
    return noctalia.flatpakAppInstalled("com.dec05eba.gpu_screen_recorder")
end

local function checkAvailability()
    if noctalia.commandExists("gpu-screen-recorder") then
        log("gpu-screen-recorder found (native)")
        return true
    end
    if noctalia.commandExists("flatpak") and flatpakGsrInstalled() == true then
        log("gpu-screen-recorder found (flatpak com.dec05eba.gpu_screen_recorder)")
        return true
    end
    log("gpu-screen-recorder NOT found (native or flatpak); recorder unavailable")
    return false
end

local function copyToClipboard(path)
    local escapedPath = path:gsub(" ", "%%20"):gsub("'", "%%27"):gsub('"', "%%22")
    local uri = `file://{escapedPath}`
    noctalia.copyToClipboard(uri, "text/uri-list")
end

local function shellQuote(value)
    return "'" .. value:gsub("'", [["'"']]) .. "'"
end

-- Match the executable at the start of argv, including absolute native, Nix and
-- Flatpak paths. Anchoring also keeps the signal command from matching its shell.
local function signalRecorder(signal, replayOnly, forceAfterDelay)
    local pattern = "^([^ ]*/)?(gpu-screen-recorder|com[.]dec05eba[.]gpu_screen_recorder)"
        .. (if replayOnly then " (.* )?-r " else "( |$)")

    local cmd = `pids=$(pgrep -f -- {shellQuote(pattern)}) || exit 0\nkill -s {signal} $pids 2>/dev/null || true`
    if forceAfterDelay then
        -- Snapshot before stopping: a capture started during the grace period
        -- must not be killed by a later command-line match.
        cmd ..= "\nsleep 3\nkill -s KILL $pids 2>/dev/null || true"
    end
    noctalia.runAsync(cmd)
end

-- notifyIfMissing: when the recorder ended on its own (not a user stop) and no
-- output file exists, gpu-screen-recorder died early - surface its captured output.
local function notifyRecordingSavedIfPresent(notifyIfMissing)
    local savedPath = outputPath
    if savedPath == "" then return end

    noctalia.runAsync(`sleep 0.5; test -s {shellQuote(savedPath)}`, function(result)
        if result.exitCode ~= 0 then
            if notifyIfMissing then
                if portalCaptureCancelled() then
                    log("target selection cancelled by user, no output file, return to idle")
                    return
                end
                logGsrTail("recording stopped early with no output file")
                noctalia.notifyError(noctalia.tr("notify.recording-failed"), noctalia.tr("notify.recording-stopped-early"))
            end
            return
        end

        log(`recording saved: {savedPath}`)
        noctalia.notify(noctalia.tr("notify.recording-saved"), savedPath)
        if cfg("copy_to_clipboard") then
            copyToClipboard(savedPath)
        end
    end)
end

-- ── Command builders ─────────────────────────────────────────────────────

local function buildAudioFlags()
    local source = cfg("audio_source")
    local codec = cfg("audio_codec")
    if source == "none" then return "" end

    -- 0 = automatic: omit -ab so gpu-screen-recorder uses its own per-codec default.
    local bitrate = cfg("audio_bitrate")
    local bitrateFlag = if type(bitrate) == "number" and bitrate > 0 then `-ab {bitrate}` else ""

    if source == "both" then
        return `-ac {codec} {bitrateFlag} -a "default_output|default_input"`
    end

    if source == "custom" then
        local sources = cfg("custom_audio_sources")
        if sources == "" then return "" end

        local flags = {}
        for src in sources:gmatch("([^,]+)") do
            src = noctalia.string.trim(src)
            table.insert(flags, `-a {shellQuote(src)}`)
        end

        if #flags == 0 then return "" end
        return `-ac {codec} {bitrateFlag} {table.concat(flags, " ")}`
    end

    return `-ac {codec} {bitrateFlag} -a {source}`
end

local function buildResolutionFlag()
    local res = cfg("resolution")
    return if res ~= "original" then `-s {res}` else ""
end

local function buildSaveScriptFlag()
    local script = cfg("post_save_script")
    if script == "" then return "" end

    script = noctalia.expandPath(script)
    if not noctalia.fileExists(script) then
        log(`post-save script not found: {script}`)
        return ""
    end

    return `-sc {shellQuote(script)}`
end

-- "cpu" forces the software encoder (h264-only), anything else keeps hardware encoding.
local function buildEncoderFlag()
    return if cfg("video_encoder") == "cpu" then "-encoder cpu" else ""
end

-- Capture modes a caller may request. An IPC override outside this set is
-- discarded so an arbitrary payload can never reach the gpu-screen-recorder
-- command line.
local VIDEO_SOURCES = { focused = true, portal = true, region = true }

local function selectedVideoSource(sourceOverride)
    if sourceOverride ~= nil and VIDEO_SOURCES[sourceOverride] then
        return sourceOverride
    end

    local configured = cfg("video_source")
    return if VIDEO_SOURCES[configured] then configured else "portal"
end

local function resolveVideoSource(errorTitle, focusedOutputName, sourceOverride)
    local source = selectedVideoSource(sourceOverride)
    if source ~= "focused" then
        return source
    end

    local monitor = focusedOutputName
    if monitor == nil or monitor == "" then
        log("no focused monitor to capture (video_source=focused)")
        noctalia.notifyError(errorTitle, noctalia.tr("notify.no-monitor"))
        return nil
    end

    return monitor
end

-- Region Picker --------------------------------------------------------------------

local function pickRegionAsync(errorTitle, callback)
    if not noctalia.commandExists("slurp") then
      log("region capture: slurp not found")
      noctalia.notifyError(errorTitle, noctalia.tr("notify.region-picker-missing"))
      callback(nil)
      return
    end

    local cmd = [[slurp -f "%wx%h+%x+%y"]]
    log(`region capture: picking area ({cmd})`)
    local ok = noctalia.runAsync(cmd, function(result)
      local geo = noctalia.string.trim(result.stdout or "")
      if result.exitCode ~= 0 or not geo:match("^%d+x%d+%+%-?%d+%+%-?%d+$") then
        log("region capture: picker cancelled or return no geometry")
        callback(nil)
        return
      end
      log(`region capture: picked {geo}`)
      callback(geo)
    end)
    if not ok then callback(nil) end
end

-- Pick a region then run `proceed` with regionGeometry set, guards reentry
local function pickRegionThen(errorTitle, proceed)
    pickInProcess = true
    pickRegionAsync(errorTitle, function(geo)
        pickInProcess = false
        if state ~= "idle" or geo == nil then return end
        regionGeometry = geo
        proceed()
    end)
end

local function buildGsrPrefix()
    return [[
_gpuscreenrecorder_flatpak_installed() {
  flatpak list --app 2>/dev/null | grep -q "com.dec05eba.gpu_screen_recorder"
}
if command -v gpu-screen-recorder >/dev/null 2>&1; then
  gpu-screen-recorder]]
end

local function outputDirectory()
    local configured = cfg("directory")
    local dir = if configured == "" then noctalia.expandPath("~/Videos/Recordings") else noctalia.expandPath(configured)
    if dir:sub(-1) ~= "/" then
        dir ..= "/"
    end
    return dir
end

local function buildGsrSuffix()
    return [[

elif command -v flatpak >/dev/null 2>&1 && _gpuscreenrecorder_flatpak_installed; then
  flatpak run --command=gpu-screen-recorder com.dec05eba.gpu_screen_recorder]]
end

local function buildRecordCommand(focusedOutputName, sourceOverride)
    local source = resolveVideoSource(noctalia.tr("notify.recording-failed"), focusedOutputName, sourceOverride)
    if source == nil then return nil end

    local dir = outputDirectory()

    local pattern = cfg("filename_pattern")
    local filename = `{noctalia.formatTime(pattern)}.mp4`
    outputPath = `{dir}{filename}`

    local fm = cfg("frame_rate_mode")
    local fps = cfg("frame_rate")
    local codec = cfg("video_codec")
    if cfg("video_encoder") == "cpu" and codec ~= "h264" then
        log(`cpu encoder forces h264 (configured {codec})`)
        codec = "h264"
    end

    local bitrateFlags = buildVideoBitrateFlags(codec)
    if bitrateFlags == nil then return nil end

    local cursor = if cfg("show_cursor") then "yes" else "no"
    local cr = cfg("color_range")
    local restore = if cfg("restore_portal") then "-restore-portal-session yes" else ""
    local audioFlags = buildAudioFlags()
    local resFlag = buildResolutionFlag()
    local encoderFlag = buildEncoderFlag()
    local scriptFlag = buildSaveScriptFlag()

    local regionFlag = if source == "region" and regionGeometry ~= nil then `-region {regionGeometry}` else ""
    local flags = `-w {source} {regionFlag} -fm {fm} -f {fps} -k {codec} {encoderFlag} {audioFlags} {bitrateFlags} -cursor {cursor} -cr {cr} {resFlag} {scriptFlag} {restore} -v no -o "{outputPath}"`

    log(`starting recording: mode={selectedVideoSource(sourceOverride)} target={source} output={outputPath} flags=[{flags}]`)

    local header = `printf '=== gpu-screen-recorder recording %s ===\n' "$(date '+%Y-%m-%d %H:%M:%S')" > "{logFile}"`
    flags ..= ` >> "{logFile}" 2>&1`

    return `{header}\n{buildGsrPrefix()} {flags}{buildGsrSuffix()} {flags}\nfi`
end

local function buildReplayCommand(focusedOutputName, sourceOverride)
    local source = resolveVideoSource(noctalia.tr("notify.replay-failed"), focusedOutputName, sourceOverride)
    if source == nil then return nil end

    local dir = outputDirectory()

    local duration = cfg("replay_duration")
    local storage = cfg("replay_storage")
    local fm = cfg("frame_rate_mode")
    local fps = cfg("frame_rate")
    local codec = cfg("video_codec")
    if cfg("video_encoder") == "cpu" and codec ~= "h264" then
        log(`cpu encoder forces h264 (configured {codec})`)
        codec = "h264"
    end

    local bitrateFlags = buildVideoBitrateFlags(codec)
    if bitrateFlags == nil then return nil end

    local cursor = if cfg("show_cursor") then "yes" else "no"
    local cr = cfg("color_range")
    local restore = if cfg("restore_portal") then "-restore-portal-session yes" else ""
    local audioFlags = buildAudioFlags()
    local resFlag = buildResolutionFlag()
    local encoderFlag = buildEncoderFlag()
    local scriptFlag = buildSaveScriptFlag()

    local regionFlag = if source == "region" and regionGeometry ~= nil then `-region {regionGeometry}` else ""
    local flags = `-w {source} {regionFlag} -c mp4 -fm {fm} -f {fps} -k {codec} {encoderFlag} {audioFlags} {bitrateFlags} -cursor {cursor} -cr {cr} {resFlag} -r {duration} -replay-storage {storage} {scriptFlag} {restore} -v no -o "{dir}"`

    log(`starting replay buffer: mode={selectedVideoSource(sourceOverride)} target={source} dir={dir} flags=[{flags}]`)

    local header = `printf '=== gpu-screen-recorder replay %s ===\n' "$(date '+%Y-%m-%d %H:%M:%S')" > "{logFile}"`
    flags ..= ` >> "{logFile}" 2>&1`

    return `{header}\n{buildGsrPrefix()} {flags}{buildGsrSuffix()} {flags}\nfi`
end

-- ── Portal check ─────────────────────────────────────────────────────────

local function checkPortalsIfNeededAsync(sourceOverride, callback)
    if selectedVideoSource(sourceOverride) ~= "portal" then
        callback(true)
        return
    end

    -- Only verify xdg-desktop-portal itself is running. Which backend services
    -- ScreenCast (wlr, hyprland, gnome, kde, umbriel, jay, niri-screenshare,
    -- …) is the portal's problem to route; if none can, gpu-screen-recorder
    -- surfaces the error and logGsrTail echoes it.
    local ok = noctalia.processMatches(function(matched)
        log(`portal check: portal={matched}`)
        callback(matched)
    end, "xdg-desktop-portal ")
    if not ok then
        log("portal check: processMatches unavailable")
        callback(false)
    end
end

-- ── Recording controls ───────────────────────────────────────────────────

local function startRecording(focusedOutputName, sourceOverride)
    if not isAvailable or state ~= "idle" or pickInProcess then return end

    -- Region re-enters here with geometry set after the pick.
    if selectedVideoSource(sourceOverride) == "region" and regionGeometry == nil then
        pickRegionThen(noctalia.tr("notify.recording-failed"), function()
            startRecording(focusedOutputName, sourceOverride)
        end)
        return
    end

    setState("pending")
    pendingSince = tickCount
    updateDisplay()

    checkPortalsIfNeededAsync(sourceOverride, function(portalAvailable)
        if (state :: string) ~= "pending" then return end -- cast: state is widened, not the "idle" the analyzer narrows it to

        if not portalAvailable then
            setState("idle")
            log("recording aborted: xdg-desktop-portal / backend not running")
            noctalia.notifyError(noctalia.tr("notify.recording-failed"), noctalia.tr("notify.portal-not-running"))
            updateDisplay()
            return
        end

        local cmd = buildRecordCommand(focusedOutputName, sourceOverride)
        if not cmd then
            setState("idle")
            log("recording aborted: could not build command (no video source)")
            updateDisplay()
            return
        end

        if noctalia.runAsync(cmd) then
            log("gpu-screen-recorder launched")
        else
            setState("idle")
            log("recording aborted: runAsync failed to launch gpu-screen-recorder")
            noctalia.notifyError(noctalia.tr("notify.recording-failed"), noctalia.tr("notify.launch-failed"))
            updateDisplay()
        end
    end)
end

local function stopRecording()
    if not table.find(RECORDING_STATES, state) then return end

    log("stopping recording (user request)")
    signalRecorder("INT", false, true)

    if state == "recording" then
        notifyRecordingSavedIfPresent()
    end

    setState("idle")
end

-- ── Replay controls ──────────────────────────────────────────────────────

local function startReplay(focusedOutputName, sourceOverride)
    if not isAvailable or state ~= "idle" or pickInProcess then return end
    if not cfg("replay_enabled") then return end

    if selectedVideoSource(sourceOverride) == "region" and regionGeometry == nil then
        pickRegionThen(noctalia.tr("notify.replay-failed"), function()
            startReplay(focusedOutputName, sourceOverride)
        end)
        return
    end

    setState("replay_pending")
    pendingSince = tickCount
    updateDisplay()

    checkPortalsIfNeededAsync(sourceOverride, function(portalAvailable)
        if (state :: string) ~= "replay_pending" then return end -- cast: state is widened, not the "idle" the analyzer narrows it to

        if not portalAvailable then
            setState("idle")
            log("replay aborted: xdg-desktop-portal / backend not running")
            noctalia.notifyError(noctalia.tr("notify.replay-failed"), noctalia.tr("notify.portal-not-running"))
            updateDisplay()
            return
        end

        local cmd = buildReplayCommand(focusedOutputName, sourceOverride)
        if not cmd then
            setState("idle")
            log("replay aborted: could not build command (no video source)")
            updateDisplay()
            return
        end

        if noctalia.runAsync(cmd) then
            log("gpu-screen-recorder replay buffer launched")
        else
            setState("idle")
            log("replay aborted: runAsync failed to launch gpu-screen-recorder")
            noctalia.notifyError(noctalia.tr("notify.replay-failed"), noctalia.tr("notify.launch-failed"))
            updateDisplay()
        end
    end)
end

local function stopReplay()
    if not table.find(REPLAY_STATES, state) then return end

    log("stopping replay buffer (user request)")
    signalRecorder("INT", true, true)

    setState("idle")
    noctalia.notify(noctalia.tr("notify.replay-stopped"))
end

local function saveReplay()
    if state ~= "replaying" then return end
    log("saving replay buffer (SIGUSR1)")
    signalRecorder("USR1", true, false)

    local pattern = cfg("replay_filename_pattern")
    if pattern ~= nil and pattern ~= "" then
        local dir = outputDirectory()
        local targetFile = `{dir}{noctalia.formatTime(pattern)}.mp4`
        -- Replay mode only accepts an output directory (-o "{dir}"), so gpu-screen-recorder
        -- names the file itself as Replay_<timestamp>.mp4 using its own clock when it
        -- finalizes. Rather than predict that name, poll for the newest Replay_*.mp4 the
        -- save produced and rename it. `ref` (one second before the SIGUSR1) bounds the
        -- search so an earlier replay sitting in the directory is never picked up.
        local ref = (tonumber(noctalia.formatTime("%s")) or 0) - 1
        local claim = `f=$(find {shellQuote(dir)} -maxdepth 1 -name 'Replay_*.mp4' -newermt "@{ref}" -printf '%T@ %p\\n' 2>/dev/null | sort -n | tail -1 | cut -d' ' -f2-); `
            .. `if [ -n "$f" ]; then mv -n -- "$f" {shellQuote(targetFile)}; else exit 1; fi`
        local attempts = 50
        local function poll()
            noctalia.runAsync(`sleep 0.2; {claim}`, function(result)
                if result.exitCode == 0 then return end
                if attempts > 0 then
                    attempts -= 1
                    poll()
                end
            end)
        end
        poll()
    end

    noctalia.notify(noctalia.tr("notify.replay-saved"))
end

-- ── State polling ────────────────────────────────────────────────────────

local function checkProcessState(processState)
    if state == "pending" then
        if tickCount - pendingSince >= PENDING_TICKS then
            if processState == "recording" then
                log("recording active")
                setState("recording")
            elseif portalCaptureCancelled() then
                log("target selection cancelled by user")
                setState("idle")
            else
                log("recording never started (process not detected)")
                logGsrTail("recording failed to start")
                setState("idle")
                noctalia.notifyError(noctalia.tr("notify.recording-failed"), noctalia.tr("notify.recording-stopped-early"))
            end
        end
    elseif state == "replay_pending" then
        if tickCount - pendingSince >= PENDING_TICKS then
            if processState == "replaying" then
                log("replay buffer active")
                setState("replaying")
                noctalia.notify(noctalia.tr("notify.replay-active"))
            elseif portalCaptureCancelled() then
                log("target selection cancelled by user")
                setState("idle")
            else
                log("replay buffer never started (process not detected)")
                logGsrTail("replay buffer failed to start")
                setState("idle")
                noctalia.notifyError(noctalia.tr("notify.replay-failed"), noctalia.tr("notify.recording-stopped-early"))
            end
        end
    elseif state == "recording" then
        if processState ~= "recording" then
            log("recording process ended on its own")
            setState("idle")
            notifyRecordingSavedIfPresent(true)
        end
    elseif state == "replaying" then
        if processState ~= "replaying" then
            log("replay buffer process ended on its own")
            logGsrTail("replay buffer stopped")
            setState("idle")
            noctalia.notify(noctalia.tr("notify.replay-stopped"))
        end
    elseif state == "idle" then
        if processState ~= nil then
            log(`adopted externally-started gpu-screen-recorder ({processState})`)
            setState(processState)
        end
    end
end

local function requestProcessStateCheck()
    if processCheckPending then return end

    processCheckPending = true
    local generation = stateGeneration
    detectProcessStateAsync(function(processState)
        processCheckPending = false
        if generation ~= stateGeneration then return end
        if processState ~= nil then
            isAvailable = true
        end
        checkProcessState(processState)
        updateDisplay()
    end)
end

-- ── Status publication ─────────────────────────────────────────────────────

-- The service has no presentation; "updating the display" is publishing status.
function updateDisplay()
    publishStatus()
end

-- ── Callbacks ────────────────────────────────────────────────────────────

function update()
    tickCount += 1

    if not checkedAvailability then
        checkedAvailability = true
        isAvailable = checkAvailability()
        requestProcessStateCheck()
    end

    if tickCount % CHECK_TICKS == 0 then
        requestProcessStateCheck()
    end

    updateDisplay()
end

function onIpc(event, payload)
    -- Widget/shortcut drive this through the state channel with a table payload;
    -- the CLI passes the trailing IPC argument as a string. A string payload, or a
    -- table `source` field, is an optional capture-mode override (focused | portal |
    -- region) applied to this start; resolveVideoSource validates it.
    local focusedOutputName = nil
    local sourceOverride = nil
    if type(payload) == "table" then
        focusedOutputName = payload.focusedOutputName
        sourceOverride = payload.source
    elseif type(payload) == "string" and payload ~= "" then
        sourceOverride = payload
    end
    if focusedOutputName == nil or focusedOutputName == "" then
        focusedOutputName = noctalia.focusedOutputName()
    end

    log(`ipc '{event}' (state={state} source={sourceOverride or "config"} monitor={focusedOutputName or "?"})`)

    if event == "start" then
        startRecording(focusedOutputName, sourceOverride)
    elseif event == "stop" then
        stopRecording()
    elseif event == "toggle" then
        if table.find(RECORDING_STATES, state) then
            stopRecording()
        elseif table.find(REPLAY_STATES, state) then
            stopReplay()
        elseif state == "idle" then
            startRecording(focusedOutputName, sourceOverride)
        end
    elseif event == "replay-start" then
        startReplay(focusedOutputName, sourceOverride)
    elseif event == "replay-stop" then
        stopReplay()
    elseif event == "replay-toggle" then
        if table.find(REPLAY_STATES, state) then
            stopReplay()
        elseif state == "idle" then
            startReplay(focusedOutputName, sourceOverride)
        end
    elseif event == "replay-save" or event == "save-replay" then
        saveReplay()
    else
        noctalia.log(`screen_recorder: unknown command '{event}'`)
    end
end

-- runAsync launches detached processes, so they need explicit teardown when the
-- service is disabled/reloaded or Noctalia exits. Keep the grace-period fallback
-- in the detached shell so it can finish after the runtime has gone away.
function onExit()
    if state ~= "idle" then
        log("stopping capture (service exit)")
        signalRecorder("INT", false, true)
    end
end

-- The widget and shortcut drive the recorder by publishing to this channel.
noctalia.state.watch("command", function(cmd)
    local action = if type(cmd) == "table" and cmd.action ~= nil then cmd.action else cmd
    if type(action) == "string" then
        onIpc(action, if type(cmd) == "table" then cmd else nil)
    end
end)
