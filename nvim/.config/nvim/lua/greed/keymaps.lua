vim.g.mapleader = " "

vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { silent = true })

--> Movement/Deleting/Navigating
vim.keymap.set("n", "<Leader>w", "<C-w>k")
vim.keymap.set("n", "<Leader>a", "<C-w>h")
vim.keymap.set("n", "<Leader>s", "<C-w>j")
vim.keymap.set("n", "<Leader>d", "<C-w>l")
vim.keymap.set("n", "<Leader>j", ":bprevious<CR>", { silent = true })
vim.keymap.set("n", "<Leader>k", ":bnext<CR>", { silent = true })
vim.keymap.set("n", "<Leader>q", ":bprevious<CR>:bdelete #<CR>", { silent = true })
vim.keymap.set("n", "<A-j>", "V:m '>+1<cr>gv=gv<esc>")
vim.keymap.set("n", "<A-k>", "V:m '<-2<cr>gv=gv<esc>")
vim.keymap.set({ "v", "x" }, "<A-j>", ":m '>+1<cr>gv=gv")
vim.keymap.set({ "v", "x" }, "<A-k>", ":m '<-2<cr>gv=gv")

--> Nvim tree
vim.keymap.set("n", "<Leader>n", ":NvimTreeToggle<CR>")

--> Remove search Highlight
vim.keymap.set("n", "<Leader>/", ":nohlsearch<CR>", { silent = true })

--> yank all lines
vim.keymap.set("n", "<Leader>y", ":%y<CR>")

--> Count a single line as 2 if in two lines
vim.keymap.set("n", "k", 'v:count == 0 ? "gk" : "k"', { expr = true, silent = true })
vim.keymap.set("n", "j", 'v:count == 0 ? "gj" : "j"', { expr = true, silent = true })

--> Terminal
vim.keymap.set("n", "<Leader>l", ":vsplit term://fish <CR>", { silent = true })
vim.keymap.set("t", "<C-l>", "<C-\\><C-n>", { silent = true })

--> Open init.lua
vim.keymap.set("n", "<Leader>v", ":edit ~/.config/nvim/init.lua<CR>", { silent = true })

--> Dashboard keymap
vim.keymap.set("n", "<Leader>o", ":DashboardNewFile<CR>", { silent = true })

--> Telescope Keymap
vim.keymap.set("n", "<Leader>f", "<cmd>Telescope find_files hidden=True<CR>")
vim.keymap.set("n", "<Leader>t", require("telescope.builtin").treesitter)
vim.keymap.set("n", "<Leader>m", "<cmd>Telescope file_browser<CR>")

--> Commentary
vim.keymap.set({ "n", "v" }, "<Leader>c", ":Commentary<CR>", { silent = true })

--> Lsp-lines
vim.keymap.set("n", "<Leader>x", require("lsp_lines").toggle)

--> Toggle term
-- vim.keymap.set("n", "<C-l>", ":ToggleTerm<CR>", { silent = true })
