local transparent_windows = {
	-- [[ TERMINALS ]]
	terminals = {
		"kitty",
		"ghostty",
		"foot",
	},

	-- [[ APPS ]]
	"spotify-launcher",
}
hl.config({
	decoration = {
		active_opacity = 1.0,
		inactive_opacity = 1.0,
		blur = {
			enabled = true,
			size = 9,
			passes = 3,
			vibrancy = 0.1696,
		},
	},
})

for _, window in ipairs(transparent_windows) do
	-- hl.
end
