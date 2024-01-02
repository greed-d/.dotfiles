vim.api.nvim_create_user_command("PeekOpen", function()
	require("peek").open()
end, {})

vim.api.nvim_create_user_command("PeekClose", function()
	require("peek").close()
end, {})

vim.api.nvim_create_user_command("Nvtfloat", function()
	require("nvterm.terminal").toggle("float")
end, {})

vim.api.nvim_create_user_command("NotifLog", function()
	require("notify").history()
end, {})

---------------------------------------> Neovide Options <----------------------------------
--
-- vim.g.neovide_scale_factor = 1.28
--
local change_scale_factor = function(delta)
	vim.g.neovide_scale_factor = vim.g.neovide_scale_factor * delta
end

vim.keymap.set("n", "<C-=>", function()
	change_scale_factor(1.1)
end)
vim.keymap.set("n", "<C-->", function()
	change_scale_factor(1 / 1.111111)
end)
