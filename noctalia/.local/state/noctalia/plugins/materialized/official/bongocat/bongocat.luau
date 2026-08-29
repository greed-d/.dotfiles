--!nonstrict
-- Bongo Cat — a cat that sits in your bar and slaps when you type or to the beat.
--
-- Configure input devices in the widget settings (input_devices = [
-- "/dev/input/by-id/...", "/dev/input/by-path/*-event-*"]). Prefer stable
-- by-id/by-path entries over /dev/input/eventN because event numbers can change.
-- When set and `evtest` is installed, the widget reads matching devices with
-- noctalia.runStream — one long-lived shell stream whose lines are delivered
-- straight to the script (no IPC, no per-keystroke process spawn). The stream is
-- killed automatically when the widget reloads or is removed.
--
-- Requirements: `evtest` installed, and your user in the `input` group.
-- Find devices with: sudo evtest  (or: ls -l /dev/input/by-id /dev/input/by-path)
--
-- Audio reactivity (audio_spectrum) uses the PipeWire spectrum and delivers
-- frames to onAudioSpectrum below.
--
-- Font glyph map (fonts/bongocat.otf):
--   b=left paw up, d=left paw down, c=right paw up, a=right paw down
--   bc=idle, dc=left slap, ba=right slap, da=both slap
--   ef=sleep, gh=blink

local bongocatFont = noctalia.loadFont("fonts/bongocat.otf")
if bongocatFont then
  barWidget.setFont(bongocatFont, "pictographic")
end
barWidget.setText("bc")
noctalia.setUpdateInterval(50)

local STATE_IDLE = 0
local STATE_LEFT = 1
local STATE_RIGHT = 2
local STATE_BOTH = 3

local glyphs = { [STATE_IDLE] = "bc", [STATE_LEFT] = "dc", [STATE_RIGHT] = "ba", [STATE_BOTH] = "da" }
local SLEEP_GLYPH = "ef"
local BLINK_GLYPH = "gh"

local catState = STATE_IDLE
local leftWasLast = false
local paused = false
local waiting = false
local blinking = false

local AUDIO_SPECTRUM_ENABLED = noctalia.getConfig("audio_spectrum") == true
local RAVE_MODE = noctalia.getConfig("rave_mode") == true
local TAPPY_MODE = noctalia.getConfig("tappy_mode") == true
local USE_MPRIS_FILTER = noctalia.getConfig("use_mpris_filter") == true

local idleTicks = 0
local waitingTicks = 0
local blinkDuration = 0
local nextBlinkIn = 0

local IDLE_TICKS = 5       -- 250ms to return paws to idle after typing stops
local WAITING_TICKS = 100  -- 5s of idle -> sleeping
local BLINK_DURATION = 9   -- ~450ms blink
local BLINK_MIN = 120      -- ~6s minimum between blinks
local BLINK_MAX = 280      -- ~14s max between blinks

local rainbowIndex = 1
local rainbowColors = { "#aa0000", "#b65c02", "#bb9c14", "#00a100", "#01019b", "#37005c", "#6a0196" }
local audioIntensity = 0
local smoothedIntensity = 0
local previousIntensity = 0
local bassIntensity = 0
local beatThreshold = 0.07
local bigBeatThreshold = 0.67
local beatDeltaThreshold = 0.014
local beatCooldownTicks = 0 -- ~100ms
local raveFlashTicks = 0    -- ~100ms
local audioConfigWarned = false

local function randomBlinkDelay()
  return BLINK_MIN + math.floor(math.random() * (BLINK_MAX - BLINK_MIN))
end

nextBlinkIn = randomBlinkDelay()

local function applyCatColor()
  if RAVE_MODE and raveFlashTicks > 0 then
    barWidget.setColor(rainbowColors[rainbowIndex], "script")
  else
    barWidget.setColor("on_surface")
  end
end

local function refreshDisplay()
  applyCatColor()
  barWidget.setText(if paused or waiting then SLEEP_GLYPH elseif blinking then BLINK_GLYPH else glyphs[catState] or "bc")
end

local function onKeyDown(isBigHit)
  if paused then return end
  waiting = false
  waitingTicks = 0
  blinking = false

  if isBigHit or catState ~= STATE_IDLE then
    catState = STATE_BOTH
  else
    leftWasLast = not leftWasLast
    catState = if leftWasLast then STATE_LEFT else STATE_RIGHT
  end
  idleTicks = 0
  refreshDisplay()
end

