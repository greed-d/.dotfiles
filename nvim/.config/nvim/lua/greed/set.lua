vim.o.clipboard = "unnamedplus"
vim.o.ignorecase = true
vim.o.lazyredraw = true
vim.o.number = true
vim.o.relativenumber = true
vim.o.shiftwidth = 2
vim.o.splitbelow = true
vim.o.splitright = true
vim.o.tabstop = 2
vim.o.termguicolors = true
vim.o.updatetime = 100
vim.o.hlsearch = false

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

local lang_maps = {
	cpp = { build = "g++ % -o %:r", exec = "./%:r" },
	c = { build = "g++ % -o %:r", exec = "./%:r" },
	typescript = { build = "deno compile %", exec = "deno run %" },
	javascript = { build = "deno compile %", exec = "deno run %" },
	python = { exec = "python %" },
	java = { build = "javac %", exec = "java %:r" },
	sh = { exec = "./%" },
	-- go = { build = "go build", exec = "go run %" },
	-- rust = { exec = "cargo run" },
	-- arduino = {
	-- 	build = "arduino-cli compile --fqbn arduino:avr:uno %:r",
	-- 	exec = "arduino-cli upload -p /dev/ttyACM0 --fqbn arduino:avr:uno %:r",
	-- },
}
for lang, data in pairs(lang_maps) do
	if data.build ~= nil then
		vim.api.nvim_create_autocmd(
			"FileType",
			{ command = "nnoremap <Leader>b :!" .. data.build .. "<CR>", pattern = lang }
		)
	end
	vim.api.nvim_create_autocmd(
		"FileType",
		{ command = "nnoremap <Leader>e :split<CR>:terminal " .. data.exec .. "<CR>", pattern = lang }
	)
end
vim.api.nvim_create_autocmd("BufWritePre", {
	command = "lua vim.lsp.buf.format()",
	pattern = "*.cpp,*.css,*.go,*.h,*.html,*.js,*.json,*.jsx,*.lua,*.md,*.py,*.rs,*.ts,*.tsx,*.yaml,*.c",
})
-- vim.api.nvim_create_autocmd("InsertEnter", { command = "set norelativenumber", pattern = "*" })
vim.api.nvim_create_autocmd("InsertLeave", { command = "set relativenumber", pattern = "*" })
vim.api.nvim_create_autocmd("TermOpen", { command = "startinsert", pattern = "*" })
vim.api.nvim_create_autocmd("BufWinEnter", { command = "set noexpandtab tabstop=2 shiftwidth=2", pattern = "*.rs" })
vim.api.nvim_create_autocmd("TextYankPost", {
	pattern = "*",
	callback = function()
		vim.highlight.on_yank({
			higroup = "IncSearch",
			timeout = 100,
		})
	end,
})

vim.api.nvim_command("sign define DiagnosticSignError text= texthl=DiagnosticSignError")
vim.api.nvim_command("sign define DiagnosticSignWarn text= texthl=DiagnosticSignWarn")
vim.api.nvim_command("sign define DiagnosticSignInfo text= texthl=DiagnosticSignInfo")
vim.api.nvim_command("sign define DiagnosticSignHint text= texthl=DiagnosticSignHint")

vim.diagnostic.config({ virtual_text = true })
