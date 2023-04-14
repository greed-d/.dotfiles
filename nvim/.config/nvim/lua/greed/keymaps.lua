local map = vim.keymap.set
local options = { noremap = true, silent = true }
vim.g.mapleader = " "

map({ "n", "v" }, "<Space>", "<Nop>", { silent = true })

--> Movement/Deleting/Navigating
-- map("n", "<Leader>w", "<C-w>k")
-- map("n", "<Leader>a", "<C-w>h")
-- map("n", "<Leader>s", "<C-w>j")
-- map("n", "<Leader>d", "<C-w>l")

map("n", "<Leader>q", ":bprevious<CR>:bdelete #<CR>", { silent = true })
map("n", "<A-j>", "V:m '>+1<cr>gv=gv<esc>")
map("n", "<A-k>", "V:m '<-2<cr>gv=gv<esc>")
map({ "v", "x" }, "<A-j>", ":m '>+1<cr>gv=gv")
map({ "v", "x" }, "<A-k>", ":m '<-2<cr>gv=gv")
map({ "n", "x" }, "<S-h>", "^", options)
map({ "n", "x" }, "<S-l>", "$", options)

--> Nvim tree
map("n", "<Leader>nt", ":NvimTreeToggle<CR>")

--> Remove search Highlight
map("n", "<Leader>/", ":nohlsearch<CR>", { silent = true })

--> yank all lines
map("n", "<Leader>y", ":%y<CR>")

--> Terminal
map("n", "<Leader>l", ":85vsplit term://fish <CR>", { silent = true })

--> Escape terminal mode
-- map("t", "<C-l>", "<C-\\><C-n>", { silent = true })

--> Telescope Keymap
map("n", "<Leader>ff", "<cmd>Telescope find_files hidden=True<CR>")
map("n", "<Leader>ft", require("telescope.builtin").treesitter)
map("n", "<Leader>fm", "<cmd>Telescope file_browser<CR>")
map("n", "<leader>fb", "<cmd>Telescope buffers<cr>", options)
map("n", "<leader>fg", "<cmd>Telescope live_grep hidden=True<cr>", options)
map("n", "<leader>fl", "<cmd>Telescope flutter commands<CR>", options)

--> Commentary
map({ "n", "v" }, "<Leader>c", ":Commentary<CR>", { silent = true })

--> Lsp-lines
map("n", "<leader>x", ":TroubleToggle<cr>", options)

--> Harpoon
map("n", "<leader>m", function()
	require("harpoon.mark").add_file()
end, options)

map("n", "<leader>o", function()
	require("harpoon.ui").toggle_quick_menu()
end, options)
map("n", "<leader>jj", function()
	require("harpoon.ui").nav_prev()
end, options)
map("n", "<leader>kk", function()
	require("harpoon.ui").nav_next()
end, options)

map("n", "<leader>1", function()
	require("harpoon.ui").nav_file(1)
end, options)
map("n", "<leader>2", function()
	require("harpoon.ui").nav_file(2)
end, options)
map("n", "<leader>3", function()
	require("harpoon.ui").nav_file(3)
end, options)
map("n", "<leader>4", function()
	require("harpoon.ui").nav_file(4)
end, options)
map("n", "<leader>5", function()
	require("harpoon.ui").nav_file(5)
end, options)

map("n", "<A-h>", ":bprevious<CR>", { silent = true })
map("n", "<A-l>", ":bnext<CR>", { silent = true })

--> Count a single line as 2 if in two lines
-- map("n", "k", 'v:count == 0 ? "gk" : "k"', options)
-- map("n", "j", 'v:count == 0 ? "gj" : "j"', options)

--> Open init.lua
-- map("n", "<Leader>v", ":edit ~/.config/nvim/init.lua<CR>", { silent = true })

--> Dashboard keymap
-- map("n", "<Leader>o", ":DashboardNewFile<CR>", { silent = true })

--> Toggle term
-- map("n", "<C-l>", ":ToggleTerm<CR>", { silent = true })
