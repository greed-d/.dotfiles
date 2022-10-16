require("nvim-treesitter.configs").setup({
	ensure_installed = {
		"bash",
		"cpp",
		"c",
		"css",
		-- "go",
		"html",
		"lua",
		"make",
		"python",
		-- "rust",
		"tsx",
		"typescript",
		-- "yaml",
	},
	highlight = { enable = true },
})
