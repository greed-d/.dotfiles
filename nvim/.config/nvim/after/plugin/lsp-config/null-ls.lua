local null_ls = require("null-ls")
null_ls.setup({
	sources = {
		null_ls.builtins.diagnostics.eslint_d,
		null_ls.builtins.formatting.eslint_d,
		null_ls.builtins.formatting.black,
		--null_ls.builtins.formatting.gofmt,
		null_ls.builtins.formatting.prettierd,
		-- null_ls.builtins.formatting.rustfmt,
		null_ls.builtins.formatting.stylua,
	},
})
