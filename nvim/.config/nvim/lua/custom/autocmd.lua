local autocmd = vim.api.nvim_create_autocmd

-------------------------------------- highlight on yanked ------------------------------------------

autocmd("TextYankPost", {
	pattern = "*",
	callback = function()
		vim.highlight.on_yank({
			higroup = "IncSearch",
			timeout = 100,
		})
	end,
})

-------------------------------------- format on save ------------------------------------------

autocmd("BufWritePre", {
	command = "lua vim.lsp.buf.format()",
	pattern = "*.cpp,*.css,*.go,*.h,*.html,*.js,*.json,*.jsx,*.lua,*.md,*.py,*.rs,*.ts,*.tsx,*.yaml,*.c,*.dart,*.jsonc",
})

-------------------------------------> Send Focus to temrinal <------------------------------------

-- TODO: Send focus to terminal after executing `bu`

-- autocmd("BufNewFile", {
--   callback = function ()
--
--
--   end
-- })
