---@type MappingsTable
local M = {}

M.general = {
  n = {
    -- [";"] = { ":", "enter command mode", opts = { nowait = true } },

    -- Moving lines up and down
    ["<A-j>"] = { "V:m '>+1<cr>gv=gv<esc>", "move line down with alt and movement key" },
    ["<A-k>"] = { "V:m '<-2<cr>gv=gv<esc>", "move line up with alt and movement key" },

    -- Moving between beginning and end_ of line made easier
    ["<S-h>"] = { "^", "Move to beginning of the line" },
    ["<S-l>"] = { "$", "Move to end of the line" },
  },

  v = {
    ["<A-j>"] = { "V:m '>+1<cr>gv=gv<esc>", "move line down with alt and movement key" },
    ["<A-k>"] = { "V:m '<-2<cr>gv=gv<esc>", "move line up with alt and movement key" },
    --
    -- Moving between beginning and end_ of line made easier
    ["<S-h>"] = { "^", "Move to beginning of the line" },
    ["<S-l>"] = { "$", "Move to end of the line" },
  },

  x = {
    ["<"] = { "<gv", "move indent left" },
    [">"] = { ">gv", "move indent right" },
  },
}

M.trouble = {
  n = {
    ["<leader>tt"] = { "<cmd>TroubleToggle<cr>", "Toggle Trouble" },
    ["<leader>tw"] = { "<cmd>TroubleToggle workspace_diagnostics<cr>", "Toggle Trouble for given workspace" },
    ["<leader>tc"] = { "<cmd>TroubleToggle document_diagnostics<cr>", "Toggle Trouble for given buffer" },
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
    ["<leader>fl"] = { "<cmd>Telescope flutter tools<CR>", "Open flutter tools" },
  },
}

M.MiniMap = {
  n = {
    ["<leader>mt"] = { "<cmd>lua MiniMap.toggle()<cr>", "Toggle MiniMap for given buffer" },
  },
}
-- more keybinds!

return M
