local present, lualine = pcall(require, "lualine")
if not present then
	return
end

local cp = require("catppuccin.palettes").get_palette()
local custom_catppuccin = require("lualine.themes.catppuccin")
custom_catppuccin.normal.b.bg = cp.surface0
custom_catppuccin.normal.c.bg = cp.base
custom_catppuccin.insert.b.bg = cp.surface0
custom_catppuccin.command.b.bg = cp.surface0
custom_catppuccin.visual.b.bg = cp.surface0
custom_catppuccin.replace.b.bg = cp.surface0
custom_catppuccin.inactive.a.bg = cp.base
custom_catppuccin.inactive.b.bg = cp.base
custom_catppuccin.inactive.b.fg = cp.surface0
custom_catppuccin.inactive.c.bg = cp.base

-- local buffer = {
-- 	"buffers",
-- 	show_filename_only = true,
-- 	hide_filename_extension = false,
-- 	show_modified_status = true,
-- 	mode = 0,
-- 	separator = { left = "", right = "" },
-- 	buffers_color = {
-- 		active = { fg = "#d3d3d3" },
-- 		inactive = { fg = "#414141" },
-- 	},
-- }

local lspStatus = {
	function()
		local msg = "No Active Lsp"
		local buf_ft = vim.api.nvim_buf_get_option(0, "filetype")
		local clients = vim.lsp.get_active_clients()
		if next(clients) == nil then
			return msg
		end
		for _, client in ipairs(clients) do
			local filetypes = client.config.filetypes
			if filetypes and vim.fn.index(filetypes, buf_ft) ~= -1 then
				return client.name
			end
		end
		return msg
	end,
	-- icon = "",
	color = { fg = "#d3d3d3" },
}

local layout = {
	lualine_a = {
		{
			function()
				return ""
			end,
			separator = { left = "", right = "" },
		},
	},
	lualine_b = {
		{
			"filetype",
			icon_only = true,
			colored = true,
			color = { bg = "#121319", fg = "#ffffff" },
		},
		{
			"filename",
			color = { bg = "#121319", fg = "#ffffff" },
			separator = { left = "", right = "" },
		},
		{
			"branch",
			icon = "",
			color = { bg = "#212430", fg = "#c296eb" },
			separator = { left = "", right = "" },
		},
		{
			"diff",
			colored = true,
			symbols = {
				added = "",
				modified = "",
				removed = "",
			},
			color = { bg = "#212430" },
			separator = { left = "", right = "" },
		},
	},
	lualine_c = {
		{
			function()
				return ""
			end,
			color = { bg = "#8FCDA9", fg = "#121319" },
			separator = { left = "", right = "" },
		},
		{
			"diagnostics",
			sources = { "nvim_lsp" },
			sections = {
				"info",
				"error",
				"warn",
				"hint",
			},
			diagnostic_color = {
				error = { fg = "#820e2d", bg = "#0f111a" },
				warn = { fg = "DiagnosticWarn", bg = "#0f111a" },
				info = { fg = "DiaganosticInfo", bg = "#0f111a" },
				hint = { fg = "#92CDE7", bg = "#0f111a" },
			},
			colored = true,
			update_in_insert = true,
			always_visible = false,
			symbols = {
				error = " ",
				warn = " ",
				hint = " ",
				info = " ",
			},
			separator = { left = "", right = "" },
		},

		{
			"buffers",
			separator = { left = "", right = "" },
			right_padding = 2,
			symbols = { alternate_file = "" },
		},
	},
	lualine_x = { lspStatus },
	lualine_y = {},
	lualine_z = {
		{
			"fileSize",
			color = "StatusLine",
		},
		{
			function()
				return ""
			end,
			separator = { left = "", right = "" },
		},
		{
			"progress",
			color = "StatusLine",
		},
		{
			function()
				return ""
			end,
			separator = { left = "", right = "" },
		},
		{
			"location",
			color = "StatusLine",
		},
		{
			function()
				return ""
			end,
			separator = { left = "", right = "" },
		},
	},
}

local no_layout = {
	lualine_a = {},
	lualine_b = {},
	lualine_c = {},
	lualine_d = {},
	lualine_x = {},
	lualine_y = {},
	lualine_z = {},
}

lualine.setup({
	sections = layout,
	inactive_sections = no_layout,
	options = {
		icons_enabled = true,
		globalstatus = false,
		disabled_filetypes = { "alpha", "dashboard", "NvimTree", "Outline" },
		always_divide_middle = true,
		theme = "catppuccin",
	},
})
