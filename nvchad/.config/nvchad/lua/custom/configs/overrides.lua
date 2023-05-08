local M = {}

M.treesitter = {
  ensure_installed = {
    -- vim/neovim
    "vim",
    "lua",

    --web dev
    "html",
    "css",
    "javascript",
    "typescript",
    "tsx",

    -- c/cpp
    "c",
    "cpp",

    --markdown
    "markdown",
    "markdown_inline",

    --fish/bash
    "bash",
    "fish",
  },
  indent = {
    enable = true,
    -- disable = {
    --   "python"
    -- },
  },
}

M.mason = {
  ensure_installed = {
    -- lua stuff
    "lua-language-server",
    "stylua",
    "selene",

    -- web dev stuff
    "css-lsp",
    "html-lsp",
    "typescript-language-server",
    "deno",
    "prettier",
    "eslint-lsp",

    -- shell
    "shfmt",
    "shellcheck",
    "codespell",
    "bash-language-server",

    -- python
    "flake8",
    "python-lsp-server",
    "black",

    -- pretty
    "prettier",
    "prettierd",

    -- c/cpp stuff
    "clangd",
    "clang-format",
    "cspell",

    --markdown
    "marksman",
  },
}
-- git support in nvimtree
M.nvimtree = {
  git = {
    enable = true,
  },

  renderer = {
    highlight_git = true,
    icons = {
      show = {
        git = true,
      },
    },
  },
}

M.telescope = {
  opts = {
    default = {
      file_ignore_pattern = { ".git" },
    },
    extension_list = { "notify", "flutter" },
  },
}

M.nvterm = {
  terminals = {
    shell = vim.o.shell,
    list = {},
    type_opts = {
      float = {
        relative = "editor",
        row = 0.16,
        col = 0.09,
        width = 0.75,
        height = 0.7,
        border = "single",
      },
      horizontal = { location = "rightbelow", split_ratio = 0.3 },
      vertical = { location = "rightbelow", split_ratio = 0.5 },
    },
  },
}

M.gitsigns = {
  signs = {
    add = { hl = "DiffAdd", text = "+", numhl = "GitSignsAddNr" },
    change = { hl = "DiffChange", text = "│", numhl = "GitSignsChangeNr" },
    delete = { hl = "DiffDelete", text = "-", numhl = "GitSignsDeleteNr" },
    topdelete = { hl = "DiffDelete", text = "‾", numhl = "GitSignsDeleteNr" },
    changedelete = { hl = "DiffChangeDelete", text = "~", numhl = "GitSignsChangeNr" },
    untracked = { hl = "GitSignsAdd", text = "┆", numhl = "GitSignsAddNr", linehl = "GitSignsAddLn" },
  },
}

return M
