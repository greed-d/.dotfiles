--!nonstrict
-- Screen Toolkit — headless [[service]].
--
-- Owns every tool pipeline (color pick, OCR, QR, palette, lens, annotate,
-- measure, recording, sharing) plus state persistence. The bar [[widget]], the
-- control-center [[shortcut]], and the main [[panel]] are thin clients: they
-- read the published state and drive this service by writing to the plugin's
-- "command" state channel (or by IPC). A capture can be started even with no
-- UI entry placed.
--
-- Screen captures go through the shell's own screenshot stack
-- (`screenshot-region` / `screenshot-fullscreen` via `noctalia msg`), which
-- owns the output policy under [shell.screenshot]. Intermediate captures
-- (OCR, QR, palette, Lens, measure, markup raws) are captured straight into
-- a plugin-owned temp file via per-call screenshot options, so they work
-- with file saving disabled and never touch the screenshots folder; older
-- shells fall back to the user's policy and move the file out (see
-- shell-capture.sh). Pixel work (OCR, QR, palette, Lens uploads, window
-- crops) runs over that file with `tesseract` / `zbarimg` / `magick` /
-- `curl`. Annotation opens the shell's own editor (`annotate <file>`); the
-- window capture lets you click one and snaps to it with `hyprctl` (or
-- takes the focused one on `niri`). Other compositors fall back to a
-- manual region; Umbriel uses its window picker. Only region *recording* uses
-- `slurp`, to get a geometry for the external recorder backends.
--
-- Recording runs `wl-screenrec` (preferred) or `wf-recorder`. The raw output
-- lands in /tmp as MP4; GIF is produced on save via record.sh convert-gif.

local PANEL_ID = "alexander/screen-toolkit:panel"
local RESULT_PANEL_ID = "alexander/screen-toolkit:result"
local PICK_PANEL_ID = "alexander/screen-toolkit:pick"

local SCRIPT_CAPTURE = noctalia.pluginDir() .. "/scripts/capture.sh"
local SCRIPT_SHELL = noctalia.pluginDir() .. "/scripts/shell-capture.sh"
local SCRIPT_CAPTURE_NIRI = noctalia.pluginDir() .. "/scripts/capture-niri.sh"
local SCRIPT_OCR = noctalia.pluginDir() .. "/scripts/ocr.sh"
local SCRIPT_LENS = noctalia.pluginDir() .. "/scripts/lens-upload.sh"
local SCRIPT_RECORD = noctalia.pluginDir() .. "/scripts/record.sh"
local SCRIPT_SHARE = noctalia.pluginDir() .. "/scripts/share-upload.sh"
local SCRIPT_PICKER = noctalia.pluginDir() .. "/scripts/color-picker.sh"

local COLOR_PNG = "/tmp/screen-toolkit-colorpicker.png"
-- Fixed output of the niri focused-window capture (niri IPC, no shell involved).
local ANNOTATE_PNG = "/tmp/screen-toolkit-annotate.png"

local MAX_HISTORY = 8

-- ── Small helpers ──────────────────────────────────────────────────────────

local function cfg(key)
  return noctalia.getConfig(key)
end

local function log(msg)
  noctalia.log(`screen-toolkit: {msg}`)
end

