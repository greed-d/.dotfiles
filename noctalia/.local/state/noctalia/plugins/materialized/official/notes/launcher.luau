--!nonstrict
-- Launcher quick-capture and note search.
--
-- `nt <text>` offers: append <text> to the scratchpad, create a new note from
-- it, or open an existing note whose name fuzzy-matches. With no text, it
-- lists the notes. Opening hands the target filename to the panel through
-- noctalia.state ("open_note") and toggles the panel.

local PANEL_ID = "noctalia/notes:panel"
local SCRATCHPAD_BASE = "scratchpad"
local MAX_MATCHES = 8

local lastText = ""

local function tr(key)
  return noctalia.tr(key)
end

local function settings()
  local dir = noctalia.expandPath(noctalia.getConfig("notes_dir"))
  local extension = noctalia.string.trim(noctalia.getConfig("extension")):gsub("^%.", "")
  if extension == "" then
    extension = "md"
  end
  return dir, "." .. extension
end

local function noteFiles(dir, suffix)
  local out = {}
  local list = noctalia.listDir(dir)
  if list ~= nil then
    for _, name in ipairs(list) do
      if #name > #suffix and name:sub(-#suffix) == suffix and name:sub(1, 1) ~= "." then
        table.insert(out, name)
      end
    end
    table.sort(out)
  end
  return out
end

local function loadPins(dir)
  local out = {}
  local raw = noctalia.readFile(dir .. "/.pinned.json")
  if raw ~= nil then
    local decoded = noctalia.json.decode(raw)
    if type(decoded) == "table" then
      for name, value in pairs(decoded) do
        if type(name) == "string" and value == true then
          out[name] = true
        end
      end
    end
  end
  return out
end

local function bumpNotesState()
  local bump = noctalia.state.get("notes_bump")
  noctalia.state.set("notes_bump", (type(bump) == "number" and bump or 0) + 1)
end

local function openInPanel(file)
  noctalia.state.set("open_note", file)
  noctalia.togglePanel(PANEL_ID)
end

-- Creates a timestamp-named note holding `content` and opens it in the panel.
local function createNote(content)
  local dir, suffix = settings()
  local ok, err = noctalia.mkdirAll(dir)
  if not ok then
    noctalia.notifyError(tr("title"), err or "")
    return
  end
  local base = noctalia.formatTime("%Y-%m-%d %H.%M.%S")
  local name = base .. suffix
  local counter = 2
  while noctalia.fileExists(dir .. "/" .. name) do
    name = base .. " (" .. counter .. ")" .. suffix
    counter += 1
  end
  local body = content
  if body ~= "" and body:sub(-1) ~= "\n" then
    body ..= "\n"
  end
  local wrote, werr = noctalia.writeFile(dir .. "/" .. name, body)
  if not wrote then
    noctalia.notifyError(tr("title"), werr or "")
    return
  end
  bumpNotesState()
  openInPanel(name)
end

-- Single-line, length-capped preview safe against cutting a UTF-8 sequence.
local function previewLine(text)
  local line = noctalia.string.trim(text):gsub("%s+", " ")
  if #line <= 60 then
    return line
  end
  local cut = 60
  while cut > 1 and line:byte(cut + 1) ~= nil and line:byte(cut + 1) >= 0x80 and line:byte(cut + 1) < 0xC0 do
    cut -= 1
  end
  return line:sub(1, cut) .. "…"
end

function onQuery(query)
  local text = noctalia.string.trim(query)
  lastText = text
  local dir, suffix = settings()
  local rows = {}

  if text ~= "" then
    table.insert(rows, {
      id = "append",
      title = tr("launcher.append_title"),
      subtitle = text,
      glyph = "pencil-plus",
    })
    table.insert(rows, {
      id = "create",
      title = tr("launcher.new_title"),
      subtitle = text,
      glyph = "file-plus",
    })
  else
    table.insert(rows, {
      id = "open:" .. SCRATCHPAD_BASE .. suffix,
      title = tr("scratchpad"),
      subtitle = tr("launcher.open_subtitle"),
      glyph = "pinned",
    })
    table.insert(rows, {
      id = "home",
      title = tr("launcher.home_title"),
      subtitle = tr("launcher.home_subtitle"),
      glyph = "notes",
    })
    local clip = noctalia.clipboardText()
    if type(clip) == "string" and noctalia.string.trim(clip) ~= "" then
      table.insert(rows, {
        id = "clip",
        title = tr("launcher.clip_title"),
        subtitle = previewLine(clip),
        glyph = "clipboard-plus",
      })
    end
  end

  local pins = loadPins(dir)
  local matches = {}
  for _, name in ipairs(noteFiles(dir, suffix)) do
    if name ~= SCRATCHPAD_BASE .. suffix then
      local display = name:sub(1, #name - #suffix)
      local score = text == "" and 0 or noctalia.fuzzyScore(text, display)
      if score ~= nil then
        table.insert(matches, { name = name, display = display, score = score, pinned = pins[name] == true })
      end
    end
  end
  table.sort(matches, function(a, b)
    if a.score ~= b.score then
      return a.score > b.score
    end
    if a.pinned ~= b.pinned then
      return a.pinned
    end
    return a.display < b.display
  end)
  for i = 1, math.min(#matches, MAX_MATCHES) do
    table.insert(rows, {
      id = "open:" .. matches[i].name,
      title = matches[i].display,
      subtitle = tr("launcher.open_subtitle"),
      glyph = matches[i].pinned and "pinned" or "notes",
    })
  end

  launcher.setResults(query, rows)
end

function onActivate(id)
  local dir, suffix = settings()

  if id == "append" then
    if lastText == "" then
      return
    end
    local ok, err = noctalia.mkdirAll(dir)
    if not ok then
      noctalia.notifyError(tr("title"), err or "")
      return
    end
    local path = dir .. "/" .. SCRATCHPAD_BASE .. suffix
    local contents = noctalia.readFile(path) or ""
    local sep = (contents == "" or contents:sub(-1) == "\n") and "" or "\n"
    local wrote, werr = noctalia.writeFile(path, contents .. sep .. lastText .. "\n")
    if not wrote then
      noctalia.notifyError(tr("title"), werr or "")
      return
    end
    bumpNotesState()
    noctalia.notify(tr("title"), tr("launcher.appended"))
    return
  end

  if id == "create" then
    if lastText ~= "" then
      createNote(lastText)
    end
    return
  end

  if id == "home" then
    noctalia.state.set("open_home", true)
    noctalia.togglePanel(PANEL_ID)
    return
  end

  if id == "clip" then
    local clip = noctalia.clipboardText()
    if type(clip) == "string" and noctalia.string.trim(clip) ~= "" then
      createNote(clip)
    end
    return
  end

  local file = id:match("^open:(.+)$")
  if file ~= nil then
    openInPanel(file)
  end
end
