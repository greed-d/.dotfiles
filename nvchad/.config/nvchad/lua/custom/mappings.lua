---@type MappingsTable
local M = {}

M.general = {
  n = {
    [";"] = { ":", "enter command mode", opts = { nowait = true } },
    ["<A-j>"] = { "V:m '>+1<cr>gv=gv<esc>", "Move up with Alt-j" },
    ["<A-k>"] = { "V:m '<-2<cr>gv=gv<esc>", "Move up with Alt-k" },
    ["<S-h>"] = { "^", "Move up with Alt-k" },
    ["<S-l>"] = { "$", "Move up with Alt-l" },
  },
  v = {
    ["<A-j>"] = { "V:m '>+1<cr>gv=gv<esc>", "Move up with Alt-j" },
    ["<A-k>"] = { "V:m '<-2<cr>gv=gv<esc>", "Move up with Alt-k" },
    ["<S-h>"] = { "^", "Move up with Alt-k" },
    ["<S-l>"] = { "$", "Move up with Alt-l" },
  }
}

M.harpoon = {
  n = {
    ["<leader>hm"] = {
      function()
        require("harpoon.mark").add_file()
      end,
      "Mark file with harpoon",
    },

    ["<leader>ho"] = {
      function()
        require("harpoon.ui").toggle_quick_menu()
      end,
      "Mark file with harpoon",
    },
    ["<leader>hp"] = {
      function()
        require("harpoon.ui").nav_prev()
      end,
      "Mark file with harpoon",
    },
    ["<leader>hn"] = {
      function()
        require("harpoon.ui").nav_next()
      end,
      "Mark file with harpoon",
    },
     ["<leader>1"] = {
      function()
        require("harpoon.ui").nav_file(1)
      end,
      "Go to file 1 in harpoon",
    },
    ["<leader>2"] = {
      function()
        require("harpoon.ui").nav_file(2)
      end,
      "Go to file 2 in harpoon",
    },
    ["<leader>3"] = {
      function()
        require("harpoon.ui").nav_file(3)
      end,
      "Go to file 3 in harpoon",
    },
     ["<leader>4"] = {
      function()
        require("harpoon.ui").nav_file(3)
      end,
      "Go to file 4 in harpoon",
    },
  },
}

M.trouble = {
  n = {
    ["<leader>xx"] = { "<cmd>TroubleToggle<CR>", "Toggle Trouble" },
    ["<leader>xw"] = { "<cmd>TroubleToggle workspace_diagnostics<CR>", "Trouble Workspace Diagonstics" },
    ["<leader>xd"] = { "<cmd>TroubleToggle document_diagnostics<CR>", "Trouble Workspace Diagonstics" },
  }
}

M.nvterm = {
  n = {
  ["<leader>ht"] = {
    function()
      require("nvterm.terminal").new "horizontal"
    end,
    "new horizontal term",
    }
  }
}
-- more keybinds!

return M
