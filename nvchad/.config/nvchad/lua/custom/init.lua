local autocmd = vim.api.nvim_create_autocmd
local opt = vim.opt

-- local new_cmd = vim.api.nvim_create_user_command
-- local g = vim.g

-------------------------------------- settings ------------------------------------------

opt.rnu = true

-------------------------------------- highlight on yanked ------------------------------------------

autocmd("TextYankPost", {
  pattern = "*",
  callback = function()
    vim.highlight.on_yank({
      higroup = "IncSearch",
      timeout = 100,
    })
  end,
})

-------------------------------------- format on save ------------------------------------------

vim.api.nvim_create_autocmd("BufWritePre", {
  command = "lua vim.lsp.buf.format()",
  pattern = "*.cpp,*.css,*.go,*.h,*.html,*.js,*.json,*.jsx,*.lua,*.md,*.py,*.rs,*.ts,*.tsx,*.yaml,*.c,*.dart",
})

--vim.api.nvim_create_user_command('PeekOpen', require('peek').open, {})
--vim.api.nvim_create_user_command('PeekClose', require('peek').close, {})

-------------------------------------- usercommands -------------------------------------------------

vim.api.nvim_create_user_command("PeekOpen", function()
  require("peek").open()
end, {})

vim.api.nvim_create_user_command("PeekClose", function()
  require("peek").close()
end, {})

vim.api.nvim_create_user_command("Nvtfloat", function()
  require("nvterm.terminal").toggle("float")
end, {})
