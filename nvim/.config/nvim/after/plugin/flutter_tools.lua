local status, ftools = pcall(require, "flutter-tools")
if not status then
	return
end

ftools.setup({
	debugger = {
		enabled = false,
		run_via_dap = false,
	},
	outline = { auto_open = false },
	decorations = {
		statusline = { device = true, app_version = true },
	},
	widget_guides = { enabled = true, debug = false },
	dev_log = { enabled = true, open_cmd = "tabedit" },
	lsp = {
		on_attach = require("greed.handlers").on_attach,
		capabilities = require("greed.handlers").capabilities,
		color = {
			enabled = true,
			background = true,
			virtual_text = true,
		},
		settings = {
			showTodos = false,
			renameFilesWithClasses = "prompt",
			updateImportsOnRename = true,
			completeFunctionCalls = true,
			lineLength = 100,
		},
	},
})
