local present, null_ls = pcall(require, "null-ls")

if not present then
	return
end

local b = null_ls.builtins

local sources = {

	-- webdev stuff
	b.formatting.deno_fmt, -- choosed deno for ts/js files cuz its very fast!
	b.formatting.prettier, -- so prettier works only on these filetypes
	b.formatting.prettierd.with({ filetypes = { "html", "markdown", "css" } }), -- so prettier works only on these filetypes

	-- Lua
	b.formatting.stylua,
	b.diagnostics.selene,

	-- cpp
	b.formatting.clang_format,
	b.diagnostics.cpplint,
	-- b.diagnostics.cspell,

	-- shell
	b.formatting.shfmt,

	--python
	b.formatting.black,
	b.diagnostics.flake8,
}

null_ls.setup({
	debug = true,
	sources = sources,
})
