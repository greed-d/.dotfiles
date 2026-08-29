--!nonstrict
-- Markdown notes in a full-height side panel.
--
-- Notes are plain .md files in the configured notes directory. The panel shows
-- a note list and a multiline editor with idle autosave (flushes after a short
-- pause in typing, on navigation, and on panel close).

local AUTOSAVE_IDLE_TICKS = 2 -- 1s panel ticks with no edits before a flush
local SCRATCHPAD_BASE = "scratchpad"

local notesDir = ""
local suffix = ".md" -- "." .. the configured extension, resolved in onOpen
local files = {}
local view = "list" -- "list" | "editor"
local current = nil -- filename ("foo.md") while the editor is open
local buffer = ""
local loadedContent = "" -- what the file held when we last read/wrote it
local editorRev = 0 -- bumped to reseed the editor input after external changes
local dirty = false
local idleTicks = 0
local pendingDelete = nil -- filename awaiting the second (confirm) click
local sortByDate = false
local pins = {} -- filename -> true; persisted in a sidecar next to the notes

local render

local function tr(key)
  return noctalia.tr(key)
end

local function displayName(file)
  return file:sub(1, #file - #suffix)
end

local function hasSuffix(name)
  return #name > #suffix and name:sub(-#suffix) == suffix
end

local function notePath(file)
  return notesDir .. "/" .. file
end

local function scratchName()
  return SCRATCHPAD_BASE .. suffix
end

-- Pins live in a hidden sidecar inside the notes directory so they sync and
-- survive restarts with the notes themselves.
local function pinsPath()
  return notesDir .. "/.pinned.json"
end

local function loadPins()
  pins = {}
  local raw = noctalia.readFile(pinsPath())
  if raw ~= nil then
    local decoded = noctalia.json.decode(raw)
    if type(decoded) == "table" then
      for name, value in pairs(decoded) do
        if type(name) == "string" and value == true then
          pins[name] = true
        end
      end
    end
  end
end

local function savePins()
  local encoded = noctalia.json.encode(pins)
  if encoded == nil then
    return
  end
  local ok, err = noctalia.writeFile(pinsPath(), encoded)
  if not ok then
    noctalia.notifyError(tr("title"), err or "")
  end
end

local function refreshFiles()
  files = {}
  local list = noctalia.listDir(notesDir)
  if list ~= nil then
    for _, name in ipairs(list) do
      if hasSuffix(name) and name ~= scratchName() and name:sub(1, 1) ~= "." then
        table.insert(files, name)
      end
    end
  end
  -- Pinned notes first, then the selected order within each group.
  local mtimes = {}
  if sortByDate then
    for _, name in ipairs(files) do
      local info = noctalia.fileInfo(notePath(name))
      mtimes[name] = info ~= nil and info.mtime or 0
    end
  end
  table.sort(files, function(a, b)
    local aPinned = pins[a] == true
    local bPinned = pins[b] == true
    if aPinned ~= bPinned then
      return aPinned
    end
    if sortByDate and mtimes[a] ~= mtimes[b] then
      return mtimes[a] > mtimes[b]
    end
    return a < b
  end)
end

local function flush()
  if not dirty or current == nil then
    return
  end
  local ok, err = noctalia.writeFile(notePath(current), buffer)
  if not ok then
    noctalia.notifyError(tr("title"), err or tr("save_failed"))
    return
  end
  loadedContent = buffer
  dirty = false
end

local function openNote(file)
  flush()
  local contents = noctalia.readFile(notePath(file))
  buffer = contents or ""
  loadedContent = buffer
  current = file
  view = "editor"
  dirty = false
  idleTicks = 0
  pendingDelete = nil
  render()
end

local function deleteNote(file)
  local ok, err = noctalia.removeFile(notePath(file))
  if not ok then
    noctalia.notifyError(tr("title"), err or "")
  end
  if pins[file] ~= nil then
    pins[file] = nil
    savePins()
  end
  if current == file then
    current = nil
    buffer = ""
    dirty = false
    view = "list"
  end
  pendingDelete = nil
  refreshFiles()
  render()
end

local function uniqueNoteName()
  local base = noctalia.formatTime("%Y-%m-%d %H.%M.%S")
  local name = base .. suffix
  local counter = 2
  while noctalia.fileExists(notePath(name)) do
    name = base .. " (" .. counter .. ")" .. suffix
    counter += 1
  end
  return name
end

local function deleteControls(file)
  return {
    ui.label({ text = tr("confirm_delete"), color = "error" }),
    ui.button({
      glyph = "check",
      variant = "primary",
      onClick = function()
        deleteNote(file)
      end,
    }),
    ui.button({
      glyph = "close",
      variant = "ghost",
      onClick = function()
        pendingDelete = nil
        render()
      end,
    }),
  }
end

local function togglePin(file)
  pins[file] = not pins[file] and true or nil
  savePins()
  refreshFiles()
  render()
end

local function listRow(file)
  local pinned = pins[file] == true
  -- Both row states keep the same leading text button so the row height (set
  -- by the text-button tier) never changes when the confirm controls swap in.
  local title = {
    text = displayName(file),
    variant = "ghost",
    contentAlign = "start",
    flexGrow = 1,
    onClick = function()
      openNote(file)
    end,
  }
  if pinned then
    title.glyph = "pinned"
  end
  local children = { ui.button(title) }
  if pendingDelete == file then
    for _, node in ipairs(deleteControls(file)) do
      table.insert(children, node)
    end
  else
    table.insert(children, ui.button({
      glyph = pinned and "pinned-off" or "pin",
      variant = "ghost",
      onClick = function()
        togglePin(file)
      end,
    }))
    table.insert(children, ui.button({
      glyph = "trash",
      variant = "ghost",
      onClick = function()
        pendingDelete = file
        render()
      end,
    }))
  end
  -- Pin state is part of the key: retained buttons keep a previously set
  -- glyph, so the row is recreated when it flips.
  return ui.row({ key = "note-" .. file .. (pinned and "-pinned" or ""), gap = 6, align = "center" }, children)
end

local function listView()
  local rows = {
    -- The scratchpad is always present (created on first write) and not deletable from here.
    ui.row({ key = "scratchpad", gap = 6, align = "center" }, {
      ui.button({
        glyph = "pinned",
        text = tr("scratchpad"),
        variant = "ghost",
        contentAlign = "start",
        flexGrow = 1,
        onClick = "onOpenScratchpad",
      }),
    }),
  }
  for _, file in ipairs(files) do
    table.insert(rows, listRow(file))
  end
  if #files == 0 then
    table.insert(rows, ui.label({ text = tr("empty"), color = "on_surface_variant" }))
  end
  return ui.scroll({ flexGrow = 1, gap = 4 }, rows)
end

local function editorStatusLine()
  local words = select(2, buffer:gsub("%S+", ""))
  local chars = utf8.len(buffer) or #buffer
  local status = dirty and tr("editing") or tr("saved")
  return status .. "  ·  " .. noctalia.tr("counts", { words = words, chars = chars })
end

local function editorHeader()
  local trailing
  if pendingDelete == current then
    trailing = deleteControls(current, "noteEditorDelete", 0)
  else
    trailing = {
      ui.button({ glyph = "trash", variant = "ghost", onClick = "onEditorDelete" }),
    }
  end
  local children = {
    ui.button({ glyph = "arrow-left", variant = "ghost", onClick = "onBack" }),
    ui.input({
      key = "rename-" .. current,
      value = displayName(current),
      onSubmit = "onRename",
      -- The scratchpad's identity is its name; renaming it would just respawn it.
      enabled = current ~= scratchName(),
      flexGrow = 1,
    }),
  }
  for _, node in ipairs(trailing) do
    table.insert(children, node)
  end
  return ui.row({ gap = 6, align = "center" }, children)
end

local function editorView()
  return ui.column({ flexGrow = 1, gap = 8, align = "stretch" }, {
    editorHeader(),
    ui.input({
      -- The rev reseeds the (uncontrolled) editor when the file changed under us.
      key = "editor-" .. current .. "-" .. editorRev,
      value = buffer,
      multiline = true,
      focus = true,
      flexGrow = 1,
      placeholder = tr("editor_placeholder"),
      onChange = "onEdited",
      onSubmit = "onFlushNow",
    }),
    ui.label({
      text = editorStatusLine(),
      fontSize = 11,
      color = "on_surface_variant",
    }),
  })
end

render = function()
  local isEditor = view == "editor" and current ~= nil
  local header = {
    ui.label({ text = tr("title"), fontSize = 16, fontWeight = "bold", color = "on_surface", flexGrow = 1 }),
  }
  if not isEditor then
    table.insert(header, ui.button({
      key = "header-sort",
      glyph = sortByDate and "history" or "sort-ascending-letters",
      variant = "ghost",
      onClick = "onToggleSort",
    }))
  end
  table.insert(header, ui.button({ key = "header-new", glyph = "plus", variant = "primary", onClick = "onNewNote" }))
  table.insert(header, ui.button({ key = "header-close", glyph = "close", variant = "ghost", onClick = "onClosePanel" }))
  panel.render(ui.column({ flexGrow = 1, gap = 12, align = "stretch" }, {
    ui.row({ align = "center", gap = 8 }, header),
    isEditor and editorView() or listView(),
  }))
end

function onOpen(_context)
  notesDir = noctalia.expandPath(noctalia.getConfig("notes_dir"))
  local extension = noctalia.string.trim(noctalia.getConfig("extension")):gsub("^%.", "")
  if extension == "" then
    noctalia.notifyError(tr("title"), tr("bad_extension"))
    extension = "md"
  end
  suffix = "." .. extension
  -- A note left open under a different extension setting no longer matches.
  if current ~= nil and not hasSuffix(current) then
    current = nil
    buffer = ""
    dirty = false
    view = "list"
  end
  local ok, err = noctalia.mkdirAll(notesDir)
  if not ok then
    noctalia.notifyError(tr("title"), err or "")
  end
  loadPins()
  refreshFiles()
  pendingDelete = nil
  panel.setWantsSecondTicks(true)
  -- The launcher entry hands over a target through the shared state: either
  -- the note list ("open_home") or a specific note ("open_note").
  if noctalia.state.get("open_home") == true then
    noctalia.state.set("open_home", false)
    flush()
    view = "list"
    current = nil
    buffer = ""
    dirty = false
    render()
    return
  end
  local target = noctalia.state.get("open_note")
  if type(target) == "string" and target ~= "" then
    noctalia.state.set("open_note", "")
    openNote(target)
    return
  end
  render()
end

function onOpenScratchpad()
  openNote(scratchName())
end

function onClose()
  flush()
end

function update()
  if dirty then
    idleTicks += 1
    if idleTicks >= AUTOSAVE_IDLE_TICKS then
      flush()
      render()
    end
  end
end

function onEdited(value)
  buffer = value
  idleTicks = 0
  dirty = true
  -- Re-render on every edit: the status line carries the live word/char count.
  render()
end

function onToggleSort()
  sortByDate = not sortByDate
  refreshFiles()
  render()
end

function onFlushNow(value)
  buffer = value
  dirty = true
  flush()
  render()
end

function onNewNote()
  flush()
  local name = uniqueNoteName()
  local ok, err = noctalia.writeFile(notePath(name), "")
  if not ok then
    noctalia.notifyError(tr("title"), err or tr("save_failed"))
    return
  end
  refreshFiles()
  openNote(name)
end

function onRename(value)
  if current == nil then
    return
  end
  local name = noctalia.string.trim(value):gsub("/", "")
  if name == "" or name == displayName(current) then
    render()
    return
  end
  local target = name .. suffix
  if noctalia.fileExists(notePath(target)) then
    noctalia.notifyError(tr("title"), tr("rename_exists"))
    render()
    return
  end
  flush()
  local ok, err = noctalia.renameFile(notePath(current), notePath(target))
  if not ok then
    noctalia.notifyError(tr("title"), err or "")
    render()
    return
  end
  if pins[current] ~= nil then
    pins[current] = nil
    pins[target] = true
    savePins()
  end
  current = target
  refreshFiles()
  render()
end

function onEditorDelete()
  pendingDelete = current
  render()
end

function onBack()
  flush()
  view = "list"
  current = nil
  buffer = ""
  pendingDelete = nil
  refreshFiles()
  render()
end

function onClosePanel()
  panel.close()
end

-- The launcher entry bumps "notes_bump" after writing note files (quick-capture
-- appends, new notes). Fold external changes into the open editor: an appended
-- tail is grafted onto whatever is being typed; other divergence only replaces
-- the buffer when there are no unsaved edits.
local function onExternalChange()
  if notesDir == "" then
    return -- never opened; nothing resolved yet
  end
  refreshFiles()
  if current ~= nil then
    local contents = noctalia.readFile(notePath(current)) or ""
    if contents ~= loadedContent then
      if contents:sub(1, #loadedContent) == loadedContent then
        buffer = buffer .. contents:sub(#loadedContent + 1)
      elseif not dirty then
        buffer = contents
      end
      loadedContent = contents
      dirty = buffer ~= loadedContent
      idleTicks = 0
      editorRev += 1
    end
  end
  render()
end

noctalia.state.watch("notes_bump", function(_value)
  onExternalChange()
end)