local function onKeyUp()
  if paused then return end
  waiting = false
  waitingTicks = 0

  catState = if catState == STATE_BOTH then if leftWasLast then STATE_LEFT else STATE_RIGHT else STATE_IDLE
  idleTicks = 0
  refreshDisplay()
end

local function onKeyRepeat(isBigHit)
  if paused then return end
  waiting = false
  waitingTicks = 0

  if catState == STATE_IDLE then
    catState = if isBigHit then STATE_BOTH elseif leftWasLast then STATE_LEFT else STATE_RIGHT
  end
  idleTicks = 0
  refreshDisplay()
end

local function onBeatTap(isBigHit)
  if paused then return end
  waiting = false
  waitingTicks = 0
  blinking = false

  if isBigHit then
    catState = STATE_BOTH
  else
    leftWasLast = not leftWasLast
    catState = if leftWasLast then STATE_LEFT else STATE_RIGHT
  end

  idleTicks = 0
  refreshDisplay()
end

-- ── Input reader (noctalia.runStream → evtest) ────────────────────────────
local function has(line, needle)
  return line:find(needle, 1, true) ~= nil
end

local function onEvtestLine(line)
  -- evtest prints one line per event, e.g.:
  --   Event: time 1700.0, type 1 (EV_KEY), code 57 (KEY_SPACE), value 1
  if not has(line, "EV_KEY") or has(line, "BTN_TOOL_") then
    return
  end
  local isBigHit = has(line, "KEY_SPACE") or has(line, "KEY_ENTER")
  if has(line, "value 1") then
    onKeyDown(isBigHit)
  elseif has(line, "value 0") then
    onKeyUp()
  elseif has(line, "value 2") then
    onKeyRepeat(isBigHit)
  end
end

local function isAllowedInputPatternByte(byte)
  return (byte >= 48 and byte <= 57) -- 0-9
      or (byte >= 65 and byte <= 90) -- A-Z
      or (byte >= 97 and byte <= 122) -- a-z
      or byte == 47 -- /
      or byte == 46 -- .
      or byte == 95 -- _
      or byte == 45 -- -
      or byte == 58 -- :
      or byte == 43 -- +
      or byte == 42 -- *
      or byte == 63 -- ?
      or byte == 91 -- [
      or byte == 93 -- ]
end

local function isSupportedInputPattern(pattern)
  return pattern:match("^/dev/input/event") ~= nil
      or pattern:match("^/dev/input/by%-id/") ~= nil
      or pattern:match("^/dev/input/by%-path/") ~= nil
end

local function validateInputPattern(pattern)
  if type(pattern) ~= "string" or pattern == "" then
    return false
  end
  if pattern:find("..", 1, true) ~= nil or not isSupportedInputPattern(pattern) then
    return false
  end
  for i = 1, #pattern do
    if not isAllowedInputPatternByte(pattern:byte(i)) then
      return false
    end
  end
  return true
end

local function startInputReader()
  local devices = noctalia.getConfig("input_devices")
  if devices == nil then
    return
  end
  if type(devices) ~= "table" then
    noctalia.notifyError("Bongo Cat", "Invalid input_devices (expected a list of /dev/input paths or globs)")
    return
  end

  local patterns = {}
  local seen = {}
  for _, pattern in ipairs(devices) do
    if not validateInputPattern(pattern) then
      noctalia.notifyError("Bongo Cat", `Invalid input_devices entry: {tostring(pattern)}`)
      return
    end
    if seen[pattern] == nil then
      seen[pattern] = true
      table.insert(patterns, pattern)
    end
  end
  if #patterns == 0 then
    return
  end

  local executable = noctalia.getConfig("executable_path")

  if executable == nil or executable == "" then
    executable = "evtest"
  end

  if not noctalia.commandExists(executable) then
    noctalia.notifyError("Bongo Cat", "the evtest path is invalid (" .. executable .. ") — cannot read input devices")
    return
  end

  -- single-quote for the shell so paths with spaces or metacharacters are safe
  local quotedExecutable = "'" .. executable:gsub("'", "'\''") .. "'"

  local command = "for device in " .. table.concat(patterns, " ")
    .. '; do [ -e "$device" ] || continue; ' .. quotedExecutable
    .. ' "$device" 2>/dev/null & done; wait'

  if not noctalia.runStream(command, onEvtestLine) then
    noctalia.notifyError("Bongo Cat", "Unable to start input device reader")
  end
end

startInputReader()

