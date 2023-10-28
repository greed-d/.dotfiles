---@type ChadrcConfig
local M = {}
local highlights = require("custom.highlights")

M.ui = {
	theme = "tokyodark",
	theme_toggle = { "tokyodark", "onedark" },

	hl_override = highlights.override,
	hl_add = highlights.add,

	--> lsp stuff
	lsp = {
		signature = {
			disabled = true,
		},
	},

	--> cmp themeing
	cmp = {
		icons = true,
		lspkind_text = true,
		style = "default", -- default/flat_light/flat_dark/atom/atom_colored
		border_color = "grey_fg2", -- only applicable for "default" style, use color names from base30 variables
		selected_item_bg = "simple", -- colored / simple
	},

	--> tabline
	tabufline = {
		show_numbers = false,
		enabled = true,
		lazyload = true,
	},

	--> statusline
	statusline = {
		theme = "vscode_colored",
		separator_style = "arrow",
	},

	telescope = { style = "borderless" }, -- borderless / bordered

	nvdash = {
		load_on_startup = true,
		-- header = {
		-- 	"",
		--
		-- 	" ██████╗ ██████╗ ██████╗ ██████╗ ███████╗██████╗ ",
		-- 	"██╔════╝ ██╔══██╗██╔══██╗╚════██╗██╔════╝██╔══██╗",
		-- 	"██║  ██╗ ██████╔╝██████╔╝ █████╔╝█████╗  ██║  ██║",
		-- 	"██║  ╚██╗██╔══██╗██╔══██╗ ╚═══██╗██╔══╝  ██║  ██║",
		-- 	"╚██████╔╝██║  ██║██║  ██║██████╔╝███████╗██████╔╝",
		-- 	" ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚═════╝ 	",
		-- 	"",
		-- 	"",
		-- },
	},
}

M.plugins = "custom.plugins"

-- check core.mappings for table structure
M.mappings = require("custom.mappings")

return M
