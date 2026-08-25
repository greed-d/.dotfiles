------------------------------
---------- KEYBINDS ----------
------------------------------

local global = require("globals")
local mainMod = "SUPER"

-- Applications
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd("app2unit -- " .. global.terminal))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("app2unit -- " .. global.browser))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("app2unit -- " .. global.file_manager))
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("app2unit -- vesktop"))
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("app2unit -- spotify-launcher"))

-- Window management
hl.bind(mainMod .. " + W", hl.dsp.window.close())
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + S", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + O", hl.dsp.exec_cmd("hyprctl dispatch overview"))

-- Power
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.exec_cmd("systemctl poweroff"))

hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("systemctl reboot"))

hl.bind(
	mainMod .. " + CTRL + Q",
	hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'")
)

hl.bind(mainMod .. " + Alt_L + P", hl.dsp.exec_cmd("hyprctl dispatch dpms off"))

-- Screenshots
hl.bind("Print", hl.dsp.exec_cmd("grimblast --notify copysave screen"))

hl.bind(mainMod .. " + Alt_L + S", hl.dsp.exec_cmd("grimblast --notify copysave screen"))

-- Sticky
-- hl.bind(mainMod .. " + A", hl.dsp.window.sticky())

-- Emoji picker
hl.bind(mainMod .. " + slash", hl.dsp.exec_cmd("vicinae vicinae://launch/core/search-emojis"))

-- Mouse binds
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true, desc = "Drag window" })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true, desc = "Resize window" })

-- Volume
hl.bind(
	mainMod .. " + Up",
	hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 10%+ -l 1.5"),
	{ locked = true, repeating = true }
)

hl.bind(
	mainMod .. " + Down",
	hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 10%-"),
	{ locked = true, repeating = true }
)

-- Focus
hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }))

-- Move window
hl.bind(mainMod .. " +CTRL + H", hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " +CTRL + J", hl.dsp.window.move({ direction = "down" }))
hl.bind(mainMod .. " +CTRL + K", hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " +CTRL + L", hl.dsp.window.move({ direction = "right" }))

-- Monitor focus
hl.bind(mainMod .. " + SHIFT + Left", hl.dsp.focus({ monitor = "l" }))
hl.bind(mainMod .. " + SHIFT + Down", hl.dsp.focus({ monitor = "d" }))
hl.bind(mainMod .. " + SHIFT + Up", hl.dsp.focus({ monitor = "u" }))
hl.bind(mainMod .. " + SHIFT + Right", hl.dsp.focus({ monitor = "r" }))

-- Move window to monitor
hl.bind(mainMod .. " + SHIFT + CTRL + Left", hl.dsp.window.move({ monitor = "l" }))
hl.bind(mainMod .. " + SHIFT + CTRL + Down", hl.dsp.window.move({ monitor = "d" }))
hl.bind(mainMod .. " + SHIFT + CTRL + Up", hl.dsp.window.move({ monitor = "u" }))
hl.bind(mainMod .. " + SHIFT + CTRL + Right", hl.dsp.window.move({ monitor = "r" }))

-- Workspace navigation
hl.bind(mainMod .. " + U", hl.dsp.focus({ workspace = "e-1" }))

hl.bind(mainMod .. " + I", hl.dsp.focus({ workspace = "e+1" }))

-- hl.bind(mainMod .. " + WheelScrollDown", hl.dsp.focus({ workspace = "e+1" }))
-- hl.bind(mainMod .. " + WheelScrollUp", hl.dsp.focus({ workspace = "e-1" }))

-- Workspace binds
local workspaces = {
	1,
	2,
	3,
	4,
	5,
	6,
	7,
	8,
	9,
}

for key, workspace in pairs(workspaces) do
	hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = workspace }))

	hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = workspace }))
end

-- Special workspace
hl.bind(mainMod .. " + SHIFT + U", hl.dsp.window.move({ workspace = "special" }), { desc = "Move to scratchpad" })
hl.bind(mainMod .. " + U", hl.dsp.workspace.toggle_special(), { desc = "Toggle scratchpad" })

-- Group management
hl.bind(mainMod .. " + G", hl.dsp.group.toggle(), { desc = "Toggle window group" })
hl.bind(mainMod .. " + CTRL + Tab", hl.dsp.group.next(), { desc = "Next window in group" })

-- Window cycling
hl.bind("ALT + Tab", function()
	hl.dispatch(hl.dsp.window.cycle_next())
	hl.dispatch(hl.dsp.window.alter_zorder({ mode = "top" }))
end, { desc = "Cycle windows (alt-tab)" })

-- Column/window sizing equivalents
-- hl.bind(mainMod .. " + Minus", hl.dsp.window.resize({ width = "-10%" }))

-- hl.bind(mainMod .. " + Equal", hl.dsp.window.resize({ width = "+10%" }))

-- hl.bind(mainMod .. " + SHIFT + Minus", hl.dsp.window.resize({ height = "-10%" }))

-- hl.bind(mainMod .. " + SHIFT + Equal", hl.dsp.window.resize({ height = "+10%" }))
