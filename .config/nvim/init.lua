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

	use("andweeb/presence.nvim")
	use({ "catppuccin/nvim", as = "catppuccin" })
	use("glepnir/dashboard-nvim")
	use({ "ellisonleao/gruvbox.nvim" })
	use("kdheepak/lazygit.nvim")
	use("hrsh7th/cmp-nvim-lsp")
	use("hrsh7th/nvim-cmp")
	use("jose-elias-alvarez/null-ls.nvim")
	use("kyazdani42/nvim-web-devicons")
	use("L3MON4D3/LuaSnip")
	use("lewis6991/gitsigns.nvim")
	use("neovim/nvim-lspconfig")
	use("nvim-lua/plenary.nvim")
	use("nvim-lualine/lualine.nvim")
	use("nvim-telescope/telescope.nvim")
	use("nvim-telescope/telescope-file-browser.nvim")
	use("nvim-treesitter/nvim-treesitter")
	use("onsails/lspkind-nvim")
	use("ryanoasis/vim-devicons")
	use("saadparwaiz1/cmp_luasnip")
	-- use "simrat39/rust-tools.nvim"
	use("tpope/vim-commentary")
	use("windwp/nvim-autopairs")
	use("williamboman/mason.nvim")
	use("williamboman/mason-lspconfig.nvim")
	use("arnamak/stay-centered.nvim")
	use("akinsho/toggleterm.nvim")
	use("airblade/vim-rooter")
	use("stevearc/stickybuf.nvim")
	use("Mofiqul/dracula.nvim")
	use("https://git.sr.ht/~whynothugo/lsp_lines.nvim")
end)

vim.o.clipboard = "unnamedplus"
vim.o.ignorecase = true
vim.o.lazyredraw = true
vim.o.number = true
vim.o.relativenumber = true
vim.o.shiftwidth = 2
vim.o.splitbelow = true
vim.o.splitright = true
vim.o.tabstop = 2
vim.o.termguicolors = true
vim.o.updatetime = 100

vim.g.mapleader = " "

vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { silent = true })
vim.keymap.set("n", "<Leader>w", "<C-w>k")
vim.keymap.set("n", "<Leader>a", "<C-w>h")
vim.keymap.set("n", "<Leader>s", "<C-w>j")
vim.keymap.set("n", "<Leader>g", ":LazyGit<CR>")
vim.keymap.set("n", "<Leader>d", "<C-w>l")
vim.keymap.set("n", "<Leader>j", ":bprevious<CR>", { silent = true })
vim.keymap.set("n", "<Leader>k", ":bnext<CR>", { silent = true })
vim.keymap.set("n", "<Leader>q", ":bprevious<CR>:bdelete #<CR>", { silent = true })
vim.keymap.set("n", "<Leader>/", ":nohlsearch<CR>", { silent = true })
vim.keymap.set("n", "<Leader>y", ":%y<CR>")
vim.keymap.set("n", "k", 'v:count == 0 ? "gk" : "k"', { expr = true, silent = true })
vim.keymap.set("n", "j", 'v:count == 0 ? "gj" : "j"', { expr = true, silent = true })
vim.keymap.set("t", "<Leader><Esc>", "<C-\\><C-n>", { silent = true })
vim.keymap.set("n", "<Leader>v", ":edit ~/.config/nvim/init.lua<CR>", { silent = true })

local lang_maps = {
	cpp = { build = "g++ % -o %:r", exec = "./%:r" },
	c = { build = "g++ % -o %:r", exec = "./%:r" },
	typescript = { build = "deno compile %", exec = "deno run %" },
	javascript = { build = "deno compile %", exec = "deno run %" },
	python = { exec = "python %" },
	java = { build = "javac %", exec = "java %:r" },
	sh = { exec = "./%" },
	-- go = { build = "go build", exec = "go run %" },
	-- rust = { exec = "cargo run" },
	arduino = {
		build = "arduino-cli compile --fqbn arduino:avr:uno %:r",
		exec = "arduino-cli upload -p /dev/ttyACM0 --fqbn arduino:avr:uno %:r",
	},
}
for lang, data in pairs(lang_maps) do
	if data.build ~= nil then
		vim.api.nvim_create_autocmd(
			"FileType",
			{ command = "nnoremap <Leader>b :!" .. data.build .. "<CR>", pattern = lang }
		)
	end
	vim.api.nvim_create_autocmd(
		"FileType",
		{ command = "nnoremap <Leader>e :split<CR>:terminal " .. data.exec .. "<CR>", pattern = lang }
	)
