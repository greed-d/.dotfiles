local servers = {
	"bashls",
	"clangd",
	"cssls",
	"emmet_ls",
	"gopls",
	"html",
	"marksman",
	-- "jedi_language_server",
	"pyright",
	-- "rust_analyzer",
	"sumneko_lua",
	"tailwindcss",
	"tsserver",
}

require("mason").setup({
	ui = {
		border = "none",
		icons = {
			package_installed = "✓",
			package_pending = "➜",
			package_uninstalled = "✗",
		},
	},
	log_level = vim.log.levels.INFO,
	max_concurrent_installers = 4,
})

require("mason-lspconfig").setup({
	ensure_installed = servers,
	automatic_installation = true,
})

for _, lsp in pairs(servers) do
	require("lspconfig")[lsp].setup({
		capabilities = require("cmp_nvim_lsp").default_capabilities(),
		flags = {
			debounce_text_changes = 150,
		},
		settings = {
			Lua = {
				diagnostics = {
					globals = { "vim" },
				},
			},
		},
	})
end
