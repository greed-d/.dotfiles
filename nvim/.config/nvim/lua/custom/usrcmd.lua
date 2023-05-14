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