end
vim.api.nvim_create_autocmd("BufWritePre", {
	command = "lua vim.lsp.buf.formatting_sync(nil, 1000)",
	pattern = "*.cpp,*.css,*.go,*.h,*.html,*.js,*.json,*.jsx,*.lua,*.md,*.py,*.rs,*.ts,*.tsx,*.yaml,*.c",
})
vim.api.nvim_create_autocmd("InsertEnter", { command = "set norelativenumber", pattern = "*" })
vim.api.nvim_create_autocmd("InsertLeave", { command = "set relativenumber", pattern = "*" })
vim.api.nvim_create_autocmd("TermOpen", { command = "startinsert", pattern = "*" })
vim.api.nvim_create_autocmd("BufWinEnter", { command = "set noexpandtab tabstop=2 shiftwidth=2", pattern = "*.rs" })

vim.cmd("sign define DiagnosticSignError text=● texthl=DiagnosticSignError")
vim.cmd("sign define DiagnosticSignWarn text=● texthl=DiagnosticSignWarn")
vim.cmd("sign define DiagnosticSignInfo text=● texthl=DiagnosticSignInfo")
vim.cmd("sign define DiagnosticSignHint text=● texthl=DiagnosticSignHint")

vim.diagnostic.config({ virtual_text = false })

require("presence"):setup({
	neovim_image_text = "Neovim",
	presence_log_level = "error",
	presence_editing_text = "Editing « %s »",
	presence_file_explorer_text = "Browsing files",
	presence_reading_text = "Reading  « %s »",
	presence_workspace_text = "Working on « %s »",
})
vim.g.catppuccin_flavour = "mocha"
vim.cmd("colorscheme catppuccin")

local db = require("dashboard")
db.custom_header = {
	"",
	"",
	"",
	"",
	" ███╗   ██╗ ███████╗ ██████╗  ██╗   ██╗ ██╗ ███╗   ███╗",
	" ████╗  ██║ ██╔════╝██╔═══██╗ ██║   ██║ ██║ ████╗ ████║",
	" ██╔██╗ ██║ █████╗  ██║   ██║ ██║   ██║ ██║ ██╔████╔██║",
	" ██║╚██╗██║ ██╔══╝  ██║   ██║ ╚██╗ ██╔╝ ██║ ██║╚██╔╝██║",
	" ██║ ╚████║ ███████╗╚██████╔╝  ╚████╔╝  ██║ ██║ ╚═╝ ██║",
	" ╚═╝  ╚═══╝ ╚══════╝ ╚═════╝    ╚═══╝   ╚═╝ ╚═╝     ╚═╝",
	"",
	"",
	"",
}
db.custom_center = {
	{
		icon = " ",
		desc = "New File            ",
		action = "DashboardNewFile",
		shortcut = "SPC o",
	},
	{
		icon = " ",
		desc = "Browse Files        ",
		action = "Telescope file_browser",
		shortcut = "SPC n",
	},
	{
		icon = " ",
		desc = "Find File           ",
		action = "Telescope find_files",
		shortcut = "SPC f",
	},
	{
		icon = " ",
		desc = "Configure Neovim    ",
		action = "edit ~/.config/nvim/lua/init.lua",
		shortcut = "SPC v",
	},
	{
		icon = " ",
		desc = "Exit Neovim              ",
		action = "quit",
	},
}
vim.keymap.set("n", "<Leader>o", ":DashboardNewFile<CR>", { silent = true })

local luasnip = require("luasnip")
local cmp = require("cmp")
cmp.setup({
	snippet = {
		expand = function(args)
			luasnip.lsp_expand(args.body)
		end,
	},
	mapping = cmp.mapping.preset.insert({
		["<C-Space>"] = cmp.mapping.complete(),
		["<CR>"] = cmp.mapping.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = true }),
		["<Tab>"] = cmp.mapping(function(fallback)
			if cmp.visible() then
				cmp.select_next_item()
			else
				fallback()
			end
		end, { "i", "s" }),
		["<S-Tab>"] = cmp.mapping(function(fallback)
			if cmp.visible() then
				cmp.select_prev_item()
			else
				fallback()
			end
		end, { "i", "s" }),
	}),
	sources = { { name = "nvim_lsp" }, { name = "luasnip" } },
})

