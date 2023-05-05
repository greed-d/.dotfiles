local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({

  -- Install a plugin
  {
    "tiagovla/tokyodark.nvim",
    config = function()
      -- init.lua
      vim.g.tokyodark_transparent_background = false
      vim.g.tokyodark_enable_italic_comment = true
      vim.g.tokyodark_enable_italic = true
      vim.g.tokyodark_color_gamma = "1.0"
      vim.cmd("colorscheme tokyodark")
    end,
  },
  { "hrsh7th/nvim-cmp" },
  { "jose-elias-alvarez/null-ls.nvim" },
  { "lewis6991/gitsigns.nvim" },
  { "neovim/nvim-lspconfig" },
  { "windwp/nvim-autopairs" },
  { "williamboman/mason.nvim" },
  { "williamboman/mason-lspconfig.nvim" },
  { "github/copilot.vim" },
  { "lukas-reineke/indent-blankline.nvim" },
  { "nvim-treesitter/nvim-treesitter" },
  { "nvim-lua/plenary.nvim" },
  { "hrsh7th/cmp-nvim-lsp" },
  { "onsails/lspkind-nvim" },
  { "saadparwaiz1/cmp_luasnip" },
  { "tpope/vim-commentary" },

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
    "utilyre/barbecue.nvim",
    name = "barbecue",
    version = "*",
    event = "BufReadPre",
    dependencies = {
      "SmiteshP/nvim-navic",
      "nvim-tree/nvim-web-devicons", -- optional dependency
    },
    opts = {
      -- configurations go here
    },
    config = function()
      require("barbecue").setup({})
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
})
