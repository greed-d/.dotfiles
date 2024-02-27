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
		border_color = "teal", -- only applicable for "default" style, use color names from base30 variables
		selected_item_bg = "colored", -- colored / simple
	},

	--> tabline
	tabufline = {
		show_numbers = true,
		enabled = true,
		lazyload = true,
	},

	--> statusline
	statusline = {
		theme = "vscode_colored",
		separator_style = "round",
	},

	telescope = { style = "bordered" }, -- borderless / bordered

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