local null_ls = require("null-ls")
null_ls.setup({
	sources = {
		null_ls.builtins.diagnostics.eslint_d,
		null_ls.builtins.formatting.eslint_d,
		null_ls.builtins.formatting.autopep8,
		--null_ls.builtins.formatting.gofmt,
		null_ls.builtins.formatting.prettierd,
		-- null_ls.builtins.formatting.rustfmt,
		null_ls.builtins.formatting.stylua,
	},
})

require("gitsigns").setup({
	signs = {
		add = { text = "+" },
		change = { text = "~" },
		delete = { text = "_" },
		topdelete = { text = "‾" },
		changedelete = { text = "~" },
	},
})

local lspconfig = require("lspconfig")

local cp = require("catppuccin.palettes.init").get_palette()
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
require("lualine").setup({
	options = {
		theme = custom_catppuccin,
		component_separators = "|",
		section_separators = { left = "", right = "" },
	},
	sections = {
		lualine_a = { { "mode", separator = { left = "" }, right_padding = 2 } },
		lualine_b = { "filename", "branch", { "diff", colored = false } },
		lualine_c = {},
		lualine_x = {},
		lualine_y = { "filetype", "progress" },
		lualine_z = { { "location", separator = { right = "" }, left_padding = 2 } },
	},
	inactive_sections = {
		lualine_a = { "filename" },
		lualine_b = {},
		lualine_c = {},
		lualine_x = {},
		lualine_y = {},
		lualine_z = {},
	},
	tabline = {
		lualine_a = {
			{
				"buffers",
				separator = { left = "", right = "" },
				right_padding = 2,
				symbols = { alternate_file = "" },
			},
		},
	},
})

local telescope = require("telescope")
telescope.setup({
	defaults = {
		mappings = { n = { ["o"] = require("telescope.actions").select_default } },
		initial_mode = "normal",
		hidden = true,
		file_ignore_patterns = { ".git/", "node_modules/", "target/" },
	},
	extensions = { file_browser = { hidden = true } },
})
telescope.load_extension("file_browser")
vim.keymap.set("n", "<Leader>n", telescope.extensions.file_browser.file_browser)
telescope.load_extension("file_browser")
vim.keymap.set("n", "<Leader>n", telescope.extensions.file_browser.file_browser)
vim.keymap.set("n", "<Leader>f", require("telescope.builtin").find_files)
vim.keymap.set("n", "<Leader>t", require("telescope.builtin").treesitter)

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

require("toggleterm").setup({
	size = 13,
	open_mapping = [[<Leader>l]],
	shade_filetypes = {},
	shade_terminals = true,
	shading_factor = "1",
	start_in_insert = true,
	persist_size = true,
	direction = "float",
	float_opts = {
		border = "curved",
		winblend = 3,
	},
})
-- require("rust-tools").setup {}

vim.keymap.set({ "n", "v" }, "<Leader>c", ":Commentary<CR>", { silent = true })

require("mason").setup({})

local servers = {
	"bashls",
	"clangd",
	"cssls",
	"gopls",
	"html",
	"pyright",
	-- "rust_analyzer",
	"sumneko_lua",
	"tailwindcss",
	"tsserver",
}

local has_formatter = { "gopls", "html", "rust_analyzer", "sumneko_lua", "tsserver", "bashls" }
require("mason-lspconfig").setup({
	ensure_installed = servers,
	automatic_installation = true,
})
local opts = {
	on_attach = function(client, bufnr)
		vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")
		local opts = { buffer = bufnr }
		vim.keymap.set("n", "<Leader>h", vim.lsp.buf.hover, opts)
		vim.keymap.set("n", "<Leader>i", vim.lsp.buf.definition, opts)
		vim.keymap.set("n", "<Leader>r", vim.lsp.buf.rename, opts)
		local should_format = true
		for _, value in pairs(has_formatter) do
			if client.name == value then
				should_format = false
			end
		end
		if not should_format then
			client.resolved_capabilities.document_formatting = false
		end
	end,
	capabilities = require("cmp_nvim_lsp").update_capabilities(vim.lsp.protocol.make_client_capabilities()),
}
for _, server in pairs(servers) do
	if server == "sumneko_lua" then
		opts.settings = { Lua = { diagnostics = { globals = { "vim" } } } }
	end
	lspconfig[server].setup(opts)
end

require("nvim-autopairs").setup({})

require("lsp_lines").setup({})
vim.keymap.set("n", "<Leader>x", require("lsp_lines").toggle)

require("stay-centered")
