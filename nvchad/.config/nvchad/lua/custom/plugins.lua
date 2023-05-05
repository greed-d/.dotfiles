local overrides = require("custom.configs.overrides")

---@type NvPluginSpec[]
local plugins = {

  {
    "neovim/nvim-lspconfig",
    dependencies = {
      -- format & linting
      {
        "jose-elias-alvarez/null-ls.nvim",
        config = function()
          require("custom.configs.null-ls")
        end,
      },
    },
    config = function()
      require("plugins.configs.lspconfig")
      require("custom.configs.lspconfig")
    end, -- Override to setup mason-lspconfig
  },

  -- override plugin configs
  {
    "williamboman/mason.nvim",
    opts = overrides.mason,
  },

  {
    "nvim-treesitter/nvim-treesitter",
    opts = overrides.treesitter,
  },

  {
    "nvim-tree/nvim-tree.lua",
    opts = overrides.nvimtree,
  },

  {
    "nvim-telescope/telescope.nvim",
    opts = overrides.telescope,
  },

  {
    "lewis6991/gitsigns.nvim",
    opts = overrides.gitsigns,
  },

  {
    "NvChad/nvterm",
    opts = overrides.nvterm,
  },

  -- Install a plugin

  {
    "max397574/better-escape.nvim",
    event = "InsertEnter",
    config = function()
      require("better_escape").setup()
    end,
  },

  {
    "andweeb/presence.nvim",
    event = "BufReadPre",
    config = function()
      require("presence").setup()
    end,
  },

  {
    "folke/trouble.nvim",
    event = "BufReadPre",
    config = function()
      require("trouble").setup()
    end,
  },

  {
    "ThePrimeagen/harpoon",
    event = "BufReadPre",
    config = function()
      require("harpoon").setup()
    end,
  },

  {
    "arnamak/stay-centered.nvim",
    event = "BufReadPre",
    config = function()
      require("stay-centered")
    end,
  },

  {
    "toppair/peek.nvim",
    build = "deno task --quiet build:fast",
    config = function()
      require("peek").setup()
    end,
  },

  {
    "romainl/vim-cool",
    event = "BufReadPre",
  },

  {
    "airblade/vim-rooter",
    event = "BufReadPre",
  },

  {
    "echasnovski/mini.nvim",
    event = "BufReadPre",
    config = function()
      require("custom.configs.extras.minimap")
    end,
  },

  {
    "akinsho/flutter-tools.nvim",
    lazy = true,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "stevearc/dressing.nvim", -- optional for vim.ui.select
      config = function()
        require("flutter-tools").setup({})
      end,
    },
  },

  {
    "alexghergh/nvim-tmux-navigation",
    event = "VeryLazy",
    config = function()
      require("nvim-tmux-navigation").setup({ disable_when_zoomed = true }) -- defaults to false
    end,
  },

  {
    "mbbill/undotree",
    event = "BufReadPre",
  },

  {
    "mfussenegger/nvim-dap-python",
    event = "BufReadPre",
  },

  -- Lua

  {
    "folke/zen-mode.nvim",
    cmd = "ZenMode",
    config = function()
      require("zen-mode").setup({})
    end,
  },

  {
    "tpope/vim-surround",
    event = "VeryLazy",
  },

  {
    "rcarriga/nvim-notify",
    event = "VeryLazy",
    config = function()
      require("notify").setup({
        stages = "fade_in_slide_out",
        background_colour = "FloatShadow",
        timeout = 1000,
      })
      vim.notify = require("notify")
    end,
  },

  {
    "elkowar/yuck.vim",
    ft = "yuck",
  },

  -- To make a plugin not be loaded
  -- {
  --   "NvChad/nvim-colorizer.lua",
  --   enabled = false
  -- },
}

return plugins
