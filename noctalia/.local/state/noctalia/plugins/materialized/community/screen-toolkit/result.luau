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
local recordThumb = noctalia.state.get("recordThumb")
local rawRecordPath = noctalia.state.get("rawRecordPath")
local saveContainerIndex = 0
local activeTool = noctalia.state.get("activeTool")
local colorResult = noctalia.state.get("colorResult")
local colorHistory = noctalia.state.get("colorHistory") or {}
local ocrResult = noctalia.state.get("ocrResult")
local ocrEditText = type(ocrResult) == "table" and ocrResult.text or ""
local translateResult = noctalia.state.get("translateResult")
local qrResult = noctalia.state.get("qrResult")
local paletteColors = noctalia.state.get("paletteColors") or {}
local paletteCapture = noctalia.state.get("paletteCapture")
local shareResult = noctalia.state.get("shareResult")
local shareQrPath = noctalia.state.get("shareQrPath") or ""
local shareHistory = noctalia.state.get("shareHistory") or {}
local selectedTranslateLang = "ar"
local selectedOcrPsm = nil
local selectedOcrLang = noctalia.getConfig("selected-ocr-lang") or "eng"
local translateLanguages = {
  { code = "en", tess = "eng", name = "English" },
  { code = "ar", tess = "ara", name = "العربية" },
  { code = "fr", tess = "fra", name = "Français" },
  { code = "de", tess = "deu", name = "Deutsch" },
  { code = "es", tess = "spa", name = "Español" },
  { code = "zh", tess = "chi_sim", name = "中文" },
  { code = "ja", tess = "jpn", name = "日本語" },
  { code = "ru", tess = "rus", name = "Русский" },
  { code = "pt", tess = "por", name = "Português" },
  { code = "it", tess = "ita", name = "Italiano" },
  { code = "tr", tess = "tur", name = "Türkçe" },
  { code = "fa", tess = "fas", name = "فارسی" },
  { code = "he", tess = "heb", name = "עברית" },
  { code = "ur", tess = "urd", name = "اردو" },
}
local tessByCode = {}
for _, l in ipairs(translateLanguages) do tessByCode[l.code] = l.tess end
local codeByTess = {}
for _, l in ipairs(translateLanguages) do codeByTess[l.tess] = l.code end
local render -- forward for tab callbacks inside renderOcr

-- ── Helpers ────────────────────────────────────────────────────────────────

local function tr(key, subst)
  if subst then return noctalia.tr(key, subst) end
  return noctalia.tr(key)
end

local function send(action, payload)
  noctalia.state.set("command", { action = action, payload = payload })
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
  recordThumb = noctalia.state.get("recordThumb")
  rawRecordPath = noctalia.state.get("rawRecordPath")
  activeTool = noctalia.state.get("activeTool")
  colorResult = noctalia.state.get("colorResult")
  colorHistory = noctalia.state.get("colorHistory") or {}
  ocrResult = noctalia.state.get("ocrResult")
  ocrEditText = type(ocrResult) == "table" and ocrResult.text or ""
  translateResult = noctalia.state.get("translateResult")
  qrResult = noctalia.state.get("qrResult")
  paletteColors = noctalia.state.get("paletteColors") or {}
  paletteCapture = noctalia.state.get("paletteCapture")
  shareResult = noctalia.state.get("shareResult")
  shareQrPath = noctalia.state.get("shareQrPath") or ""
  shareHistory = noctalia.state.get("shareHistory") or {}
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
  elseif activeTool == "share" then
    title, glyph = tr("panel.share_title"), "share"
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
  return ui.column({ flexGrow = 1, gap = 2, align = "center", paddingH = 6, paddingV = 8, radius = 10, fill = "surface_container/0.25" }, {
    ui.label({ text = label, fontSize = 10, color = "on_surface_variant" }),
    ui.label({ text = value or "—", fontSize = 13, fontWeight = "bold" }),
  })
end

