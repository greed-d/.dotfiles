---@type MappingsTable
local M = {}

-- local opt = {}
M.disabled = {
  n = {
    ["<leader>h"] = "",
    ["<leader>x"] = "",
    ["<leader>b"] = "",
  },
}

M.general = {
  n = {
    [";"] = { ":", "enter command mode", opts = { nowait = true } },
    ["<A-j>"] = { "V:m '>+1<cr>gv=gv<esc>", "Move up with Alt-j", opts = { silent = true } },
    ["<A-k>"] = { "V:m '<-2<cr>gv=gv<esc>", "Move up with Alt-k", opts = { silent = true } },
    ["<S-h>"] = { "^", "Move up with Alt-k" },
    ["<S-l>"] = { "$", "Move up with Alt-l" },
    ["<"] = { "<gv", "Move Indent Left" },
    [">"] = { ">gv", "Move Indent Right" },
    ["<leader>bf"] = { "<cmd> new <CR>", "new buffer", opts = { silent = true } },
    ["<leader>to"] = { "<cmd> tabnew <CR> ", "create new tab", opts = { silent = true } },
    ["<leader>tn"] = { "<cmd> tabn <CR> ", "go to next tab", opts = { silent = true } },
    ["<leader>tp"] = { "<cmd> tabprev <CR> ", "go to previous tab", opts = { silent = true } },
    ["<leader>lg"] = { "<cmd> LazyGit <CR>", "Open LazyGit", opts = { silent = true } },
    -- ["<A-,>" = {}]
  },

  v = {
    ["<A-j>"] = { ":m '>+1<CR>gv=gv", "Move up with Alt-j", opts = { silent = true } },
    ["<A-k>"] = { ":m '<-2<CR>gv=gv", "Move up with Alt-k", opts = { silent = true } },
    ["<S-h>"] = { "^", "Move up with Alt-k" },
    ["<S-l>"] = { "$", "Move up with Alt-l" },
    ["<"] = { "<gv", "Move Indent Left" },
    [">"] = { ">gv", "Move Indent Right" },
  },
  x = {
    ["<S-h>"] = { "^", "Move up with Alt-k" },
    ["<S-l>"] = { "$", "Move up with Alt-l" },
    ["<A-j>"] = { ":m '>+1<CR>gv=gv", "Move up with Alt-j", opts = { silent = true } },
    ["<A-k>"] = { ":m '<-2<CR>gv=gv", "Move up with Alt-k", opts = { silent = true } },
    ["<"] = { "<gv", "Move Indent Left" },
    [">"] = { ">gv", "Move Indent Right" },
  },
}

M.tabufline = {
  plugin = true,

  n = {
    -- close buffer + hide terminal buffer
    ["<leader>k"] = {
      function()
        require("nvchad_ui.tabufline").close_buffer()
      end,
      "close buffer",
    },
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

    ["<leader>bu"] = {
      function()
        local file = vim.fn.expand("%")
        local sfile = vim.fn.expand("%:r")
        local ft_cmds = {
          sh = "bash " .. file,
          rust = "cargo " .. file,
          prolog = "glpc " .. file,
          python = "python3 " .. file,
          go = "go build && go run " .. file,
          c = "g++ " .. file .. " -o " .. sfile .. " && ./" .. sfile,
          cpp = "g++ " .. file .. " -o " .. sfile .. " && ./" .. sfile,
          javascript = "deno compile " .. file .. " && deno run " .. file,
          typescript = "deno compile " .. file .. " && deno run " .. file,
          arduino = "arduino-cli complile --fqbn arduino:avr:uno "
              .. sfile
              .. " && arduino-cli upload -p /dev/ttyACM0 --fqbn arduino:avr:uno "
              .. sfile,
        }

        require("nvterm.terminal").send(ft_cmds[vim.bo.filetype], "float")
      end,

      "compile & run a file",
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

M.UndoTree = {
  n = {
    ["<leader>ut"] = { "<cmd>UndotreeToggle<CR>", "Toggle Trouble" },
    ["<leader>ue"] = { "<cmd>UndotreeFocus<CR>", "Toggle Trouble" },
  },
}
-- more keybinds!

return M
