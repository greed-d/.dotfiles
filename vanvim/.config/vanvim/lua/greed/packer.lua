local install_path = vim.fn.stdpath("data") .. "/site/pack/packer/start/packer.nvim"

if vim.fn.empty(vim.fn.glob(install_path)) > 0 then
	vim.fn.execute("!git clone https://github.com/wbthomason/packer.nvim " .. install_path)
end

local packer_group = vim.api.nvim_create_augroup("Packer", { clear = true })
vim.api.nvim_create_autocmd(
	"BufWritePost",
	{ command = "source <afile> | PackerCompile", group = packer_group, pattern = "init.lua" }
)

require("packer").startup(function(use)
	use("wbthomason/packer.nvim")

	--> Colour Schemes/lualine
	use({ "catppuccin/nvim", as = "catppuccin" })
	use("edr3x/lualine.nvim")
	use("folke/tokyonight.nvim")

	--> LSP/CMP
	use("hrsh7th/nvim-cmp")
	use("jose-elias-alvarez/null-ls.nvim")
	use("lewis6991/gitsigns.nvim")
	use("neovim/nvim-lspconfig")
	use("windwp/nvim-autopairs")
	use("williamboman/mason.nvim")
	use("williamboman/mason-lspconfig.nvim")
	use("github/copilot.vim")
	use("lukas-reineke/indent-blankline.nvim")
	use("nvim-treesitter/nvim-treesitter")
	use("nvim-lua/plenary.nvim")
	use("hrsh7th/cmp-nvim-lsp")
	use("onsails/lspkind-nvim")
	use("saadparwaiz1/cmp_luasnip")
	use("tpope/vim-commentary")

	--> LANGUAGE SPECIFIC PLUGINS
	use({ "akinsho/flutter-tools.nvim", requires = "nvim-lua/plenary.nvim" })
	use({ "toppair/peek.nvim", run = "deno task --quiet build:fast" })

	--> NAVIGATION PLUGINS
	use("nvim-telescope/telescope-file-browser.nvim")
	use("christoomey/vim-tmux-navigator")
	use("nvim-telescope/telescope.nvim")
	use("ThePrimeagen/harpoon")
	use("airblade/vim-rooter")
	use("arnamak/stay-centered.nvim")
	use({
		"DaikyXendo/nvim-tree.lua",
		requires = {
			"DaikyXendo/nvim-material-icon",
		},
	})

	--> MISC PLUGINS
	use("ThePrimeagen/vim-be-good")
	use("andweeb/presence.nvim")
	use("NvChad/nvim-colorizer.lua")
	use("DaikyXendo/nvim-material-icon")
	use({ "folke/lsp-colors.nvim" })
	use("glepnir/dashboard-nvim")
	use("kyazdani42/nvim-web-devicons")
	use("L3MON4D3/LuaSnip")
	use("max397574/better-escape.nvim")
	use("romainl/vim-cool")
	use("ryanoasis/vim-devicons")

	use({
		"folke/trouble.nvim",
		requires = "kyazdani42/nvim-web-devicons",
		config = function()
			require("trouble").setup({})
		end,
	})

	use({
		"kdheepak/tabline.nvim",
		requires = { "hoob3rt/lualine.nvim", "kyazdani42/nvim-web-devicons" },
	})

	-- 	use({
	-- 		"declancm/cinnamon.nvim",
	-- 		config = function()
	-- 			require("cinnamon").setup()
	-- 		end,
	-- 	})

	-- use({
	-- 	"nvim-tree/nvim-tree.lua",
	-- 	requires = {
	-- 		"nvim-tree/nvim-material-icon" -- optional, for file icons
	-- 	},
	-- })
	-- use({ "ellisonleao/gruvbox.nvim" })
	-- use("Mofiqul/dracula.nvim")
	-- use("akinsho/toggleterm.nvim")
	-- use "simrat39/rust-tools.nvim"
	-- use("kdheepak/lazygit.nvim")
	-- use("stevearc/stickybuf.nvim")
	-- use("https://git.sr.ht/~whynothugo/lsp_lines.nvim")
end)
