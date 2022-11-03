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
	-- use({ "ellisonleao/gruvbox.nvim" })
	-- use("Mofiqul/dracula.nvim")
	use("edr3x/lualine.nvim")

	--> LSP/CMP
	use("hrsh7th/nvim-cmp")
	use("jose-elias-alvarez/null-ls.nvim")
	use("lewis6991/gitsigns.nvim")
	use("neovim/nvim-lspconfig")
	use("windwp/nvim-autopairs")
	use("williamboman/mason.nvim")
	use("williamboman/mason-lspconfig.nvim")
	use("nvim-telescope/telescope.nvim")
	use("nvim-telescope/telescope-file-browser.nvim")
	use("nvim-treesitter/nvim-treesitter")
	use("nvim-lua/plenary.nvim")
	use("hrsh7th/cmp-nvim-lsp")
	use("onsails/lspkind-nvim")
	use("saadparwaiz1/cmp_luasnip")

	--> MISC PLUGINS
	-- use("andweeb/presence.nvim")
	use("glepnir/dashboard-nvim")
	use("romainl/vim-cool")
	use("max397574/better-escape.nvim")
	use("kyazdani42/nvim-web-devicons")
	use("L3MON4D3/LuaSnip")
	use("ryanoasis/vim-devicons")
	use("tpope/vim-commentary")
	use("arnamak/stay-centered.nvim")
	use("airblade/vim-rooter")
	use("stevearc/stickybuf.nvim")
	use({ "toppair/peek.nvim", run = "deno task --quiet build:fast" })
	use("https://git.sr.ht/~whynothugo/lsp_lines.nvim")
	use({
		"nvim-tree/nvim-tree.lua",
		requires = {
			"nvim-tree/nvim-web-devicons", -- optional, for file icons
		},
	})
	-- use("akinsho/toggleterm.nvim")
	-- use "simrat39/rust-tools.nvim"
	-- use("kdheepak/lazygit.nvim")
end)
