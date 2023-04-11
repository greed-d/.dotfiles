local M = {}

M.treesitter = {
  ensure_installed = {
    "vim",
    "lua",
    "html",
    "css",
    "javascript",
    "typescript",
    "tsx",
    "c",
    "markdown",
    "markdown_inline",
    "python",
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

    -- web dev stuff
    "css-lsp",
    "html-lsp",
    "typescript-language-server",
    "deno",
    "prettier",
    "emmet-ls",
    "json-lsp",

    --JS
    "eslint-lsp",

    -- shell
    "shfmt",
    "shellcheck",
    "codespell",

    -- Bash
    "bash-language-server",

    -- python
    "flake8",
    "python-lsp-server",
    "autopep8",

    -- pretty
    "prettier",
    "prettierd",

    -- c/cpp stuff
    "clangd",
    "clang-format",
  },
}

M.telescope = {
  opts = {
    extensions_list = { "flutter", "harpoon" },
    file_ignore_patterns = { ".git" },
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

return M
