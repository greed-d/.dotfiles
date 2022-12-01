vim.g.catppuccin_flavour = "mocha"
require("catppuccin").setup()
vim.api.nvim_command("colorscheme catppuccin")

vim.cmd [[
 	highlight Comment guifg=#858799
 ]]
