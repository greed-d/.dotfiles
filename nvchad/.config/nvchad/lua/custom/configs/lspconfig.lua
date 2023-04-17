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
	"json_lsp",
	"pyright",
	-- "python-lsp-server",
	"eslint",
}

for _, lsp in ipairs(servers) do
	lspconfig[lsp].setup({
		on_attach = on_attach,
		capabilities = capabilities,
	})
end

--
-- lspconfig.pyright.setup { blabla}
--      bash-language-server
--      css-lsp
--      emmet-ls
--      eslint-lsp
--      html-lsp
--      json-lsp
--      lua-language-server
--      pyright
--      python-lsp-server
--      typescript-language-server
--
