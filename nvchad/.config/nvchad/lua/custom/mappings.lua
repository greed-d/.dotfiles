---@type MappingsTable
local M = {}

M.general = {
	n = {
		[";"] = { ":", "enter command mode", opts = { nowait = true } },
		["<A-j>"] = { "m '>+1<CR>gv=gv", "Move up with Alt-j" },
		["<A-k>"] = { ":m '<-2<CR>gv=gv", "Move up with Alt-k" },
		["<S-h>"] = { "^", "Move up with Alt-k" },
		["<S-l>"] = { "$", "Move up with Alt-l" },
		[">"] = { ">gv", "Move Indent Right" },
		["<"] = { "<gv", "Move Indent Left" },
	},
	v = {
		["<A-j>"] = { ":m '>+1<cr>gv=gv", "Move up with Alt-j" },
		["<A-k>"] = { ":m '<-2<cr>gv=gv", "Move up with Alt-k" },
		["<S-h>"] = { "^", "Move up with Alt-k" },
		["<S-l>"] = { "$", "Move up with Alt-l" },
		["<"] = { "<gv", "Move Indent Left" },
		[">"] = { ">gv", "Move Indent Right" },
	},
	x = {
		["<S-h>"] = { "^", "Move up with Alt-k" },
		["<A-j>"] = { ":m '>+1<CR>gv=gv", "Move up with Alt-j" },
		["<A-k>"] = { ":m '<-2<CR>gv=gv", "Move up with Alt-k" },
		["<S-l>"] = { "$", "Move up with Alt-l" },
		["<"] = { "<gv", "Move Indent Left" },
		[">"] = { ">gv", "Move Indent Right" },
	},
}

M.harpoon = {
	n = {
		--Harpoon
		["<leader>hm"] = {
			function()
				require("harpoon.mark").add_file()
			end,
			"Mark using harpoon",
		},
		["<leader>ho"] = {
			function()
				require("harpoon.ui").toggle_quick_menu()
			end,
			"Open Harpoon quick menu",
		},
		["<leader>hn"] = {
			function()
				require("harpoon.ui").nav_next()
			end,
			"Navigate to next mark in harpoon",
		},
		["<leader>hp"] = {
			function()
				require("harpoon.ui").nav_prev()
			end,
			"Navigate to prev mark in harpoon",
		},
		["<leader>1"] = {
			function()
				require("harpoon.ui").nav_file(1)
			end,
			"Navigate to 1st mark in harpoon",
		},
		["<leader>2"] = {
			function()
				require("harpoon.ui").nav_file(2)
			end,
			"Navigate to 2nd mark in harpoon",
		},
		["<leader>3"] = {
			function()
				require("harpoon.ui").nav_file(3)
			end,
			"Navigate to 3rd mark in harpoon",
		},
		["<leader>4"] = {
			function()
				require("harpoon.ui").nav_file(4)
			end,
			"Navigate to 4th mark in harpoon",
		},
		["<leader>5"] = {
			function()
				require("harpoon.ui").nav_file(5)
			end,
			"Navigate to 5th mark in harpoon",
		},
	},
}
M.trouble = {
	n = {
		["<leader>xx"] = { "<cmd>TroubleToggle<CR>", "Toggle Trouble" },
		["<leader>xw"] = { "<cmd>TroubleToggle workspace_diagnostics<CR>", "Trouble Workspace Diagonstics" },
		["<leader>xd"] = { "<cmd>TroubleToggle document_diagnostics<CR>", "Trouble Workspace Diagonstics" },
	},
}

M.nvterm = {
	n = {
		["<leader>ht"] = {
			function()
				require("nvterm.terminal").new("horizontal")
			end,
			"new horizontal term",
		},
	},
}

M.tmuxNavigation = {
	n = {
		["<C-h>"] = { "<cmd>NvimTmuxNavigateLeft<CR>", "Nvim/TMUX navigate Left" },
		["<C-j>"] = { "<cmd>NvimTmuxNavigateDown<CR>", "Nvim/TMUX navigate Down" },
		["<C-k>"] = { "<cmd>NvimTmuxNavigateUp<CR>", "Nvim/TMUX navigate Up" },
		["<C-l>"] = { "<cmd>NvimTmuxNavigateRight<CR>", "Nvim/TMUX navigate Left" },
	},
}

M.telescope = {
	n = {
		["<leader>fl"] = { "<cmd>Telescope flutter commands<CR>", "Open flutter tools" },
	},
}

M.MiniMap = {
	n = {
		["<leader>mt"] = { "<cmd>lua MiniMap.toggle()<cr>", "Toggle MiniMap for given buffer" },
	},
}
-- more keybinds!

return M