local function recordSaveCard()
  local isGif = recordFormat == "gif"
  local info = recordInfo or {}
  local actions = {}
  local rawPath = (rawRecordPath and rawRecordPath ~= "") and rawRecordPath or nil
  local function preview()
    if not rawPath then return end
    noctalia.runAsync({ "xdg-open", rawPath })
  end
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
        render()
      end,
    }))
  end
  table.insert(actions, actionButton("player-play", tr("panel.preview"), function()
    preview()
  end))
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
  local thumbPath = (recordThumb and recordThumb ~= "") and recordThumb or RECORD_THUMB_PATH
  local hasThumb = (noctalia.fileExists == nil) or noctalia.fileExists(thumbPath)
  local thumbEl = hasThumb
    and ui.image({ path = thumbPath, height = 280, fit = "contain", radius = 12, borderWidth = 1, border = "outline_variant" })
    or ui.column({ height = 120, align = "center", justify = "center", gap = 6, radius = 12, fill = "surface_container/0.25" }, {
      ui.glyph({ name = "video", size = 28, color = "on_surface_variant" }),
      ui.label({ text = tr("panel.no_preview"), fontSize = 11, color = "on_surface_variant" }),
    })
  if rawPath then thumbEl = ui.column({ onClick = preview, tooltip = tr("panel.click_to_play") }, { thumbEl }) end
  local estimateRow = nil
  if isGif then
    local cap = noctalia.getConfig("gif-max-seconds") or 30
    estimateRow = ui.label({ text = tr("panel.gif_estimate", { secs = tostring(cap) }), fontSize = 11, color = "on_surface_variant" })
  end
  local cardChildren = {
    thumbEl,
    ui.row({ gap = 8 }, {
      infoTile(tr("panel.record_size"), fmtBytes(info.size or 0)),
      infoTile(tr("panel.record_duration"), fmtDuration(info.duration or 0)),
      infoTile(tr("panel.record_ratio"), fmtRatio(info.width, info.height)),
    }),
  }
  if estimateRow then table.insert(cardChildren, estimateRow) end
  table.insert(cardChildren, ui.row({ gap = 6, align = "center" }, actions))
  return ui.column({ gap = 10 }, cardChildren)
end

-- ── Result views ───────────────────────────────────────────────────────────

local function emptyState(glyph, text)
  return ui.column({ gap = 10, minHeight = 120, align = "center", justify = "center" }, {
    ui.glyph({ name = glyph, size = 30, color = "outline_variant" }),
    ui.label({ text = text, fontSize = 12, color = "on_surface_variant" }),
  })
end

local function colorFormatRow(name, value)
  return ui.row({ gap = 8, align = "center", paddingH = 10, paddingV = 8, radius = 10, fill = "surface_container/0.25" }, {
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
      ui.box({ width = 26, height = 26, radius = 8, fill = hex, borderWidth = 1, border = "outline_variant" }),
    }))
  end
  return ui.row({ gap = 8 }, swatches)
end

