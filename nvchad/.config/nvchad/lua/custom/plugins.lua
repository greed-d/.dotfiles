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
		event = "BufReadPre",
		config = function()
			require("presence").setup()
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
	},
	{
		"toppair/peek.nvim",
		event = "BufReadPre",
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

	-- To make a plugin not be loaded
	-- {
	--   "NvChad/nvim-colorizer.lua",
	--   enabled = false
	-- },
}

return plugins
