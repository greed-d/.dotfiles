local autocmd = vim.api.nvim_create_autocmd
local opt = vim.opt

-- local new_cmd = vim.api.nvim_create_user_command
-- local g = vim.g

-------------------------------------- settings ------------------------------------------

opt.rnu = true

-------------------------------------- language-maps ------------------------------------------

local lang_maps = {
	cpp = { build = "g++ % -o %:r", exec = "./%:r" },
	c = { build = "g++ % -o %:r", exec = "./%:r" },
	typescript = { build = "deno compile %", exec = "deno run %" },
	javascript = { build = "deno compile %", exec = "deno run %" },
	python = { exec = "python %" },
	java = { build = "javac %", exec = "java %:r" },
	sh = { exec = "./%" },
	prolog = { exec = "gplc %" },
}
for lang, cmd in pairs(lang_maps) do
	if cmd.build ~= nil then
		autocmd("FileType", { command = "nnoremap <Leader>b :!" .. cmd.build .. "<CR>", pattern = lang })
	end
	autocmd(
		"FileType",
		{ command = "nnoremap <Leader>e :90vsplit<CR>:terminal " .. cmd.exec .. "<CR>", pattern = lang }
	)
end

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

vim.api.nvim_create_autocmd("BufWritePre", {
	command = "lua vim.lsp.buf.format()",
	pattern = "*.cpp,*.css,*.go,*.h,*.html,*.js,*.json,*.jsx,*.lua,*.md,*.py,*.rs,*.ts,*.tsx,*.yaml,*.c,*.dart",
})

--vim.api.nvim_create_user_command("PeekOpen", require("peek").open, {})
--vim.api.nvim_create_user_command("PeekClose", require("peek").close, {})
--vim.api.nvim_create_user_command('PeekOpen', require('peek').open, {})
--vim.api.nvim_create_user_command('PeekClose', require('peek').close, {})
--vim.api.nvim_create_user_command("PeekOpen", require("peek").open, {})
--vim.api.nvim_create_user_command("PeekClose", require("peek").close, {})
