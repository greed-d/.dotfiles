local opt = vim.opt

--------------------------------------> settings <------------------------------------------

opt.rnu = true
vim.o.guifont = "CaskaydiaCove NF:h14"

--------------------------------------> usercommands <-------------------------------------------------

require("custom.autocmd")
require("custom.usrcmd")