local function parseCsvNumbers(csv)
  local values = {}
  if csv == nil or csv == "" then
    return values
  end
  for part in csv:gmatch("([^,]+)") do
    table.insert(values, tonumber(part) or 0)
  end
  return values
end

local function parseAudioState(csv)
  local parts = parseCsvNumbers(csv)
  return parts[1] == 1, parts[2] == 1
end

local function average(values, firstIndex, lastIndex)
  if lastIndex < firstIndex then
    return 0
  end
  local sum = 0
  local count = 0
  for i = firstIndex, lastIndex do
    sum = sum + (values[i] or 0)
    count += 1
  end
  if count == 0 then
    return 0
  end
  return sum / count
end

function update()
  if (RAVE_MODE or TAPPY_MODE) and not AUDIO_SPECTRUM_ENABLED and not audioConfigWarned then
    audioConfigWarned = true
    noctalia.notifyError("Bongo Cat", "Set audio_spectrum = true to use rave_mode or tappy_mode.")
  end

  if beatCooldownTicks > 0 then
    beatCooldownTicks -= 1
  end

  if raveFlashTicks > 0 then
    raveFlashTicks -= 1
    if raveFlashTicks == 0 then
      refreshDisplay()
    end
  end

  if paused then return end

  -- Idle timeout: return paws to rest
  if catState ~= STATE_IDLE then
    idleTicks += 1
    if idleTicks >= IDLE_TICKS then
      catState = STATE_IDLE
      refreshDisplay()
    end
  end

  -- Waiting timeout: go to sleep
  if not waiting then
    waitingTicks += 1
    if waitingTicks >= WAITING_TICKS then
      waiting = true
      blinking = false
      refreshDisplay()
    end
  end

  -- Blink logic (only when awake and idle)
  if not waiting and catState == STATE_IDLE then
    if blinking then
      blinkDuration += 1
      if blinkDuration >= BLINK_DURATION then
        blinking = false
        blinkDuration = 0
        nextBlinkIn = randomBlinkDelay()
        refreshDisplay()
      end
    else
      nextBlinkIn -= 1
      if nextBlinkIn <= 0 then
        blinking = true
        blinkDuration = 0
        refreshDisplay()
      end
    end
  end
end

function onAudioSpectrum(valuesCsv, stateCsv)
  if paused then return end
  if not RAVE_MODE and not TAPPY_MODE then return end

  local audioActive, mprisPlaying = parseAudioState(stateCsv)
  if not audioActive then
    audioIntensity = 0
    return
  end
  if USE_MPRIS_FILTER and not mprisPlaying then
    return
  end

  local values = parseCsvNumbers(valuesCsv)
  if #values == 0 then
    audioIntensity = 0
    return
  end

  local subBassCount = math.clamp(#values, 1, 4)
  local bassCount = math.clamp(#values, 1, 8)
  local midCount = math.clamp(#values, 9, 16)
  local subBassAvg = average(values, 1, subBassCount)
  local bassAvg = average(values, 1, bassCount)
  local midAvg = average(values, 9, midCount)

  bassIntensity = subBassAvg
  audioIntensity = (bassAvg * 0.8) + (midAvg * 0.6)

  local alpha = 0.75
  previousIntensity = smoothedIntensity
  smoothedIntensity = alpha * audioIntensity + (1 - alpha) * smoothedIntensity

  local intensityDelta = smoothedIntensity - previousIntensity
  local isBeat = (intensityDelta > beatDeltaThreshold and smoothedIntensity > beatThreshold * 0.5)
      or (smoothedIntensity > beatThreshold and intensityDelta > 0)

  if isBeat and beatCooldownTicks <= 0 then
    if RAVE_MODE then
      rainbowIndex = (rainbowIndex % #rainbowColors) + 1
      raveFlashTicks = 2
      refreshDisplay()
    end

    if TAPPY_MODE then
      onBeatTap(bassIntensity > bigBeatThreshold)
    end

    beatCooldownTicks = 2
  end
end

function onClick()
  paused = not paused
  if not paused then
    waitingTicks = 0
    waiting = false
    catState = STATE_IDLE
  end
  refreshDisplay()
end

function onIpc(event, payload)
  if event == "pause" then
    paused = true
    refreshDisplay()
  elseif event == "resume" then
    paused = false
    waiting = false
    waitingTicks = 0
    catState = STATE_IDLE
    refreshDisplay()
  elseif event == "toggle" then
    paused = not paused
    if not paused then
      waiting = false
      waitingTicks = 0
      catState = STATE_IDLE
    end
    refreshDisplay()
  end
end
