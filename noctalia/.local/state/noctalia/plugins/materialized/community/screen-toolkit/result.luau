--!nonstrict
-- Screen Toolkit — result [[panel]].
--
-- A separate panel the [[service]] opens when a capture tool finishes. It
-- renders the result (color / OCR / QR / palette) at a comfortable size, with
-- copy / search / translate / share actions. It is a thin client: it reads the
-- published state and dispatches actions through the "command" channel.

local panelOpen = false

local recordState = noctalia.state.get("recordState") or "idle"
local recordFormat = noctalia.state.get("recordFormat") or "mp4"
local recordInfo = noctalia.state.get("recordInfo")
local saveContainerIndex = 0
local activeTool = noctalia.state.get("activeTool")
local colorResult = noctalia.state.get("colorResult")
local colorHistory = noctalia.state.get("colorHistory") or {}
local ocrResult = noctalia.state.get("ocrResult")
local ocrEditText = type(ocrResult) == "table" and ocrResult.text or ""
local translateResult = noctalia.state.get("translateResult")
local qrResult = noctalia.state.get("qrResult")
local paletteColors = noctalia.state.get("paletteColors") or {}
local ocrTab = "original"
local selectedTranslateLang = "ar"
local translateLanguages = {
  { code = "en", name = "English" },
  { code = "ar", name = "العربية" },
  { code = "fr", name = "Français" },
  { code = "de", name = "Deutsch" },
  { code = "es", name = "Español" },
  { code = "zh", name = "中文" },
  { code = "ja", name = "日本語" },
  { code = "ru", name = "Русский" },
  { code = "pt", name = "Português" },
  { code = "it", name = "Italiano" },
  { code = "tr", name = "Türkçe" },
  { code = "fa", name = "فارسی" },
  { code = "he", name = "עברית" },
  { code = "ur", name = "اردو" },
}
local render -- forward for tab callbacks inside renderOcr

-- ── Helpers ────────────────────────────────────────────────────────────────

local function tr(key, subst)
  if subst then return noctalia.tr(key, subst) end
  return noctalia.tr(key)
end

local function send(action, payload)
  noctalia.state.set("command", { action = action, payload = payload })
end

