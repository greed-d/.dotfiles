require("tokyodark").setup()

local gvim = vim.g

gvim.api.nvim_command("colorscheme tokyodark")
gvim.tokyodark_transparent_background = false
gvim.tokyodark_enable_italic_comment = true
gvim.tokyodark_enable_italic = true
gvim.tokyodark_color_gamma = "1.0"
