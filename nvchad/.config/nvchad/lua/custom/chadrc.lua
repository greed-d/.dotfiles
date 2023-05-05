---@type ChadrcConfig
local M = {}

-- Path to overriding theme and highlights files
local highlights = require("custom.highlights")

M.ui = {
  theme = "tokyodark",
  theme_toggle = { "tokyodark", "catppuccin" },

  hl_override = highlights.override,
  hl_add = highlights.add,

  -- cmp themeing
  cmp = {
    icons = true,
    lspkind_text = true,
    style = "default",          -- default/flat_light/flat_dark/atom/atom_colored
    border_color = "grey_fg",   -- only applicable for "default" style, use color names from base30 variables
    selected_item_bg = "colored", -- colored / simple
  },

  tabufline = {
    show_numbers = true,
    enabled = true,
    lazyload = true,
  },

  statusline = {
    theme = "vscode_colored",
    separator_style = "default",
  },

  telescope = { style = "bordered" }, -- borderless / bordered

  nvdash = {
    load_on_startup = true,
  },
}

M.plugins = "custom.plugins"

-- check core.mappings for table structure
M.mappings = require("custom.mappings")

return M