local function shellQuote(value)
  return "'" .. tostring(value):gsub("'", [['"'"']]) .. "'"
end

local function copyText(text)
  if not text or text == "" then return end
  noctalia.copyToClipboard(text, "text/plain;charset=utf-8")
end

local function isRTL(text)
  local s = tostring(text)
  -- Detect RTL scripts (Arabic, Hebrew, Persian, Urdu, etc.)
  -- Arabic U+0600-U+08FF and Hebrew U+0590-U+05FF encode as D7/D8/D9 bytes in UTF-8
  -- Look for UTF-8 lead bytes 0xD7 (215), 0xD8 (216), 0xD9 (217) followed by continuation byte
  return s:find("[\215\216\217][\128-\191]") ~= nil
end

local function actionButton(glyph, text, onClick, variant)
  return ui.button({
    glyph = glyph,
    text = text,
    controlSize = "sm",
    variant = variant or "default",
    onClick = onClick,
  })
end

-- History only stores hex, so rebuild the other formats here (mirrors the
-- service's conversions so the shown values match a fresh pick).
local function hexToRgb(hex)
  local r, g, b = tostring(hex):match("#(%x%x)(%x%x)(%x%x)")
  if not r then return 0, 0, 0 end
  return tonumber(r, 16), tonumber(g, 16), tonumber(b, 16)
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

local function showHistoryColor(hex)
  local r, g, b = hexToRgb(hex)
  local h, s, v = rgbToHsv(r, g, b)
  local hh, ss, ll = rgbToHsl(r, g, b)
  -- Publish through state: the colorResult / activeTool watches re-render, so
  -- this works without a forward reference to render().
  noctalia.state.set("activeTool", "colorpicker")
  noctalia.state.set("colorResult", {
    hex = hex,
    rgb = string.format("rgb(%d, %d, %d)", r, g, b),
    hsv = string.format("hsv(%d, %d%%, %d%%)", h, s, v),
    hsl = string.format("hsl(%d, %d%%, %d%%)", hh, ss, ll),
    capturePath = nil,
  })
end

local function refresh()
  recordState = noctalia.state.get("recordState") or "idle"
  recordFormat = noctalia.state.get("recordFormat") or "mp4"
  recordInfo = noctalia.state.get("recordInfo")
  activeTool = noctalia.state.get("activeTool")
  colorResult = noctalia.state.get("colorResult")
  colorHistory = noctalia.state.get("colorHistory") or {}
  ocrResult = noctalia.state.get("ocrResult")
  ocrEditText = type(ocrResult) == "table" and ocrResult.text or ""
  translateResult = noctalia.state.get("translateResult")
  qrResult = noctalia.state.get("qrResult")
  paletteColors = noctalia.state.get("paletteColors") or {}
end

-- ── Header ─────────────────────────────────────────────────────────────────

local function header()
  local title, glyph = tr("panel.title"), "crosshair"
  if recordState == "ready" then
    title, glyph = tr("panel.ready"), "video"
  elseif activeTool == "colorpicker" then
    title, glyph = tr("tools.colorpicker"), "palette"
  elseif activeTool == "ocr" then
    title, glyph = tr("tools.ocr"), "scan"
  elseif activeTool == "qr" then
    title, glyph = tr("tools.qr"), "qrcode"
  elseif activeTool == "palette" then
    title, glyph = tr("tools.palette"), "color-swatch"
  end
  return ui.row({ align = "center", gap = 10 }, {
    ui.column({ width = 36, height = 36, radius = 10, fill = "primary/0.15", align = "center", justify = "center" }, {
      ui.glyph({ name = glyph, size = 18, color = "primary" }),
    }),
    ui.label({ text = title, flexGrow = 1, fontSize = 16, fontWeight = "bold", color = "on_surface" }),
    ui.button({
      glyph = "trash",
      text = tr("panel.clear"),
      variant = "ghost",
      controlSize = "sm",
      tooltip = tr("panel.clear"),
      onClick = function()
        if recordState == "ready" then send("recordDiscard") else send("clearResult") end
        panel.close()
      end,
    }),
    ui.button({ glyph = "close", variant = "ghost", controlSize = "sm", onClick = function() panel.close() end }),
  })
end

-- Recording finished: preview the thumbnail, recording info, then save or
-- discard. The format (GIF / MP4) was chosen from the main panel when the
-- recording started; a video can still be finalized as MP4 or MOV.
local RECORD_THUMB_PATH = "/tmp/screen-toolkit-record-thumb.png"

local function fmtBytes(bytes)
  if bytes >= 1048576 then
    return string.format("%.1f MB", bytes / 1048576)
  end
  return string.format("%.0f KB", bytes / 1024)
end

local function fmtDuration(seconds)
  seconds = math.floor(seconds + 0.5)
  local h = math.floor(seconds / 3600)
  local m = math.floor((seconds % 3600) / 60)
  local s = seconds % 60
  if h > 0 then return string.format("%d:%02d:%02d", h, m, s) end
  return string.format("%d:%02d", m, s)
end

local function fmtRatio(w, h)
  if not w or not h or w <= 0 or h <= 0 then return "—" end
  local a, b = w, h
  while b ~= 0 do a, b = b, a % b end
  return string.format("%d:%d", w / a, h / a)
end

local function infoTile(label, value)
  return ui.column({ flexGrow = 1, gap = 2, align = "center", paddingH = 6, paddingV = 8, radius = 10, fill = "surface_variant/0.25" }, {
    ui.label({ text = label, fontSize = 10, color = "on_surface_variant" }),
    ui.label({ text = value or "—", fontSize = 13, fontWeight = "bold" }),
  })
end

local function recordSaveCard()
  local isGif = recordFormat == "gif"
  local info = recordInfo or {}
  local actions = {}
  if isGif then
    table.insert(actions, ui.label({
      text = tr("tools.record_gif"),
      flexGrow = 1,
      fontSize = 12,
      color = "on_surface_variant",
    }))
  else
    table.insert(actions, ui.select({
      options = { "MP4", "MOV" },
      selectedIndex = saveContainerIndex,
      controlSize = "sm",
      width = 96,
      onChange = function(value)
        saveContainerIndex = tonumber(value) or 0
      end,
    }))
  end
  table.insert(actions, actionButton("download", tr("panel.save"), function()
    if isGif then
      send("recordSave")
    else
      send("recordSave", { format = saveContainerIndex == 0 and "mp4" or "mov" })
    end
  end, "primary"))
  table.insert(actions, actionButton("trash", tr("panel.discard"), function()
    send("recordDiscard")
  end, "ghost"))
  return ui.column({ flexGrow = 1, gap = 10 }, {
    ui.image({ path = RECORD_THUMB_PATH, height = 220, fit = "contain", radius = 12, borderWidth = 1, border = "outline" }),
    ui.row({ gap = 8 }, {
      infoTile(tr("panel.record_size"), fmtBytes(info.size or 0)),
      infoTile(tr("panel.record_duration"), fmtDuration(info.duration or 0)),
      infoTile(tr("panel.record_ratio"), fmtRatio(info.width, info.height)),
    }),
    ui.row({ gap = 6, align = "center" }, actions),
  })
end

-- ── Result views ───────────────────────────────────────────────────────────

local function emptyState(glyph, text)
  return ui.column({ flexGrow = 1, gap = 10, align = "center", justify = "center" }, {
    ui.glyph({ name = glyph, size = 30, color = "outline" }),
    ui.label({ text = text, fontSize = 12, color = "on_surface_variant" }),
  })
end

local function colorFormatRow(name, value)
  return ui.row({ gap = 8, align = "center", paddingH = 10, paddingV = 8, radius = 10, fill = "surface_variant/0.25" }, {
    ui.label({ text = name, width = 40, fontSize = 12, fontWeight = "bold", color = "on_surface_variant" }),
    ui.label({ text = value, flexGrow = 1, fontSize = 12 }),
    ui.button({ glyph = "copy", variant = "ghost", onClick = function() copyText(value) end }),
  })
end

local function colorHistoryRow()
  if #colorHistory == 0 then
    return ui.label({ text = tr("panel.no_history"), fontSize = 12, color = "muted" })
  end
  local swatches = {}
  for i = #colorHistory, 1, -1 do
    local hex = colorHistory[i]
    table.insert(swatches, ui.column({
      key = "hist-" .. hex,
      flexGrow = 1,
      gap = 4,
      align = "center",
      onClick = function() showHistoryColor(hex) end,
    }, {
      ui.box({ width = 26, height = 26, radius = 8, fill = hex, borderWidth = 1, border = "outline" }),
    }))
  end
  return ui.row({ gap = 8 }, swatches)
end

local function renderColor()
  if not colorResult then
    return emptyState("palette", tr("panel.no_color"))
  end
  local c = colorResult
  return ui.column({ flexGrow = 1, gap = 10 }, {
    ui.row({ gap = 12, align = "center" }, {
      ui.box({ key = "swatch", width = 76, height = 50, radius = 12, fill = c.hex, borderWidth = 2, border = "outline" }),
      ui.column({ flexGrow = 1, gap = 2 }, {
        ui.label({ text = c.hex, fontSize = 18, fontWeight = "bold", color = "on_surface" }),
        ui.label({ text = c.rgb, fontSize = 11, color = "on_surface_variant" }),
      }),
      ui.column({ align = "end", gap = 4 }, {
        actionButton("color-picker", tr("panel.pick_again"), function() send("colorPicker"); panel.close() end),
        actionButton("trash", tr("panel.clear"), function() send("clearResult"); panel.close() end, "ghost"),
      }),
    }),
    ui.row({ gap = 6 }, {
      actionButton("copy", tr("panel.copy_all"), function()
        copyText(string.format("%s\n%s\n%s\n%s", c.hex, c.rgb, c.hsl, c.hsv))
      end),
      actionButton("share", tr("panel.share"), function() send("share", c.capturePath) end),
    }),
    ui.separator({ spacing = 4 }),
    colorFormatRow("HEX", c.hex),
    colorFormatRow("RGB", c.rgb),
    colorFormatRow("HSL", c.hsl),
    colorFormatRow("HSV", c.hsv),
    ui.separator({ spacing = 4 }),
    ui.column({ gap = 6 }, {
      ui.row({ align = "center", justify = "space_between", gap = 8 }, {
        ui.label({ text = tr("panel.history"), fontSize = 12, fontWeight = "bold", color = "on_surface_variant" }),
        ui.button({ text = tr("panel.clear_history"), controlSize = "sm", variant = "ghost", onClick = function() send("clearHistory") end }),
      }),
      colorHistoryRow(),
    }),
  })
end

local function renderOcr()
  if not ocrResult then
    return emptyState("scan", tr("panel.no_result"))
  end
  local text = ocrEditText or ""
  local url = text:match("https?://[^%s]+")
  if not url then
    local bare = text:match("www%.[%w%-%.]+[^%s]*")
    if bare then url = "https://" .. bare end
  end
  local email = text:match("[%w%._%%+%-]+@[%w%.%-]+%.[%a][%a]+")
  local imgW = tonumber(ocrResult.gw) or 0
  local imgH = tonumber(ocrResult.gh) or 0
  local imgHeight = 90
  if imgW > 0 and imgH > 0 then
    imgHeight = math.max(70, math.min(140, math.floor(360 * (imgH / imgW))))
  end
  local lineCount = 1
  for _ in tostring(text):gmatch("\n") do lineCount = lineCount + 1 end
  lineCount = lineCount + math.floor(#text / 60)
  local inputHeight = math.max(70, math.min(180, lineCount * 20 + 32))
  local hasTranslation = translateResult and translateResult ~= ""
  if hasTranslation and ocrTab ~= "original" and ocrTab ~= "translation" then ocrTab = "original" end
  local scrollChildren = {}
  -- Source image card — tinted to differentiate from editable output
  if ocrResult.capturePath and ocrResult.capturePath ~= "" then
    table.insert(scrollChildren, ui.row({ justify = "space_between", align = "center" }, {
      ui.row({ gap = 6, align = "center" }, {
        ui.glyph({ name = "photo", size = 14, color = "primary" }),
        ui.label({ text = tr("panel.ocr_source") ~= "panel.ocr_source" and tr("panel.ocr_source") or "Source", fontSize = 11, fontWeight = "bold", color = "on_surface_variant" }),
      }),
      ui.label({ text = imgW > 0 and string.format("%dx%d", imgW, imgH) or "", fontSize = 10, color = "on_surface_variant" }),
    }))
    table.insert(scrollChildren, ui.column({ fill = "surface_variant/0.35", radius = 12, padding = 6, borderWidth = 1, border = "outline" }, {
      ui.image({
        key = "ocr-image-" .. tostring(ocrResult.cacheBust or ocrResult.capturePath),
        path = ocrResult.capturePath,
        height = imgHeight,
        fit = "contain",
        radius = 8,
      }),
    }))
  end
  table.insert(scrollChildren, ui.row({ justify = "space_between", align = "center" }, {
    ui.row({ gap = 6, align = "center" }, {
      ui.glyph({ name = "edit", size = 14, color = "primary" }),
      ui.label({ text = tr("panel.ocr_text"), fontSize = 11, fontWeight = "bold", color = "on_surface_variant" }),
    }),
    ui.button({ glyph = "copy", variant = "ghost", controlSize = "sm", tooltip = tr("panel.copy_text"), onClick = function() copyText(ocrEditText) end }),
  }))
  table.insert(scrollChildren, ui.input({
    key = "ocr-edit-" .. tostring(ocrResult.cacheBust or "current"),
    value = text,
    multiline = true,
    height = inputHeight,
    flexGrow = 1,
    onChange = function(value) ocrEditText = value or "" end,
  }))
  if hasTranslation then
    local rtl = isRTL(translateResult)
    local displayText = tostring(translateResult):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
    table.insert(scrollChildren, ui.separator({ spacing = 6 }))
    table.insert(scrollChildren, ui.row({ justify = "space_between", align = "center" }, {
      ui.label({ text = tr("panel.translation"), fontSize = 11, fontWeight = "bold", color = "primary" }),
      ui.button({ glyph = "copy", variant = "ghost", controlSize = "sm", tooltip = tr("panel.copy_text"), onClick = function() copyText(displayText) end }),
    }))
    table.insert(scrollChildren, ui.column({
        fill = "surface_variant/0.25",
        radius = 10,
        paddingH = 10,
        paddingV = 8,
        flexGrow = 1,
      }, {
        ui.label({
          text = displayText,
          fontSize = 13,
          textAlign = if rtl then "right" else "left",
          fontFamily = if rtl then "Noto Naskh Arabic" else nil,
        }),
      }))
  end
  -- Controls — icon-only with tooltips + searchable language picker (replaces raw "ar" input)
  local langOptions = {}
  local langCodes = {}
  for _, l in ipairs(translateLanguages) do
    table.insert(langOptions, l.code .. " — " .. l.name)
    table.insert(langCodes, l.code)
  end
  local selectedIdx = 0
  for i, c in ipairs(langCodes) do if c == selectedTranslateLang then selectedIdx = i - 1; break end end
  local controls = {
    ui.button({ glyph = "copy", variant = "ghost", controlSize = "sm", tooltip = tr("panel.copy_text"), onClick = function() copyText(ocrTab == "translation" and translateResult or ocrEditText) end }),
  }
  if url then
    table.insert(controls, ui.button({ glyph = "external-link", variant = "ghost", controlSize = "sm", tooltip = tr("panel.open_url"), onClick = function() noctalia.runAsync("xdg-open " .. shellQuote(url)) end }))
  elseif email then
    table.insert(controls, ui.button({ glyph = "mail", variant = "ghost", controlSize = "sm", tooltip = tr("panel.compose_mail"), onClick = function() noctalia.runAsync("xdg-open " .. shellQuote("mailto:" .. email)) end }))
  end
  table.insert(controls, ui.button({ glyph = "search", variant = "ghost", controlSize = "sm", tooltip = tr("panel.search_text"), onClick = function() send("ocrSearch", { text = ocrEditText }) end }))
  table.insert(controls, ui.button({ glyph = "share", variant = "ghost", controlSize = "sm", tooltip = tr("panel.share"), onClick = function() send("share", ocrResult.capturePath) end }))
  table.insert(controls, ui.spacer({ flexGrow = 1 }))
  table.insert(controls, ui.select({
    options = langOptions,
    selectedIndex = selectedIdx,
    width = 160,
    controlSize = "sm",
    onChange = function(value)
      local idx = tonumber(value) or 0
      selectedTranslateLang = langCodes[idx + 1] or "en"
      render()
    end,
  }))
  table.insert(controls, ui.button({ glyph = "language", variant = "primary", controlSize = "sm", tooltip = tr("panel.translate"), onClick = function() send("ocrTranslate", { lang = selectedTranslateLang, text = ocrEditText }) end }))
  return ui.column({ flexGrow = 1, gap = 8 }, {
    ui.row({ gap = 4, align = "center" }, controls),
    ui.scroll({ flexGrow = 1, gap = 8 }, scrollChildren),
  })
end

local function renderQr()
  if not qrResult then
    return emptyState("qrcode", tr("panel.no_result"))
  end
  local text = qrResult.text or ""
  local isUrl = text:sub(1, 4) == "http"
  local buttons = {
    actionButton("copy", tr("panel.copy_text"), function() copyText(text) end),
  }
  if isUrl then
    table.insert(buttons, actionButton("external-link", tr("panel.open_url"), function()
      noctalia.runAsync("xdg-open " .. shellQuote(text))
    end))
  end
  table.insert(buttons, actionButton("share", tr("panel.share"), function() send("share", qrResult.capturePath) end))
  return ui.column({ flexGrow = 1, gap = 8 }, {
    ui.row({ gap = 6 }, buttons),
    ui.scroll({ flexGrow = 1, gap = 8 }, {
      ui.image({ path = qrResult.capturePath, height = 110, fit = "contain", radius = 12, borderWidth = 1, border = "outline" }),
      ui.label({ text = text, fontSize = 13 }),
    }),
  })
end

local function renderPalette()
  if #paletteColors == 0 then
    return emptyState("color-swatch", tr("panel.no_result"))
  end
  local tiles = {}
  for i, hex in ipairs(paletteColors) do
    table.insert(tiles, ui.column({
      key = "pal-" .. i,
      flexGrow = 1,
      gap = 5,
      align = "center",
      paddingV = 8,
      radius = 12,
      fill = "surface_variant/0.25",
      borderWidth = 1,
      border = "outline",
      onClick = function() copyText(hex) end,
    }, {
      ui.box({ width = 34, height = 34, radius = 10, fill = hex, borderWidth = 1, border = "outline" }),
      ui.label({ text = hex, fontSize = 9, color = "on_surface_variant" }),
    }))
  end
  return ui.column({ flexGrow = 1, gap = 8 }, {
    ui.row({ gap = 6 }, {
      actionButton("copy", tr("panel.copy_hex_list"), function()
        copyText(table.concat(paletteColors, "\n"))
      end),
      actionButton("code", tr("panel.copy_css_vars"), function()
        local buf = {}
        for i, hex in ipairs(paletteColors) do buf[#buf + 1] = `--palette-{i}: {hex};` end
        copyText(table.concat(buf, "\n"))
      end),
      actionButton("share", tr("panel.share"), function() send("share", "/tmp/screen-toolkit-palette.png") end),
    }),
    ui.row({ gap = 6 }, tiles),
  })
end

-- ── Render ─────────────────────────────────────────────────────────────────

local function body()
  if recordState == "ready" then
    return recordSaveCard()
  elseif activeTool == "colorpicker" then
    return renderColor()
  elseif activeTool == "ocr" then
    return renderOcr()
  elseif activeTool == "qr" then
    return renderQr()
  elseif activeTool == "palette" then
    return renderPalette()
  end
  return emptyState("crosshair", tr("panel.empty"))
end

render = function()
  panel.render(ui.column({ flexGrow = 1, gap = 10 }, {
    header(),
    body(),
  }))
end

-- ── Lifecycle ──────────────────────────────────────────────────────────────

function onOpen(_context)
  panelOpen = true
  refresh()
  render()
end

function onClose()
  panelOpen = false
end

noctalia.state.watch("recordState", function(v)
  if recordState == "ready" and v ~= "ready" then
    panel.close()
    return
  end
  recordState = v or "idle"
  if panelOpen then render() end
end)
noctalia.state.watch("recordFormat", function(v) recordFormat = v or "mp4"; if panelOpen then render() end end)
noctalia.state.watch("recordInfo", function(v) recordInfo = v; if panelOpen then render() end end)
noctalia.state.watch("activeTool", function(v) activeTool = v; if panelOpen then render() end end)
noctalia.state.watch("colorResult", function(v) colorResult = v; if panelOpen then render() end end)
noctalia.state.watch("colorHistory", function(v) colorHistory = v or {}; if panelOpen then render() end end)
noctalia.state.watch("ocrResult", function(v)
  ocrResult = v
  ocrEditText = type(v) == "table" and v.text or ""
  if panelOpen then render() end
end)
noctalia.state.watch("translateResult", function(v)
  translateResult = v
  if panelOpen then render() end
end)
noctalia.state.watch("qrResult", function(v) qrResult = v; if panelOpen then render() end end)
noctalia.state.watch("paletteColors", function(v) paletteColors = v or {}; if panelOpen then render() end end)
