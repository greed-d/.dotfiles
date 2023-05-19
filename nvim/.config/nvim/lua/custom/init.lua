local opt = vim.opt

--------------------------------------> settings <------------------------------------------

opt.rnu = true
vim.o.guifont = "JetBrainsMono Nerd Font:h11"

--------------------------------------> usercommands <-------------------------------------------------

require("custom.autocmd")
require("custom.usrcmd")
