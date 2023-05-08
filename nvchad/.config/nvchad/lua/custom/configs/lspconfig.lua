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
}

for _, lsp in ipairs(servers) do
  lspconfig[lsp].setup({
    on_attach = on_attach,
    capabilities = capabilities,
  })
end

require("lspconfig").jsonls.setup({
  capabilities = require("cmp_nvim_lsp").default_capabilities(),
  filetypes = { "json", "jsonc" },
  flags = {
    debounce_text_changes = 150,
  },
})