local function trim(s)
  return (tostring(s):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function copyFileUri(path)
  local escaped = tostring(path):gsub(" ", "%%20"):gsub("'", "%%27"):gsub('"', "%%22")
  noctalia.copyToClipboard(`file://{escaped}`, "text/uri-list")
end

-- Compositor detection. `niri msg` talks over a socket whose path niri exports
-- as NIRI_SOCKET; when that is set we route annotate-window through the niri
-- capture script, otherwise we fall back to the Hyprland path (hyprctl).
-- Umbriel exports UMBRIEL_SOCKET and gets its own focused-window path
-- (slurp cannot run there, so no click-to-pick: same deal as Niri).
local function isNiri()
  return (noctalia.getenv("NIRI_SOCKET") or "") ~= ""
end

local function isUmbriel()
  return (noctalia.getenv("UMBRIEL_SOCKET") or "") ~= ""
end

-- Whether the cursor is excluded from recordings. Screenshots follow the
-- shell's own [shell.screenshot] cursor policy; this flag only reaches the
-- external recorder backends (see their cursor flags in buildRecorderArgv).
local cursorHidden = true
local CAPTURE_DELAY = 0.15

local function publish(key, value)
  noctalia.state.set(key, value)
end

-- `noctalia.outputs()` reports logical geometry; gpu-screen-recorder, wl-screenrec and wf-recorder want logical geometry. Except for gpu-screen-recorder, they all take geometry as formated by this function.
local function focusedGeometry()
  local outputs = noctalia.outputs()
  for _, o in ipairs(outputs) do
    if o.focused then
      return string.format(
        "%d,%d %dx%d",
        o.x,
        o.y,
        o.width,
        o.height
      )
    end
  end
  if outputs and #outputs > 0 then
    local o = outputs[1]
    return string.format(
      "%d,%d %dx%d",
      o.x,
      o.y,
      o.width,
      o.height
    )
  end
  return nil
end

local function videoDir()
  local p = noctalia.expandPath(cfg("video-path") or "")
  if p == "" then p = noctalia.expandPath("~/Videos") end
  return p
end

local function buildFilename(tool, ext)
  local stem = noctalia.formatTime(cfg("filename-format") or "")
  if stem == nil or stem == "" then
    stem = tool .. "-" .. noctalia.formatTime("%Y-%m-%d_%H-%M-%S")
  end
  return stem .. ext
end

-- ── Region selection (slurp, recording only) ─────────────────────────────────

local slurping = false
local ocrRunning = false
local ocrSerial = 0

-- Region *recording* still needs a geometry for wl-screenrec / wf-recorder,
-- so it keeps the slurp crosshair. All screenshot/OCR/QR/palette/Lens flows
-- use the shell's interactive region overlay via shellCapture below instead.
-- Draws the slurp crosshair after a short delay so the just-closed panel's
-- close animation is not captured. Invokes callback(geom) or nothing on cancel.
local function slurpGeometry(callback)
  if slurping then
    noctalia.notify(noctalia.tr("panel.running"))
    return
  end
  slurping = true
  -- slurp blocks for as long as the user is dragging the selection. Give it a
  -- generous timeout; the default runAsync one cancels a slow/long drag.
  if not noctalia.runAsync({ "sleep", "0.3" }, function()
    noctalia.runAsync({ "slurp", "-f", "%x,%y %wx%h" }, function(res)
      slurping = false
      if res.exitCode ~= 0 then return end -- cancelled
      local geom = trim(res.stdout or "")
      if geom == "" then return end
      callback(geom)
    end, 600000)
  end) then
    slurping = false
  end
end

-- ── Native shell capture ───────────────────────────────────────────────────

local SHELL_TIMEOUT_INTERACTIVE = 600000
local SHELL_TIMEOUT_QUICK = 120000
local SHELL_TIMEOUT_EDIT = 30000

-- Runs a shell-capture.sh action and maps its exit codes:
--   10 cancelled → silent; 11 nothing saved → no_file hint;
--   1 missing dep → names it; anything else nonzero → capture_failed.
-- Exit 0 delivers the file path on stdout to onFile(path).
local function shellCapture(argv, timeout, onFile)
  noctalia.runAsync(argv, function(res)
    if res.exitCode == 10 then return end -- cancelled, silent
    if res.exitCode ~= 0 then
      log(`capture '{table.concat(argv, " ")}' exit={res.exitCode} out={trim(res.stdout or "")}`)
    end
    if res.exitCode == 11 then
      noctalia.notifyError(noctalia.tr("messages.no_file"))
      return
    end
    if res.exitCode == 1 then
      noctalia.notifyError(noctalia.tr("messages.missing_dep", { dep = trim(res.stdout or "") }))
      return
    end
    if res.exitCode ~= 0 then
      noctalia.notifyError(noctalia.tr("messages.capture_failed"))
      return
    end
    local path = trim(res.stdout or "")
    if path == "" then
      noctalia.notifyError(noctalia.tr("messages.no_file"))
      return
    end
    onFile(path)
  end, timeout)
end

-- Capture actions ending in "-tmp" (see shell-capture.sh) already deliver a
-- plugin-owned temp file, so text-only tools (OCR/QR/palette/measure/lens)
-- and markup raws call them directly: nothing is ever written to the
-- screenshots folder. Annotate's `edit` handoff and the record flows keep
-- plain shellCapture — their file is the deliverable.

-- Opens a file in the shell's annotation editor. Silent when the editor
-- takes it; surfaces failures instead of dying quietly.
local function editFile(path, onOk)
  noctalia.runAsync({ SCRIPT_SHELL, "edit", path }, function(res)
    if res.exitCode == 1 then
      noctalia.notifyError(noctalia.tr("messages.missing_dep", { dep = trim(res.stdout or "") }))
      return
    end
    if res.exitCode ~= 0 then
      noctalia.notifyError(noctalia.tr("messages.capture_failed"))
      return
    end
    if onOk then onOk(trim(res.stdout or "")) end
  end, SHELL_TIMEOUT_EDIT)
end

-- ── Color conversions ──────────────────────────────────────────────────────

local function clamp(n)
  return math.max(0, math.min(255, n))
end

local function rgbToHsv(r, g, b)
  local rn, gn, bn = r / 255, g / 255, b / 255
  local max, min = math.max(rn, gn, bn), math.min(rn, gn, bn)
  local d = max - min
  local h, sat, val = 0, 0, max
  if d ~= 0 then
    sat = d / max
    if max == rn then
      h = ((gn - bn) / d + (gn < bn and 6 or 0)) % 6
    elseif max == gn then
      h = (bn - rn) / d + 2
    else
      h = (rn - gn) / d + 4
    end
    h = math.round(h * 60)
  end
  return h, math.round(sat * 100), math.round(val * 100)
end

local function rgbToHsl(r, g, b)
  local rn, gn, bn = r / 255, g / 255, b / 255
  local max, min = math.max(rn, gn, bn), math.min(rn, gn, bn)
  local d = max - min
  local h, l = 0, (max + min) / 2
  local s = if d == 0 then 0 else d / (1 - math.abs(2 * l - 1))
  if d ~= 0 then
    if max == rn then
      h = ((gn - bn) / d + (gn < bn and 6 or 0)) % 6
    elseif max == gn then
      h = (bn - rn) / d + 2
    else
      h = (rn - gn) / d + 4
    end
    h = h / 6
  end
  return math.floor(h * 360 + 0.5), math.round(s * 100), math.round(l * 100)
end

-- ── Persistence (survives restarts; plugin data dir is update-safe) ────────

local DATA_DIR = noctalia.pluginDataDir()
local RESULTS_FILE = DATA_DIR .. "/results.json"
local HISTORY_FILE = DATA_DIR .. "/color-history.json"
local SHARE_HISTORY_FILE = DATA_DIR .. "/share-history.json"

local function loadState()
  local raw = noctalia.readFile(RESULTS_FILE)
  if raw then
    local d = noctalia.json.decode(raw)
    if type(d) == "table" then
      if d.activeTool then publish("activeTool", d.activeTool) end
      if d.colorResult then publish("colorResult", d.colorResult) end
      if d.ocrResult then publish("ocrResult", d.ocrResult) end
      if d.qrResult then publish("qrResult", d.qrResult) end
      if d.paletteColors then publish("paletteColors", d.paletteColors) end
      if d.paletteCapture then publish("paletteCapture", d.paletteCapture) end
    end
  end
  local hraw = noctalia.readFile(HISTORY_FILE)
  if hraw then
    local d = noctalia.json.decode(hraw)
    if type(d) == "table" then publish("colorHistory", d) end
  end
  local sraw = noctalia.readFile(SHARE_HISTORY_FILE)
  if sraw then
    local d = noctalia.json.decode(sraw)
    if type(d) == "table" then publish("shareHistory", d) end
  end
end

local function saveResults()
  local d = {
    activeTool = noctalia.state.get("activeTool"),
    colorResult = noctalia.state.get("colorResult"),
    ocrResult = noctalia.state.get("ocrResult"),
    qrResult = noctalia.state.get("qrResult"),
    paletteColors = noctalia.state.get("paletteColors"),
    paletteCapture = noctalia.state.get("paletteCapture"),
  }
  local enc = noctalia.json.encode(d)
  if enc then noctalia.writeFile(RESULTS_FILE, enc) end

  local h = noctalia.state.get("colorHistory") or {}
  local henc = noctalia.json.encode(h)
  if henc then noctalia.writeFile(HISTORY_FILE, henc) end

  local sh = noctalia.state.get("shareHistory") or {}
  local senc = noctalia.json.encode(sh)
  if senc then noctalia.writeFile(SHARE_HISTORY_FILE, senc) end
end

local function pushHistory(hex)
  hex = hex:upper()
  local history = noctalia.state.get("colorHistory") or {}
  for i, c in ipairs(history) do
    if c == hex then
      table.remove(history, i)
      break
    end
  end
  table.insert(history, 1, hex)
  while #history > MAX_HISTORY do
    table.remove(history)
  end
  publish("colorHistory", history)
end

-- ── Tools: color picker ────────────────────────────────────────────────────

local function runColorPicker()
  -- hyprpicker waits for an interactive pointer selection. Keep it on the
  -- long-lived stream API; captured runAsync callbacks can time out while the
  -- user is still choosing a color.
  -- runStream only accepts a shell string on the host, so this one keeps the
  -- shell form. COLOR_PNG is a constant without spaces, needing no quoting.
  noctalia.runStream(`sleep {CAPTURE_DELAY}; {SCRIPT_PICKER} {COLOR_PNG}`, function(line)
    local r, g, b = tostring(line):match("^(%d+)%s+(%d+)%s+(%d+)$")
    if not r then return end
    r, g, b = clamp(tonumber(r)), clamp(tonumber(g)), clamp(tonumber(b))
    local hex = string.format("#%02X%02X%02X", r, g, b)
    local rgb = string.format("rgb(%d, %d, %d)", r, g, b)
    local h, s, v = rgbToHsv(r, g, b)
    local hh, ss, ll = rgbToHsl(r, g, b)
    local hsv = string.format("hsv(%d, %d%%, %d%%)", h, s, v)
    local hsl = string.format("hsl(%d, %d%%, %d%%)", hh, ss, ll)

    noctalia.copyToClipboard(hex, "text/plain;charset=utf-8")
    pushHistory(hex)
    publish("colorResult", {
      hex = hex, rgb = rgb, hsv = hsv, hsl = hsl,
      capturePath = COLOR_PNG, cacheBust = os.time(),
    })
    publish("activeTool", "colorpicker")
    saveResults()
    noctalia.togglePanel(RESULT_PANEL_ID)
  end)
end

-- ── Tools: OCR ─────────────────────────────────────────────────────────────

local OCR_EXIT_KEYS = {
  [2] = "ocr.exit_args",
  [4] = "ocr.exit_process",
}

local function runOcr()
  if ocrRunning then
    noctalia.notify(noctalia.tr("panel.running"))
    return
  end
  shellCapture({ SCRIPT_SHELL, "region-tmp" }, SHELL_TIMEOUT_INTERACTIVE, function(path)
    ocrRunning = true
    ocrSerial = ocrSerial + 1
    local serial = ocrSerial
    local lang = cfg("selected-ocr-lang") or "eng"
    noctalia.runAsync({ SCRIPT_OCR, path, lang }, function(res)
      ocrRunning = false
      if res.exitCode == 1 then
        noctalia.notifyError(noctalia.tr("messages.missing_dep", { dep = trim(res.stdout or "") }))
        return
      elseif res.exitCode ~= 0 then
        noctalia.notifyError(noctalia.tr(OCR_EXIT_KEYS[res.exitCode] or "ocr.exit_unknown", { code = tostring(res.exitCode) }))
        return
      end
      local text = trim(res.stdout or "")
      if text == "" then
        noctalia.notifyError(noctalia.tr("messages.no_text"))
        return
      end
      noctalia.runAsync({ "magick", "identify", "-format", "%w %h", path }, function(dimRes)
        local dw, dh = tostring(dimRes.stdout or ""):match("(%d+)%s+(%d+)")
        noctalia.copyToClipboard(text, "text/plain;charset=utf-8")
        publish("ocrResult", {
          text = text,
          capturePath = path,
          cacheBust = tostring(os.time()) .. "-" .. tostring(serial),
          gw = tonumber(dw) or 0,
          gh = tonumber(dh) or 0,
        })
        publish("translateResult", nil)
        publish("activeTool", "ocr")
        saveResults()
        noctalia.togglePanel(RESULT_PANEL_ID)
      end)
    end)
  end)
end

local function ocrTranslate(payload)
  local result = noctalia.state.get("ocrResult")
  local text = if type(payload) == "table" and type(payload.text) == "string"
    then payload.text
    else type(result) == "table" and result.text or nil
  if not text or text == "" then return end
  if not noctalia.commandExists("trans") then
    noctalia.notifyError(noctalia.tr("messages.missing_dep", { dep = "translate-shell" }))
    return
  end
  publish("translateResult", nil)
  local targetLang = if type(payload) == "table" then payload.lang else payload
  local lang = if type(targetLang) == "string" and targetLang ~= "" then targetLang else "en"
  noctalia.runAsync({ "trans", "-brief", "-no-bidi", "-to", lang, text }, function(res)
    if res.exitCode ~= 0 then
      publish("translateResult", noctalia.tr("messages.translate_failed"))
      return
    end
    -- trans bidi conversion outputs presentation-forms + terminal padding (visual order);
    -- -no-bidi gives logical order (U+0600) for Qt/HarfBuzz shaping. Collapse stray newlines.
    local out = trim(res.stdout or "")
    out = out:gsub("%s+", " ")
    -- strip BOM FEFF that trans emits in bidi mode
    out = out:gsub("^\239\187\191", "")
    publish("translateResult", out)
  end)
end

local function ocrRetry(payload)
  if ocrRunning then
    noctalia.notify(noctalia.tr("panel.running"))
    return
  end
  local result = noctalia.state.get("ocrResult")
  local path = if type(result) == "table" then result.capturePath else nil
  if not path or path == "" then
    noctalia.notifyError(noctalia.tr("messages.no_text"))
    return
  end
  local psm, lang = nil, cfg("selected-ocr-lang") or "eng"
  local function validPsm(v)
    v = tostring(v)
    if v == "3" or v == "4" or v == "6" or v == "7" or v == "11" then return v end
    return nil
  end
  if type(payload) == "table" then
    psm = validPsm(payload.psm)
    if type(payload.lang) == "string" and payload.lang ~= "" then lang = payload.lang end
  elseif type(payload) == "string" and payload ~= "" then
    psm = validPsm(payload)
    if not psm then lang = payload end
  elseif type(payload) == "number" then
    psm = validPsm(payload)
  end
  ocrRunning = true
  ocrSerial = ocrSerial + 1
  local serial = ocrSerial
  local args = { SCRIPT_OCR, path, lang }
  if psm then args[#args + 1] = psm end
  noctalia.runAsync(args, function(res)
    ocrRunning = false
    if res.exitCode == 1 then
      noctalia.notifyError(noctalia.tr("messages.missing_dep", { dep = trim(res.stdout or "") }))
      return
    elseif res.exitCode ~= 0 then
      noctalia.notifyError(noctalia.tr(OCR_EXIT_KEYS[res.exitCode] or "ocr.exit_unknown", { code = tostring(res.exitCode) }))
      return
    end
    local text = trim(res.stdout or "")
    if text == "" then
      noctalia.notifyError(noctalia.tr("messages.no_text"))
      return
    end
    noctalia.copyToClipboard(text, "text/plain;charset=utf-8")
    local gw, gh = 0, 0
    if type(result) == "table" then gw, gh = tonumber(result.gw) or 0, tonumber(result.gh) or 0 end
    publish("ocrResult", {
      text = text,
      capturePath = path,
      cacheBust = tostring(os.time()) .. "-r" .. tostring(serial),
      gw = gw,
      gh = gh,
    })
    publish("translateResult", nil)
    publish("activeTool", "ocr")
    saveResults()
  end)
end

-- ── Tools: QR / palette / lens ─────────────────────────────────────────────

local function runQr()
  shellCapture({ SCRIPT_SHELL, "region-tmp" }, SHELL_TIMEOUT_INTERACTIVE, function(path)
    noctalia.runAsync({ SCRIPT_CAPTURE, "qr", path }, function(res)
      local text = trim(res.stdout or "")
      if res.exitCode ~= 0 or text == "" then
        noctalia.notifyError(noctalia.tr("messages.no_qr"))
        return
      end
      noctalia.copyToClipboard(text, "text/plain;charset=utf-8")
      publish("qrResult", { text = text, capturePath = path })
      publish("activeTool", "qr")
      saveResults()
      noctalia.togglePanel(RESULT_PANEL_ID)
    end)
  end)
end

local function runPalette()
  shellCapture({ SCRIPT_SHELL, "region-tmp" }, SHELL_TIMEOUT_INTERACTIVE, function(path)
    noctalia.runAsync({ SCRIPT_CAPTURE, "palette", path }, function(res)
      if res.exitCode ~= 0 then
        noctalia.notifyError(noctalia.tr("messages.palette_failed"))
        return
      end
      local colors = {}
      for line in (res.stdout or ""):gmatch("[^\n]+") do
        local c = trim(line)
        if c:match("^#%x%x%x%x%x%x$") then
          colors[#colors + 1] = c:upper()
        end
      end
      local seen, out = {}, {}
      for _, c in ipairs(colors) do
        if not seen[c] then
          seen[c] = true
          out[#out + 1] = c
        end
      end
      if #out == 0 then
        noctalia.notifyError(noctalia.tr("messages.palette_failed"))
        return
      end
      noctalia.copyToClipboard(table.concat(out, "\n"), "text/plain;charset=utf-8")
      publish("paletteColors", out)
      publish("paletteCapture", path)
      publish("activeTool", "palette")
      saveResults()
      noctalia.togglePanel(RESULT_PANEL_ID)
    end)
  end)
end

local function runLens()
  shellCapture({ SCRIPT_SHELL, "region-tmp" }, SHELL_TIMEOUT_INTERACTIVE, function(path)
    noctalia.runAsync({ SCRIPT_LENS, path }, function(res)
      if res.exitCode == 1 then
        noctalia.notifyError(noctalia.tr("messages.missing_dep", { dep = trim(res.stdout or "") }))
      elseif res.exitCode ~= 0 then
        noctalia.notifyError(noctalia.tr("messages.lens_failed"))
      end
    end)
  end)
end

-- ── Tools: measure ─────────────────────────────────────────────────────────

local function runMeasure()
  shellCapture({ SCRIPT_SHELL, "region-tmp" }, SHELL_TIMEOUT_INTERACTIVE, function(path)
    noctalia.runAsync({ "magick", "identify", "-format", "%w %h", path }, function(res)
      local sw, sh = tostring(res.stdout or ""):match("(%d+)%s+(%d+)")
      local gw, gh = tonumber(sw), tonumber(sh)
      if not gw or not gh then
        noctalia.notifyError(noctalia.tr("messages.measure_failed"))
        return
      end
      local text = string.format("%d x %d px", gw, gh)
      noctalia.copyToClipboard(text, "text/plain;charset=utf-8")
      publish("measureResult", { width = gw, height = gh, text = text })
      noctalia.notify(noctalia.tr("messages.measure_result", { width = tostring(gw), height = tostring(gh) }))
    end)
  end)
end

-- ── Tools: annotate (shell editor handoff) ──────────────────────────────

local function afterAnnotate(path)
  publish("activeTool", "annotate")
  publish("annotateResult", { capturePath = path })
  saveResults()
end

-- Markup: capture + editor handoff. With "annotate-keep-raw" off (default)
-- the raw capture stays in a plugin-owned temp file and only the editor's
-- Copy / Save output reaches the user's outputs; with it on, the raw is
-- kept in the shell's screenshot folder (v2.0 behavior).
local function annotateArgv(action)
  if cfg("annotate-keep-raw") == true then
    return { SCRIPT_SHELL, action, "keep" }
  end
  return { SCRIPT_SHELL, action }
end

local function annotateRegion()
  shellCapture(annotateArgv("annotate-region"), SHELL_TIMEOUT_INTERACTIVE, afterAnnotate)
end

local function annotateFullscreen()
  shellCapture(annotateArgv("annotate-fullscreen"), SHELL_TIMEOUT_QUICK, afterAnnotate)
end

local function annotateWindow()
  if isNiri() then
    if not noctalia.commandExists("niri") then
      noctalia.notifyError(noctalia.tr("messages.missing_dep", { dep = "niri" }))
      return
    end
    noctalia.runAsync({ SCRIPT_CAPTURE_NIRI, "annotate-window" }, function(res)
      if res.exitCode == 3 then
        noctalia.notifyError(noctalia.tr("messages.missing_dep", { dep = "niri" }))
        return
      end
      if res.exitCode ~= 0 then
        noctalia.notifyError(noctalia.tr("messages.capture_failed"))
        return
      end
      editFile(ANNOTATE_PNG, afterAnnotate)
    end, SHELL_TIMEOUT_QUICK)
    return
  end
  if isUmbriel() then
    local sock = noctalia.getenv("UMBRIEL_SOCKET") or ""
    if sock == "" or not noctalia.commandExists("umbriel") then
      noctalia.notify(noctalia.tr("messages.window_snap_fallback"))
      annotateRegion()
      return
    end
    -- Click-to-choose: list windows, open the picker, snap on choice.
    noctalia.runAsync({ "env", "UMBRIEL_SOCKET=" .. sock, "umbriel", "windows", "--json" }, function(res)
      local list = {}
      if res.exitCode == 0 then
        local d = noctalia.json.decode(res.stdout or "")
        if type(d) == "table" then
          for _, w in ipairs(d) do
            if type(w) == "table" and w.visible == true and w.minimized ~= true and w.tab_hidden ~= true
              and type(w.id) == "string" and w.id ~= "" and type(w.w) == "number" and w.w > 0
              and type(w.h) == "number" and w.h > 0 then
              table.insert(list, {
                id = w.id,
                app = tostring(w.app_id or "?"),
                title = tostring(w.title or ""),
                focused = w.focused == true,
              })
            end
          end
        end
      end
      if #list == 0 then
        noctalia.notifyError(noctalia.tr("messages.no_window"))
        return
      end
      publish("pickList", list)
      noctalia.togglePanel(PICK_PANEL_ID)
    end, 15000)
    return
  end
  if not noctalia.commandExists("hyprctl") then
    -- No window-query API on this compositor (Wayland offers none): fall
    -- back to a manual region instead of failing.
    noctalia.notify(noctalia.tr("messages.window_snap_fallback"))
    annotateRegion()
    return
  end
  shellCapture({ SCRIPT_SHELL, "annotate-window" }, SHELL_TIMEOUT_INTERACTIVE, afterAnnotate)
end

-- ── Recording ──────────────────────────────────────────────────────────────

-- Recorder availability. `gpu-screen-recorder` (NVENC) is the best choice on
-- NVIDIA GPUs but can only capture monitors/windows — it cannot record an
-- arbitrary region — so fullscreen capture prefers it while region capture
-- falls back to wl-screenrec / wf-recorder.
local gsrAvailable = false
local wlScreenrecAvailable = false
local wfRecorderAvailable = false
local lastRecorderLog = ""

local recordState = "idle" -- idle | recording | converting | ready
local recordFormat = "mp4"
local rawPath = ""
local recordPath = ""
local recordThumbPath = ""
local recordStartedAt = nil

local function refreshRecorders()
  gsrAvailable = noctalia.commandExists("gpu-screen-recorder")
  wlScreenrecAvailable = noctalia.commandExists("wl-screenrec")
  wfRecorderAvailable = noctalia.commandExists("wf-recorder")
  local key = string.format(
    "%s|%s|%s", tostring(gsrAvailable), tostring(wlScreenrecAvailable), tostring(wfRecorderAvailable)
  )
  if key ~= lastRecorderLog then
    lastRecorderLog = key
    log("recorders: " .. key)
  end
end

local function bestFullscreenRecorder()
  if gsrAvailable then return "gpu-screen-recorder" end
  if wlScreenrecAvailable then return "wl-screenrec" end
  if wfRecorderAvailable then return "wf-recorder" end
  return ""
end

local function bestRegionRecorder()
  if wlScreenrecAvailable then return "wl-screenrec" end
  if wfRecorderAvailable then return "wf-recorder" end
  return ""
end

local function setRecordState(next)
  if recordState == next then return end
  recordState = next
  publish("recordState", recordState)
  publish("recording", recordState == "recording")
  publish("recordPath", recordPath)
  publish("recordFormat", recordFormat)
  publish("recordStartedAt", if recordState == "recording" then recordStartedAt else nil)
end

local overrideAudioOut = nil
local overrideAudioIn = nil

local function getAudioOut()
  if overrideAudioOut ~= nil then return overrideAudioOut end
  return cfg("record-audio-out") == true
end

local function getAudioIn()
  if overrideAudioIn ~= nil then return overrideAudioIn end
  return cfg("record-audio-in") == true
end

local function gsrAudioArgv()
  local audioOut = getAudioOut()
  local audioIn = getAudioIn()
  if audioOut and audioIn then
    return { "-a", "default_output|default_input", "-ac", "aac" }
  elseif audioOut then
    return { "-a", "default_output", "-ac", "aac" }
  elseif audioIn then
    return { "-a", "default_input", "-ac", "aac" }
  end
  return {}
end

-- Resolve the PulseAudio/PipeWire source for single-source wf-recorder /
-- wl-screenrec audio. Argv exec has no shell, so `$(pactl ...)` cannot be
-- embedded in the recorder command; look the device up first, then launch.
local function resolveAudioDevice(source, callback)
  local query = if source == "in" then "get-default-source" else "get-default-sink"
  noctalia.runAsync({ "pactl", query }, function(res)
    local name = trim(res.stdout or "")
    if res.exitCode ~= 0 or name == "" then
      callback(nil)
      return
    end
    callback(if source == "in" then name else name .. ".monitor")
  end)
end

local function buildRecorderArgv(bin, geom, out, device)
  local audioOut, audioIn = getAudioOut(), getAudioIn()
  local isRegion = geom and geom ~= "" and geom ~= "screen"
  local fps = tostring(cfg("record-fps") or 60)
  local codec = cfg("record-codec") or "h264"

  if bin == "gpu-screen-recorder" then
    local cursor = cursorHidden and "no" or "yes"
    local target = { "-w", "screen" }
    if isRegion then
      local gx, gy, gw, gh = tostring(geom):match("^(-?%d+),(-?%d+) (%d+)x(%d+)$")
      if gx then target = { "-w", "region", "-region", string.format("%sx%s+%s+%s", gw, gh, gx, gy) } end
    else
      local fg = focusedGeometry()
      if fg then
        local fx, fy, fw, fh = fg:match("^(-?%d+),(-?%d+) (%d+)x(%d+)$")
        if fx then target = { "-w", "region", "-region", string.format("%sx%s+%s+%s", fw, fh, fx, fy) } end
      end
    end
    local argv = { bin }
    for _, t in ipairs(target) do argv[#argv + 1] = t end
    argv[#argv + 1] = "-f"
    argv[#argv + 1] = fps
    argv[#argv + 1] = "-k"
    argv[#argv + 1] = codec
    argv[#argv + 1] = "-bm"
    argv[#argv + 1] = "qp"
    argv[#argv + 1] = "-ffmpeg-opts"
    argv[#argv + 1] = "qp=25"
    argv[#argv + 1] = "-cursor"
    argv[#argv + 1] = cursor
    argv[#argv + 1] = "-cr"
    argv[#argv + 1] = "limited"
    for _, a in ipairs(gsrAudioArgv()) do argv[#argv + 1] = a end
    argv[#argv + 1] = "-v"
    argv[#argv + 1] = "no"
    argv[#argv + 1] = "-o"
    argv[#argv + 1] = out
    return argv
  end

  local isWl = bin == "wl-screenrec"
  local argv = { bin }
  if isRegion then
    argv[#argv + 1] = "-g"
    argv[#argv + 1] = geom
  else
    local focused = noctalia.focusedOutputName()
    if focused and focused ~= "" then
      argv[#argv + 1] = "-o"
      argv[#argv + 1] = focused
    else
      local fg = focusedGeometry()
      if fg then
        argv[#argv + 1] = "-g"
        argv[#argv + 1] = fg
      end
    end
  end
  argv[#argv + 1] = "-f"
  argv[#argv + 1] = out

  if isWl then
    argv[#argv + 1] = "-m"
    argv[#argv + 1] = fps
    argv[#argv + 1] = "--codec"
    argv[#argv + 1] = if codec == "h264" then "avc" else codec
    if cursorHidden then argv[#argv + 1] = "--no-cursor" end
  else
    argv[#argv + 1] = "-r"
    argv[#argv + 1] = fps
  end

  if audioOut and audioIn then
    argv[#argv + 1] = if isWl then "--audio" else "-a"
  elseif audioOut or audioIn then
    if device and device ~= "" then
      if isWl then
        argv[#argv + 1] = "--audio"
        argv[#argv + 1] = "--audio-device"
        argv[#argv + 1] = device
      else
        argv[#argv + 1] = "--audio=" .. device
      end
    else
      argv[#argv + 1] = if isWl then "--audio" else "-a"
    end
  end

  return argv
end

local function launchRecord(geom, format, bin, device)
  rawPath = `/tmp/screen-toolkit-record-{os.time()}.mp4`
  recordFormat = if format == "gif" then "gif" else "mp4"
  publish("recordFormat", recordFormat)
  recordPath = ""
  recordThumbPath = rawPath:gsub("%.mp4$", "-thumb.png")
  publish("rawRecordPath", rawPath)
  -- Drop the previous recording's thumb now (nothing references it anymore:
  -- a new stop chain always publishes a fresh path before opening the card).
  local prevThumb = noctalia.state.get("recordThumb")
  if type(prevThumb) == "string" and prevThumb ~= "" and prevThumb ~= recordThumbPath then
    noctalia.runAsync({ "rm", "-f", prevThumb })
  end
  local argv = buildRecorderArgv(bin, geom, rawPath, device)
  log(`starting recording: {table.concat(argv, " ")}`)
  if #argv == 0 then
    rawPath = ""
    setRecordState("idle")
    noctalia.notifyError(noctalia.tr("messages.recording_failed"))
    return
  end
  -- Launch detached (no callback): the recorder keeps running after runAsync
  -- returns, exactly like the built-in screen recorder does. A tracked
  -- (callback) runAsync owns the command's process group and tears it down
  -- when it finishes, killing a backgrounded recorder. Direct exec has no
  -- wrapper shell, so the stop path's pkill matches the recorder's own
  -- `-f <rawPath>` argument.
  if not noctalia.runAsync(argv) then
    rawPath = ""
    setRecordState("idle")
    noctalia.notifyError(noctalia.tr("messages.recording_failed"))
    return
  end
  recordStartedAt = os.time()
  setRecordState("recording")
end

local function startRecord(geom, format, bin)
  refreshRecorders()
  if bin == "" then
    noctalia.notifyError(noctalia.tr("messages.no_recorder"))
    return
  end
  -- clean up old thumb so it doesn't stay stuck in preview
  if recordState ~= "idle" then return end
  local audioOut, audioIn = getAudioOut(), getAudioIn()
  if (audioOut and not audioIn) or (audioIn and not audioOut) then
    resolveAudioDevice(if audioOut then "out" else "in", function(device)
      if device == nil then log("audio device lookup failed; recording with default device") end
      launchRecord(geom, format, bin, device)
    end)
    return
  end
  launchRecord(geom, format, bin, nil)
end

local function waitForFileStable(path, callback, attempts, previousSize)
  attempts = attempts or 60
  noctalia.runAsync({ "stat", "-c", "%s", path }, function(res)
    local size = trim(res.stdout or "")
    local numSize = tonumber(size)
    if res.exitCode == 0 and numSize and numSize > 0 then
      if previousSize == numSize then
        callback(true)
        return
      end
      noctalia.runAsync({ "sleep", "0.3" }, function()
        waitForFileStable(path, callback, attempts - 1, numSize)
      end)
      return
    end
    if attempts <= 0 then
      callback(numSize ~= nil and numSize > 0)
      return
    end
    noctalia.runAsync({ "sleep", "0.2" }, function()
      waitForFileStable(path, callback, attempts - 1, previousSize)
    end)
  end)
end

local function parseRecordInfo(raw)
  local d, wh, size = tostring(raw):match("([%d%.]+)|(%d+x%d+)|(%d+)")
  local w, h = 0, 0
  if wh then
    local ww, hh = wh:match("(%d+)x(%d+)")
    w, h = tonumber(ww) or 0, tonumber(hh) or 0
  end
  return {
    duration = tonumber(d) or 0,
    width = w,
    height = h,
    size = tonumber(size) or 0,
  }
end

local function finalizeRecord(format, copyToClipboard)
  if rawPath == "" then rawPath = noctalia.state.get("rawRecordPath") or "" end
  if recordThumbPath == "" then recordThumbPath = noctalia.state.get("recordThumb") or "" end
  if rawPath == "" then return end
  local destDir = videoDir()
  local ext
  if format == "gif" then ext = ".gif" elseif format == "mov" then ext = ".mov" else ext = ".mp4" end
  local dest = destDir .. "/" .. buildFilename("record", ext)
  setRecordState("converting")
  local argv
  if format == "gif" then
    argv = { SCRIPT_RECORD, "convert-gif", rawPath, dest, tostring(cfg("gif-max-seconds") or 0) }
  elseif format == "mov" then
    argv = { SCRIPT_RECORD, "convert-mov", rawPath, dest }
  else
    argv = { SCRIPT_RECORD, "convert-mp4", rawPath, dest }
  end
  noctalia.runAsync(argv, function(res)
    if res.exitCode ~= 0 then
      setRecordState("idle")
      noctalia.notifyError(noctalia.tr("messages.recording_failed"))
      return
    end
    recordPath = dest
    rawPath = ""
    publish("rawRecordPath", "")
    if recordThumbPath ~= "" then noctalia.runAsync({ "rm", "-f", recordThumbPath }) end
    recordThumbPath = ""
    publish("recordThumb", "")
    setRecordState("idle")
    if copyToClipboard then
      copyFileUri(dest)
      noctalia.notify(noctalia.tr("panel.copied_to_clipboard"), dest)
    else
      noctalia.notify(noctalia.tr("messages.saved_to", { path = dest }))
    end
  end, 600000)
end

local function recordStop()
  -- Survive a service reload mid-recording: the shell-held state outlives
  -- our locals, so recover the raw path instead of orphaning the recorder.
  if recordState ~= "recording" and noctalia.state.get("recording") ~= true then return end
  if rawPath == "" then rawPath = noctalia.state.get("rawRecordPath") or "" end
  if rawPath == "" then
    setRecordState("idle")
    return
  end
  recordState = "recording"
  recordThumbPath = rawPath:gsub("%.mp4$", "-thumb.png")
  setRecordState("converting")
  -- No "stopped" popup: the save card appearing is the confirmation.
  -- rawPath is unique per recording, so pkill scopes to our recorder only and
  -- never touches the built-in screen recorder's process. pkill never matches
  -- itself, and direct exec leaves no wrapper shell to match either.
  noctalia.runAsync({ "pkill", "-INT", "-f", rawPath }, function()
    waitForFileStable(rawPath, function(ok)
      if not ok then
        setRecordState("idle")
        noctalia.notifyError(noctalia.tr("messages.recording_failed"))
        return
      end
      local skipConfirm = cfg("record-skip-confirmation") == true
      local toClipboard = cfg("record-copy-to-clipboard") == true
      if toClipboard then
        finalizeRecord(recordFormat, true)
      elseif skipConfirm then
        finalizeRecord(recordFormat, false)
      else
        -- Extract a mid-frame thumbnail so the result panel can preview the
        -- recording, then probe it for size / duration / resolution.
        -- Thumb path is unique per recording so overlapping stop/start
        -- chains can never steal or delete each other's preview.
        noctalia.runAsync({ SCRIPT_RECORD, "thumb", rawPath, recordThumbPath }, function(res)
          log(`thumb exit={res and res.exitCode} out={res and trim(res.stdout or "")}`)
          noctalia.runAsync({ "ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "default=noprint_wrappers=1:nokey=1", rawPath }, function(durRes)
            local duration = trim(durRes.stdout or "")
            noctalia.runAsync({ "ffprobe", "-v", "error", "-select_streams", "v:0", "-show_entries", "stream=width,height", "-of", "csv=s=x:p=0", rawPath }, function(whRes)
              local wh = trim(whRes.stdout or "")
              noctalia.runAsync({ "stat", "-c", "%s", rawPath }, function(statRes)
                local size = trim(statRes.stdout or "")
                publish("recordInfo", parseRecordInfo(`{duration}|{wh}|{size}`))
                publish("recordThumb", recordThumbPath)
                setRecordState("ready")
                noctalia.togglePanel(RESULT_PANEL_ID)
              end)
            end, 15000)
          end, 15000)
        end, 15000)
      end
    end)
  end)
end

local function recordDiscard()
  if rawPath == "" then rawPath = noctalia.state.get("rawRecordPath") or "" end
  if recordThumbPath == "" then recordThumbPath = noctalia.state.get("recordThumb") or "" end
  if rawPath ~= "" then
    noctalia.runAsync({ "rm", "-f", rawPath })
    rawPath = ""
  end
  publish("rawRecordPath", "")
  if recordThumbPath ~= "" then noctalia.runAsync({ "rm", "-f", recordThumbPath }) end
  recordThumbPath = ""
  publish("recordThumb", "")
  setRecordState("idle")
end

-- A recording that finished but was never saved is superseded the moment the
-- user runs any other capture tool; drop its temp file so the result panel
-- can't get stuck showing the stale "save recording" card.
local function discardPendingRecording()
  if recordState ~= "ready" then return end
  recordDiscard()
end

local SHARE_EXIT_KEYS = {
  [1] = "messages.share_bad_args",
  [2] = "messages.share_file_not_found",
  [3] = "messages.share_missing_dep",
  [4] = "messages.share_request_failed",
  [5] = "messages.share_invalid_response",
  [6] = "messages.share_file_too_large",
}

-- ── Sharing ────────────────────────────────────────────────────────────────

local function expirySecs(expiry, hasKey)
  if not hasKey then return 3 * 3600 end
  if expiry == "1h" then return 3600 end
  if expiry == "1d" then return 86400 end
  if expiry == "7d" then return 7 * 86400 end
  if expiry == "30d" then return 30 * 86400 end
  return nil
end

local function pushShareHistory(entry)
  local h = noctalia.state.get("shareHistory") or {}
  table.insert(h, 1, entry)
  while #h > 8 do table.remove(h) end
  publish("shareHistory", h)
  local enc = noctalia.json.encode(h)
  if enc then noctalia.writeFile(SHARE_HISTORY_FILE, enc) end
end

local function shareFile(file)
  if file == nil or file == "" then
    noctalia.notifyError(noctalia.tr("messages.share_bad_args"))
    return
  end
  if type(file) == "table" then
    file = file.path or file.file or ""
  end
  if type(file) ~= "string" or file == "" then
    noctalia.notifyError(noctalia.tr("messages.share_bad_args"))
    return
  end
  local apiKey = cfg("x02-api-key") or ""
  local expiry = cfg("x02-expiry") or "7d"
  noctalia.runAsync(
    { SCRIPT_SHARE, file, apiKey, expiry },
    function(res)
      if res.exitCode ~= 0 then
        local msg = SHARE_EXIT_KEYS[res.exitCode]
        noctalia.notifyError(if msg then noctalia.tr(msg) else noctalia.tr("messages.share_unknown_error"))
        return
      end
      local url = trim(res.stdout or "")
      if url == "" then
        noctalia.notifyError(noctalia.tr("messages.share_invalid_response"))
        return
      end
      noctalia.copyToClipboard(url, "text/plain;charset=utf-8")
      local entry = {
        url = url,
        file = file,
        time = os.time(),
        expiry = expiry,
        expirySecs = expirySecs(expiry, apiKey ~= ""),
      }
      pushShareHistory(entry)
      publish("shareResult", entry)
      publish("shareQrPath", "")
      publish("activeTool", "share")
      saveResults()
      noctalia.togglePanel(RESULT_PANEL_ID)
      if noctalia.commandExists("qrencode") then
        local qrPath = string.format("/tmp/st-share-qr-%d.png", os.time())
        noctalia.runAsync({ "qrencode", "-o", qrPath, "-s", "6", "-m", "2", url }, function(qrRes)
          if qrRes.exitCode == 0 then publish("shareQrPath", qrPath) end
        end)
      end
    end
  )
end

local function clearShareHistory()
  publish("shareHistory", {})
  publish("shareResult", nil)
  publish("shareQrPath", "")
  noctalia.writeFile(SHARE_HISTORY_FILE, "[]")
end

-- ── Result housekeeping ────────────────────────────────────────────────────

local function clearResult()
  publish("activeTool", nil)
  publish("colorResult", nil)
  publish("ocrResult", nil)
  publish("translateResult", nil)
  publish("qrResult", nil)
  publish("paletteColors", nil)
  publish("paletteCapture", nil)
  publish("annotateResult", nil)
  saveResults()
end

local function clearHistory()
  publish("colorHistory", {})
  saveResults()
end

-- ── Dispatch ───────────────────────────────────────────────────────────────

local function runRecordRegion(format)
  refreshRecorders()
  local bin = bestRegionRecorder()
  if bin == "" then noctalia.notifyError(noctalia.tr("messages.no_recorder")) return end
  slurpGeometry(function(geom) startRecord(geom, format, bin) end)
end

local function runRecordFullscreen(format)
  refreshRecorders()
  local bin = bestFullscreenRecorder()
  if bin == "" then noctalia.notifyError(noctalia.tr("messages.no_recorder")) return end
  startRecord("screen", format, bin)
end

local HANDLERS = {
  colorPicker = runColorPicker, ocr = runOcr, ocrRetry = ocrRetry, qr = runQr, palette = runPalette, lens = runLens, measure = runMeasure,
  annotate = annotateRegion, annotateFullscreen = annotateFullscreen, annotateWindow = annotateWindow,
  record = function() runRecordRegion("gif") end, recordMp4 = function() runRecordRegion("mp4") end,
  recordFullscreen = function() runRecordFullscreen("gif") end, recordFullscreenMp4 = function() runRecordFullscreen("mp4") end,
  recordStop = recordStop,
  recordSave = function(payload) finalizeRecord((type(payload) == "table" and payload.format or nil) or recordFormat, false) end,
  recordDiscard = recordDiscard,
  ocrTranslate = ocrTranslate, share = shareFile, clearShareHistory = clearShareHistory, clearResult = clearResult, clearHistory = clearHistory,
  setAudioOut = function(payload) overrideAudioOut = (type(payload) == "table" and payload.value or payload) == true end,
  setAudioIn = function(payload) overrideAudioIn = (type(payload) == "table" and payload.value or payload) == true end,
  toggle = function()
    noctalia.togglePanel(PANEL_ID)
  end,
}

-- Tools that begin a brand-new capture. Starting one discards any recording
-- that finished but was never saved, so the result panel shows the new tool's
-- result instead of the stale "save recording" card.
local CAPTURE_STARTS = {
  colorPicker = true, ocr = true, qr = true, palette = true, lens = true,
  measure = true, annotate = true, annotateFullscreen = true, annotateWindow = true,
  record = true, recordMp4 = true, recordFullscreen = true, recordFullscreenMp4 = true,
}

local function dispatch(event, payload)
  if event == nil then return end
  local handler = HANDLERS[event]
  if handler then
    if CAPTURE_STARTS[event] then discardPendingRecording() end
    log(`ipc '{event}'`)
    handler(payload)
  else
    log(`unknown command '{event}'`)
  end
end

-- UI entries drive the service through this channel; the CLI uses onIpc.
noctalia.state.watch("command", function(cmd)
  if type(cmd) == "table" then
    dispatch(cmd.action, cmd.payload)
  elseif type(cmd) == "string" then
    dispatch(cmd)
  end
end)

-- Window picker choice: snap the chosen Umbriel window and annotate it.
noctalia.state.watch("pickChoice", function(id)
  if type(id) ~= "string" or id == "" then return end
  noctalia.state.set("pickChoice", "")
  local sock = noctalia.getenv("UMBRIEL_SOCKET") or ""
  if sock == "" or not noctalia.commandExists("umbriel") then
    noctalia.notifyError(noctalia.tr("messages.missing_dep", { dep = "umbriel" }))
    return
  end
  shellCapture({ SCRIPT_SHELL, "annotate-window-id", id, sock }, SHELL_TIMEOUT_INTERACTIVE, afterAnnotate)
end)

function onIpc(event, payload)
  dispatch(event, payload)
end

-- ── Boot ───────────────────────────────────────────────────────────────────

local function pruneTmp()
  noctalia.runAsync({ "sh", "-c", "find /tmp -maxdepth 1 -name 'st-capture-*' -mtime +7 -delete; find /tmp -maxdepth 1 -name 'screen-toolkit-record-*-thumb.png' -mtime +7 -delete; find /tmp -maxdepth 1 -name 'screen-toolkit-ocr-work-*' -mtime +1 -delete; find /tmp -maxdepth 1 -name 'st-share-qr-*.png' -mtime +7 -delete; find /tmp -maxdepth 1 -name 'st-blur-*.png' -mtime +7 -delete" })
end

local function boot()
  noctalia.mkdirAll(DATA_DIR)
  pruneTmp()
  loadState()
  cursorHidden = cfg("hide-cursor") ~= false
  refreshRecorders()
end

-- Services stay alive while plugin settings change. Keep capture and recorder
-- flags in sync without requiring the user to restart Noctalia.
function onConfigChanged()
  local nextCursorHidden = cfg("hide-cursor") ~= false
  if nextCursorHidden ~= cursorHidden then
    cursorHidden = nextCursorHidden
  end
  refreshRecorders()
end

boot()
