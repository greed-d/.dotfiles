local M = {}

M.treesitter = {
	ensure_installed = {
		-- vim/neovim
		"vim",
		"lua",

		--web dev
		"html",
		"css",
		"javascript",
		"typescript",
		"tsx",

		-- c/cpp
		"c",
		"cpp",

		--markdown
		"markdown",
		"markdown_inline",

		--fish/bash
		"bash",
		"fish",
	},
	indent = {
		enable = true,
		-- disable = { "python" },
	},
}

M.mason = {
	ensure_installed = {
		-- lua stuff
		"lua-language-server",
		"stylua",
		"selene",

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
		"black",

		-- pretty
		"prettier",
		"prettierd",

		-- c/cpp stuff
		"clangd",
		"clang-format",
		"cspell",

		--markdown
		"marksman",
	},
	log_level = vim.log.levels.INFO,
	automatic_install = true,
}
-- git support in nvimtree
M.nvimtree = {
	git = {
		enable = true,
	},

	view = {
		float = {
			enable = true,
			quit_on_focus_loss = true,
			open_win_config = {
				relative = "editor",
				border = "rounded",
				width = 50,
				height = 40,
				row = 6,
				col = 95,
			},
		},
	},
	renderer = {
		highlight_git = true,
		icons = {
			show = {
				git = true,
			},
			git = {
				renamed = "»",
				untracked = "?",
			},
		},
	},
}

M.telescope = {
	opts = {
		default = {
			file_ignore_pattern = { ".git", "venv" },
			initial_mode = "normal",
		},
		extension_list = { "notify", "flutter", "treesitter", "ui-select" },
		extensions = {
			notify = {},
			["ui-select"] = {
				require("telescope.themes").get_dropdown({}),
			},
		},
	},
}

M.nvterm = {
	terminals = {
		shell = vim.o.shell,
		list = {},
		type_opts = {
			float = {
				relative = "editor",
				row = 0.16,
				col = 0.09,
				width = 0.75,
				height = 0.7,
				border = "single",
			},
			horizontal = { location = "rightbelow", split_ratio = 0.3 },
			vertical = { location = "rightbelow", split_ratio = 0.5 },
		},
	},
}

M.gitsigns = {
	signs = {
		add = { hl = "DiffAdd", text = "+", numhl = "GitSignsAddNr" },
		change = { hl = "DiffChange", text = "│", numhl = "GitSignsChangeNr" },
		delete = { hl = "DiffDelete", text = "-", numhl = "GitSignsDeleteNr" },
		topdelete = { hl = "DiffDelete", text = "‾", numhl = "GitSignsDeleteNr" },
		changedelete = { hl = "DiffChangeDelete", text = "~", numhl = "GitSignsChangeNr" },
		untracked = { hl = "GitSignsAdd", text = "┆", numhl = "GitSignsAddNr", linehl = "GitSignsAddLn" },
	},
}

return M
