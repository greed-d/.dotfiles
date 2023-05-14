---@type ChadrcConfig
local M = {}
local highlights = require "custom.highlights"

M.ui = {
  theme = "ayu_dark",
  theme_toggle = { "ayu_dark", "onedark" },

  hl_override = highlights.override,
  hl_add = highlights.add,

  -- cmp themeing
  cmp = {
    icons = true,
    lspkind_text = true,
    style = "default",           -- default/flat_light/flat_dark/atom/atom_colored
    border_color = "grey_fg2",   -- only applicable for "default" style, use color names from base30 variables
    selected_item_bg = "simple", -- colored / simple
  },

  tabufline = {
    show_numbers = false,
    enabled = true,
    lazyload = true,
  },

  statusline = {
    theme = "vscode_colored",
    separator_style = "default",
  },

  telescope = { style = "borderless" }, -- borderless / bordered

  nvdash = {
    load_on_startup = true,
  },
}

M.plugins = "custom.plugins"

-- check core.mappings for table structure
M.mappings = require "custom.mappings"

return M