local function renderColor()
  if not colorResult then
    return emptyState("palette", tr("panel.no_color"))
  end
  local c = colorResult
  return ui.column({ gap = 10 }, {
    ui.row({ gap = 12, align = "center" }, {
      ui.box({ key = "swatch", width = 76, height = 50, radius = 12, fill = c.hex, borderWidth = 2, border = "outline_variant" }),
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
    table.insert(scrollChildren, ui.column({ fill = "surface_container/0.35", radius = 12, padding = 6, borderWidth = 1, border = "outline_variant" }, {
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
        fill = "surface_container/0.25",
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
  -- Controls — same language options for translate + OCR retry (codes only),
  -- one row. OCR sends the mapped Tesseract code, so no more typos → errors.
  local langOptions = {}
  local langCodes = {}
  for _, l in ipairs(translateLanguages) do
    table.insert(langOptions, l.code .. " — " .. l.name)
    table.insert(langCodes, l.code)
  end
  local selectedIdx = 0
  for i, c in ipairs(langCodes) do if c == selectedTranslateLang then selectedIdx = i - 1; break end end
  local ocrCode = codeByTess[selectedOcrLang] or selectedOcrLang
  local ocrLangIdx = 0
  for i, c in ipairs(langCodes) do if c == ocrCode then ocrLangIdx = i - 1; break end end
  -- Single tool row: [translate group] + [retry group]. Retry re-runs on
  -- the same pixels, no recapture.
  local psmOptions = { tr("panel.auto"), "3", "6", "7", "11" }
  local psmIdx = 0
  if selectedOcrPsm == "3" then psmIdx = 1
  elseif selectedOcrPsm == "6" then psmIdx = 2
  elseif selectedOcrPsm == "7" then psmIdx = 3
  elseif selectedOcrPsm == "11" then psmIdx = 4 end
  local toolRowItems = {}
  if url then
    table.insert(toolRowItems, ui.button({ glyph = "external-link", variant = "ghost", controlSize = "sm", tooltip = tr("panel.open_url"), onClick = function() noctalia.runAsync({ "xdg-open", url }) end }))
  elseif email then
    table.insert(toolRowItems, ui.button({ glyph = "mail", variant = "ghost", controlSize = "sm", tooltip = tr("panel.compose_mail"), onClick = function() noctalia.runAsync({ "xdg-open", "mailto:" .. email }) end }))
  end
  table.insert(toolRowItems, ui.label({ text = tr("panel.retry"), fontSize = 11, color = "on_surface_variant" }))
  table.insert(toolRowItems, ui.select({
    options = psmOptions,
    selectedIndex = psmIdx,
    width = 76,
    controlSize = "sm",
    onChange = function(value)
      local idx = tonumber(value) or 0
      selectedOcrPsm = if idx == 0 then nil else psmOptions[idx + 1]
      render()
    end,
  }))
  table.insert(toolRowItems, ui.select({
    options = langCodes,
    selectedIndex = ocrLangIdx,
    width = 64,
    controlSize = "sm",
    onChange = function(value)
      local idx = tonumber(value) or 0
      selectedOcrLang = langCodes[idx + 1] or selectedOcrLang
      render()
    end,
  }))
  table.insert(toolRowItems, ui.button({ glyph = "refresh", variant = "default", controlSize = "sm", tooltip = tr("panel.retry"), onClick = function() send("ocrRetry", { psm = selectedOcrPsm, lang = tessByCode[selectedOcrLang] or selectedOcrLang }) end }))
  table.insert(toolRowItems, ui.spacer({ flexGrow = 1 }))
  table.insert(toolRowItems, ui.label({ text = tr("panel.translate"), fontSize = 11, color = "on_surface_variant" }))
  table.insert(toolRowItems, ui.select({
    options = langOptions,
    selectedIndex = selectedIdx,
    width = 200,
    controlSize = "sm",
    onChange = function(value)
      local idx = tonumber(value) or 0
      selectedTranslateLang = langCodes[idx + 1] or "en"
      render()
    end,
  }))
  table.insert(toolRowItems, ui.button({ glyph = "language", variant = "primary", controlSize = "sm", tooltip = tr("panel.translate"), onClick = function() send("ocrTranslate", { lang = selectedTranslateLang, text = ocrEditText }) end }))
  return ui.column({ gap = 8 }, {
    ui.row({ gap = 6, align = "center" }, toolRowItems),
    ui.column({ gap = 8 }, scrollChildren),
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
      noctalia.runAsync({ "xdg-open", text })
    end))
  end
  return ui.column({ gap = 8 }, {
    ui.row({ gap = 6 }, buttons),
    ui.column({ gap = 8 }, {
      ui.image({ path = qrResult.capturePath, height = 110, fit = "contain", radius = 12, borderWidth = 1, border = "outline_variant" }),
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
      fill = "surface_container/0.25",
      borderWidth = 1,
      border = "outline_variant",
      onClick = function() copyText(hex) end,
    }, {
      ui.box({ width = 34, height = 34, radius = 10, fill = hex, borderWidth = 1, border = "outline_variant" }),
      ui.label({ text = hex, fontSize = 9, color = "on_surface_variant" }),
    }))
  end
  return ui.column({ gap = 8 }, {
    ui.row({ gap = 6 }, {
      actionButton("copy", tr("panel.copy_hex_list"), function()
        copyText(table.concat(paletteColors, "\n"))
      end),
      actionButton("code", tr("panel.copy_css_vars"), function()
        local buf = {}
        for i, hex in ipairs(paletteColors) do buf[#buf + 1] = `--palette-{i}: {hex};` end
        copyText(table.concat(buf, "\n"))
      end),
      actionButton("share", tr("panel.share"), function()
        if paletteCapture and paletteCapture ~= "" then send("share", paletteCapture) end
      end),
    }),
    ui.row({ gap = 6 }, tiles),
  })
end

-- ── Render ─────────────────────────────────────────────────────────────────

local function fmtExpiry(entry)
  if not entry or not entry.expirySecs then return tr("panel.permanent_link") end
  local left = (entry.time + entry.expirySecs) - os.time()
  if left <= 0 then return tr("panel.expired") end
  local h = math.floor(left / 3600)
  local m = math.floor((left % 3600) / 60)
  local label = h > 0 and (h .. "h " .. m .. "m") or (m .. "m")
  return tr("panel.expires_in", { time = label })
end

local function renderShare()
  if not shareResult or not shareResult.url then
    return emptyState("share", tr("panel.no_share_history"))
  end
  local url = shareResult.url
  local top = {
    ui.label({ text = url, fontSize = 12, color = "primary" }),
    ui.row({ gap = 6 }, {
      actionButton("copy", tr("panel.copy_link"), function() copyText(url) end),
      actionButton("external-link", tr("panel.open_url"), function() noctalia.runAsync({ "xdg-open", url }) end),
    }),
    ui.label({ text = fmtExpiry(shareResult), fontSize = 11, color = "on_surface_variant" }),
  }
  local hasQr = shareQrPath and shareQrPath ~= "" and (noctalia.fileExists == nil or noctalia.fileExists(shareQrPath))
  if hasQr then
    table.insert(top, ui.column({ gap = 4, align = "center" }, {
      ui.image({ path = shareQrPath, width = 180, height = 180, fit = "contain", radius = 12, borderWidth = 1, border = "outline_variant" }),
      ui.label({ text = tr("panel.qr_scan"), fontSize = 11, color = "on_surface_variant" }),
    }))
  end
  if #shareHistory > 1 then
    local rows = {}
    for i, h in ipairs(shareHistory) do
      if i > 1 and type(h) == "table" and h.url then
        local u = h.url
        table.insert(rows, ui.row({
          key = "share-hist-" .. i, gap = 8, align = "center",
          paddingV = 6, paddingH = 10, radius = 10, fill = "surface_container/0.25",
          onClick = function() copyText(u) end,
        }, {
          ui.label({ text = u, flexGrow = 1, fontSize = 11, maxLines = 1 }),
        }))
      end
    end
    if #rows > 0 then
      table.insert(top, ui.row({ align = "center", justify = "space_between", gap = 8 }, {
        ui.label({ text = tr("panel.share_history"), fontSize = 12, fontWeight = "bold", color = "on_surface_variant" }),
        ui.button({ text = tr("panel.clear_share_history"), controlSize = "sm", variant = "ghost", onClick = function() send("clearShareHistory") end }),
      }))
      table.insert(top, ui.column({ gap = 6 }, rows))
    end
  else
    table.insert(top, ui.row({ align = "center", justify = "space_between", gap = 8 }, {
      ui.label({ text = tr("panel.share_history"), fontSize = 12, fontWeight = "bold", color = "on_surface_variant" }),
      ui.button({ text = tr("panel.clear_share_history"), controlSize = "sm", variant = "ghost", onClick = function() send("clearShareHistory") end }),
    }))
  end
  return ui.column({ gap = 8 }, top)
end

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
  elseif activeTool == "share" then
    return renderShare()
  end
  return emptyState("crosshair", tr("panel.empty"))
end

render = function()
  panel.render(ui.column({ gap = 10 }, {
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
  -- Closing the card discards the recording as if it never happened.
  -- The explicit way to keep it is Save/Copy.
  if recordState == "ready" then send("recordDiscard") end
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
noctalia.state.watch("recordThumb", function(v) recordThumb = v; if panelOpen then render() end end)
noctalia.state.watch("rawRecordPath", function(v) rawRecordPath = v; if panelOpen then render() end end)
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
noctalia.state.watch("paletteCapture", function(v) paletteCapture = v; if panelOpen then render() end end)
noctalia.state.watch("shareResult", function(v) shareResult = v; if panelOpen then render() end end)
noctalia.state.watch("shareQrPath", function(v) shareQrPath = v or ""; if panelOpen then render() end end)
noctalia.state.watch("shareHistory", function(v) shareHistory = v or {}; if panelOpen then render() end end)
