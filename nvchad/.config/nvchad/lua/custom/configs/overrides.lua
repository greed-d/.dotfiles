local M = {}

M.treesitter = {
	ensure_installed = {
		"vim",
		"lua",
		"html",
		"css",
		"javascript",
		"typescript",
		"tsx",
		"c",
		"markdown",
		"markdown_inline",
		"bash",
		"fish",
	},
	indent = {
		enable = true,
		-- disable = {
		--   "python"
		-- },
	},
}

M.mason = {
	ensure_installed = {
		-- lua stuff
		"lua-language-server",
		"stylua",

		-- web dev stuff
		"css-lsp",
		"html-lsp",
		"typescript-language-server",
		"deno",
		"prettier",
		"eslint-lsp",

		-- shell
		"shfmt",
		"shellcheck",
		"codespell",
		"bash-language-server",

		-- python
		"flake8",
		"python-lsp-server",
		"autopep8",
		"black",

		-- pretty
		"prettier",
		"prettierd",

		-- c/cpp stuff
		"clangd",
		"clang-format",

		--markdown
		"marksman",
	},
}
-- git support in nvimtree
M.nvimtree = {
	git = {
		enable = true,
	},

	renderer = {
		highlight_git = true,
		icons = {
			show = {
				git = true,
			},
		},
	},
}

M.telescope = {
	opts = {
		default = {
			file_ignore_pattern = { ".git", "wallpapers", "wally", "Wallpapers" },
		},
		extension_list = { "notify", "flutter" },
	},
}

M.gitsigns = {
	signs = {
		add = { hl = "DiffAdd", text = "", numhl = "GitSignsAddNr" },
		change = { hl = "DiffChange", text = "│", numhl = "GitSignsChangeNr" },
		delete = { hl = "DiffDelete", text = "", numhl = "GitSignsDeleteNr" },
		topdelete = { hl = "DiffDelete", text = "‾", numhl = "GitSignsDeleteNr" },
		changedelete = { hl = "DiffChangeDelete", text = "~", numhl = "GitSignsChangeNr" },
		untracked = { hl = "GitSignsAdd", text = "┆", numhl = "GitSignsAddNr", linehl = "GitSignsAddLn" },
	},
}

return M
