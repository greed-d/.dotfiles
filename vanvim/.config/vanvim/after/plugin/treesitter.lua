require("nvim-treesitter.configs").setup({
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
  highlight = { enable = true },
})
