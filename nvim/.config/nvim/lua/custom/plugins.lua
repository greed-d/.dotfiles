local overrides = require("custom.configs.overrides")

---@type NvPluginSpec[]
local plugins = {
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			-- format & linting
			{
				"jose-elias-alvarez/null-ls.nvim",
				config = function()
					require("custom.configs.null-ls")
				end,
			},
		},
		config = function()
			require("plugins.configs.lspconfig")
			require("custom.configs.lspconfig")
		end, -- Override to setup mason-lspconfig
	},

	-- override plugin configs
	{
		"williamboman/mason.nvim",
		opts = overrides.mason,
	},
	{
		"nvim-treesitter/nvim-treesitter",
		opts = overrides.treesitter,
	},

	{
		"nvim-tree/nvim-tree.lua",
		opts = overrides.nvimtree,
	},

	{
		"nvim-telescope/telescope.nvim",
		opts = overrides.telescope,
	},

	{
		"lewis6991/gitsigns.nvim",
		opts = overrides.gitsigns,
	},

	{
		"NvChad/nvterm",
		opts = overrides.nvterm,
	},
	{
		"hrsh7th/nvim-cmp",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp-signature-help",
		},
		opts = {
			sources = {
				{ name = "nvim_lsp" },
				{ name = "luasnip" },
				{ name = "buffer" },
				{ name = "nvim_lua" },
				{ name = "path" },
				{ name = "nvim_lsp_signature_help" },
			},
		},
	},

	-- Install a plugin

	{
		"max397574/better-escape.nvim",
		event = "InsertEnter",
		config = function()
			require("better_escape").setup()
		end,
	},

	{
		"andweeb/presence.nvim",
		event = "VeryLazy",
		config = function()
			require("presence").setup({
				-- log_level = "debug",
				neovim_image_text = "NEOVIM go BRRRRR",
				main_image = "file",
				-- enable_line_number = true,
			})
		end,
	},

	{
		"folke/trouble.nvim",
		event = "BufReadPre",
		config = function()
			require("trouble").setup()
		end,
	},

	{
		"ThePrimeagen/harpoon",
		event = "BufReadPre",
		config = function()
			require("harpoon").setup()
		end,
	},

	{
		"arnamak/stay-centered.nvim",
		event = "BufReadPre",
		config = function()
			require("stay-centered")
		end,
		-- enabled = false,
	},

	{
		"toppair/peek.nvim",
		build = "deno task --quiet build:fast",
		config = function()
			require("peek").setup()
		end,
	},

	{
		"romainl/vim-cool",
		event = "BufReadPre",
	},

	{
		"airblade/vim-rooter",
		event = "BufReadPre",
	},

	{
		"echasnovski/mini.nvim",
		event = "BufReadPre",
		config = function()
			require("custom.configs.extras.minimap")
		end,
	},

	{
		"akinsho/flutter-tools.nvim",
		lazy = true,
		dependencies = {
			"nvim-lua/plenary.nvim",
			"stevearc/dressing.nvim", -- optional for vim.ui.select
			config = function()
				require("flutter-tools").setup({})
			end,
		},
	},

	{
		"alexghergh/nvim-tmux-navigation",
		event = "VeryLazy",
		config = function()
			require("nvim-tmux-navigation").setup({ disable_when_zoomed = true }) -- defaults to false
		end,
	},

	{
		"utilyre/barbecue.nvim",
		event = "BufReadPre",
		name = "barbecue",
		version = "*",
		dependencies = {
			"SmiteshP/nvim-navic",
			"nvim-tree/nvim-web-devicons", -- optional dependency
		},
		opts = {
			-- configurations go here
		},
	},

	{
		"mbbill/undotree",
		event = "BufReadPre",
	},

	{
		"mfussenegger/nvim-dap-python",
		event = "BufReadPre",
	},

	-- Lua

	{
		"folke/zen-mode.nvim",
		cmd = "ZenMode",
		config = function()
			require("zen-mode").setup({})
		end,
	},

	{
		"tpope/vim-surround",
		event = "VeryLazy",
	},

	{
		"rcarriga/nvim-notify",
		lazy = false,
		config = function()
			require("notify").setup({
				stages = "slide",
				background_colour = "FloatShadow",
				render = "simple",
				top_down = false,
				timeout = 2000,
			})
			vim.notify = require("notify")
		end,
		enabled = false,
	},

	{
		"elkowar/yuck.vim",
		ft = "yuck",
	},

	{
		"kdheepak/lazygit.nvim",
		cmd = "LazyGit",
	},

	{
		"folke/noice.nvim",
		event = "VeryLazy",
		config = function()
			require("custom.configs.extras.noice")
		end,
		dependencies = {
			"MunifTanjim/nui.nvim",
			"rcarriga/nvim-notify",
		},
		enabled = false,
	},

	{
		"ggandor/flit.nvim",
		event = "BufReadPre",
		dependencies = { "ggandor/leap.nvim" },
		config = function()
			require("flit").setup({
				keys = { f = "f", F = "F", t = "t", T = "T" },
				-- A string like "nv", "nvo", "o", etc.
				labeled_modes = "v",
				multiline = true,
				-- Like `leap`s similar argument (call-specific overrides).
				-- E.g.: opts = { equivalence_classes = {} }
				opts = {},
			})
		end,
	},

	{
		"folke/todo-comments.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		event = "BufReadPre",
		config = function()
			require("custom.configs.extras.todo")
		end,
	},

	{
		"simrat39/symbols-outline.nvim",
		event = "VeryLazy",
		config = function()
			require("symbols-outline").setup({
				auto_preview = false,
				position = "left",
				width = 16,
			})
		end,
	},
	{
		"kevinhwang91/nvim-ufo",
		dependencies = {
			"kevinhwang91/promise-async",
			{
				"luukvbaal/statuscol.nvim",
				config = function()
					local builtin = require("statuscol.builtin")
					require("statuscol").setup({
						relculright = true,
						segments = {
							{ text = { builtin.foldfunc }, click = "v:lua.ScFa" },
							{ text = { "%s" }, click = "v:lua.ScSa" },
							{ text = { builtin.lnumfunc, " " }, click = "v:lua.ScLa" },
						},
					})
				end,
			},
		},
		lazy = false,
		event = "BufReadPre",
		init = function()
			vim.opt.foldcolumn = "1"
			vim.opt.foldlevel = 99
			vim.opt.foldlevelstart = 99
			vim.opt.foldenable = true
			vim.opt.fillchars = [[eob: ,fold: ,foldopen:,foldsep: ,foldclose:]]
		end,
		keys = {
			{
				"zR",
				function()
					require("ufo").openAllFolds()
				end,
			},

			{
				"zM",
				function()
					require("ufo").closeAllFolds()
				end,
			},
		},
		opts = {
			provider_selector = function()
				return { "treesitter", "indent" }
			end,
		},
	},
	{
		"nvim-telescope/telescope-ui-select.nvim",
		event = "VeryLazy",
		config = function()
			require("telescope").setup({})
		end,
	},
	{
		"stevearc/dressing.nvim",
		event = "VeryLazy",
		config = function()
			require("dressing").setup({})
		end,
	},
	{
		"barrett-ruth/live-server.nvim",
		cmd = "LiveServerStart",
		build = "yarn global add live-server",
		config = function()
			require("live-server").setup()
		end,
	},
	-- Lua
	{
		"folke/persistence.nvim",
		event = "BufReadPre", -- this will only start session saving when an actual file was opened
		opts = {
			-- add any custom options here
		},
	},
	{
		"HiPhish/rainbow-delimiters.nvim",
		event = "BufReadPre",
	},
}

return plugins
