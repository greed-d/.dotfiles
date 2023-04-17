local present, null_ls = pcall(require, "null-ls")

if not present then
	return
end

local b = null_ls.builtins

local sources = {

	-- webdev stuff
	b.formatting.deno_fmt, -- choosed deno for ts/js files cuz its very fast!
	b.formatting.prettier.with({ filetypes = { "html", "markdown", "css" } }), -- so prettier works only on these filetypes
	b.formatting.prettierd.with({ filetypes = { "jsonc" } }), -- so prettier works only on these filetypes

	-- Lua
	b.formatting.stylua,

	-- cpp
	b.formatting.clang_format,

	-- shell
	b.formatting.shfmt,
	b.formatting.codespell,

	--python
	b.formatting.autopep8,
}

null_ls.setup({
	debug = true,
	sources = sources,
})
--      autopep8
--      clang-format
--      prettier
--      prettierd
--      shfmt
--      stylua
--
