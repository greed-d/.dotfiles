local lspconfig = require("lspconfig")
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
			client.server_capabilities.document_formatting = false
		end
	end,
	capabilities = require("cmp_nvim_lsp").default_capabilities(vim.lsp.protocol.make_client_capabilities()),
}
for _, server in pairs(servers) do
	if server == "sumneko_lua" then
		opts.settings = { Lua = { diagnostics = { globals = { "vim" } } } }
	end
	lspconfig[server].setup(opts)
end
