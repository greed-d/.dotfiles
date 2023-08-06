local on_attach = require("plugins.configs.lspconfig").on_attach
local capabilities = require("plugins.configs.lspconfig").capabilities

local lspconfig = require("lspconfig")

-- if you just want default config for the servers then put them in a table
local servers = {
	"html",
	"cssls",
	"tsserver",
	"clangd",
	-- "lua_ls",
	"bashls",
	"emmet_ls",
	"pyright",
	"marksman",
	-- "python-lsp-server",
	"eslint",
	"lemminx",
}

for _, lsp in ipairs(servers) do
	lspconfig[lsp].setup({
		on_attach = on_attach,
		capabilities = capabilities,
	})

	lspconfig.emmet_ls.setup({
		capabilities = capabilities,
		filetypes = { "html", "htmldjango" },
		flags = {
			debounce_text_changes = 150,
		},
	})
end
