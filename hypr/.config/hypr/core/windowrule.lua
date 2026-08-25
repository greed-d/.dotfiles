--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------
-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- and https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/

-- Example window rules that are useful
local suppressMaximizeRule = hl.window_rule({
	-- Ignore maximize requests from all apps. You'll probably like this.
	name = "suppress-maximize-events",
	match = { class = ".*" },

	suppress_event = "maximize",
})

local function tag_by_class(tag_name, patterns)
	for _, pattern in ipairs(patterns) do
		hl.window_rule({
			match = { class = pattern },
			tag = tag_name,
		})
	end
end

local function tag_by_title(tag_name, patterns)
	for _, pattern in ipairs(patterns) do
		hl.window_rule({
			match = { title = pattern },
			tag = tag_name,
		})
	end
end

-- Apply multiple properties to a single match in one rule
local function rule(match_spec, props)
	local rule_spec = { match = match_spec }
	for k, v in pairs(props) do
		rule_spec[k] = v
	end
	hl.window_rule(rule_spec)
end

-- Apply a property to multiple tagged windows
local function apply_to_tag(tag_name, props)
	rule({ tag = tag_name }, props)
end

hl.config({
	general = {
		gaps_in = 5,
		gaps_out = 5,

		border_size = 2,

		col = {
			active_border = { colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 45 },
			inactive_border = "rgba(595959aa)",
		},
	},
})

-- suppressMaximizeRule:set_enabled(false)

hl.window_rule({
	-- Fix some dragging issues with XWayland
	name = "fix-xwayland-drags",
	match = {
		class = "^$",
		title = "^$",
		xwayland = true,
		float = true,
		fullscreen = false,
		pin = false,
	},

	no_focus = true,
})

-- Hyprland-run windowrule
hl.window_rule({
	name = "move-hyprland-run",
	match = { class = "hyprland-run" },

	move = "20 monitor_h-120",
	float = true,
})

-----------------------
---- LOOK AND FEEL ----
-----------------------

-- Refer to https://wiki.hypr.land/Configuring/Basics/Variables/

-- Ref https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/
-- "Smart gaps" / "No gaps when only"
-- uncomment all if you wish to use that.
hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
hl.workspace_rule({ workspace = "f[1]", gaps_out = 0, gaps_in = 0 })
hl.window_rule({
	name = "no-gaps-wtv1",
	match = { float = false, workspace = "w[tv1]" },
	border_size = 0,
	rounding = 0,
})
hl.window_rule({
	name = "no-gaps-f1",
	match = { float = false, workspace = "f[1]" },
	border_size = 0,
	rounding = 0,
})

tag_by_class("browser", {
	"^([Ff]irefox|org.mozilla.firefox|[Ff]irefox-esr|[Ff]irefox-bin|firefox-nightly)$",
	"^([Gg]oogle-chrome(-beta|-dev|-unstable)?)$",
	"^(chrome-.+-Default)$",
	"^([Cc]hromium)$",
	"^([Mm]icrosoft-edge(-stable|-beta|-dev|-unstable))$",
	"^(Brave-browser(-beta|-dev|-unstable)?)$",
	"^([Tt]horium-browser|[Cc]achy-browser)$",
	"^(zen-alpha|zen)$",
})

tag_by_class("devtools", { "^(Developer Tools.*)$" })

tag_by_class("notif", { "^(swaync-control-center|swaync-notification-window|swaync-client|class)$" })

tag_by_class("terminal", { "^(Alacritty|kitty|kitty-dropterm)$" })

tag_by_class("email", {
	"^([Tt]hunderbird|org.gnome.Evolution)$",
	"^(eu.betterbird.Betterbird)$",
})

tag_by_class("projects", {
	"^(codium|codium-url-handler|VSCodium)$",
	"^(VSCode|code-url-handler)$",
	"^(jetbrains-.+)$",
})

tag_by_class("screenshare", { "^(com.obsproject.Studio)$" })

tag_by_class("im", {
	"^([Dd]iscord|[Ww]ebCord|[Vv]esktop)$",
	"^([Ff]erdium)$",
	"^([Ww]hatsapp-for-linux)$",
	"^(ZapZap|com.rtosta.zapzap)$",
	"^(org.telegram.desktop|io.github.tdesktop_x64.TDesktop)$",
	"^(teams-for-linux)$",
	"^(im.riot.Riot|Element)$",
})

tag_by_class("games", {
	"^(gamescope)$",
	"^(steam_app_\\d+)$",
})

tag_by_class("gamestore", {
	"^([Ss]team)$",
	"^(com.heroicgameslauncher.hgl)$",
})

tag_by_title("gamestore", { "^([Ll]utris)$" })

tag_by_class("file-manager", {
	"^([Tt]hunar|org.gnome.Nautilus|[Pp]cmanfm-qt)$",
	"^(app.drey.Warp)$",
})

tag_by_class("wallpaper", { "^([Ww]aytrogen)$" })

tag_by_class("multimedia", { "^([Aa]udacious)$", "^[Ss]potify*" })

tag_by_class("multimedia_video", { "^([Mm]pv|vlc)$" })

tag_by_class("settings", {
	"^(wihotspot(-gui)?)$",
	"^([Bb]aobab|org.gnome.[Bb]aobab)$",
	"^(gnome-disks|wihotspot(-gui)?)$",
	"^(file-roller|org.gnome.FileRoller)$",
	"^(nm-applet|nm-connection-editor|blueman-manager)$",
	"^(pavucontrol|org.pulseaudio.pavucontrol|com.saivert.pwvucontrol)$",
	"^(qt5ct|qt6ct|[Yy]ad)$",
	"(xdg-desktop-portal-gtk)",
	"^(org.kde.polkit-kde-authentication-agent-1)$",
	"^([Rr]ofi)$",
})

tag_by_title("settings", {
	"^(ROG Control)$",
	"(Kvantum Manager)",
})

tag_by_class("viewer", {
	"^(gnome-system-monitor|org.gnome.SystemMonitor|io.missioncenter.MissionCenter)$",
	"^(evince)$",
	"^(eog|org.gnome.Loupe)$",
})

-- Thunar dialogs (not main window)
local thunar_dialog = { class = "([Tt]hunar)", title = "negative:.*[Tt]hunar.*" }

rule(thunar_dialog, { float = true, center = true })

rule({ title = "^(ROG Control)$" }, { center = true })

rule({ class = "^(pavucontrol|org.pulseaudio.pavucontrol|com.saivert.pwvucontrol)$" }, { center = true })

rule({ class = "^([Ww]hatsapp-for-linux|ZapZap|com.rtosta.zapzap)$" }, { center = true })

rule({ title = "^(Picture-in-Picture)$" }, { move = "72% 7%" })

-- ============================================
-- MISC FLOAT RULES
-- ============================================

apply_to_tag("wallpaper", { float = true, size = "70% 70%" })

apply_to_tag("settings", { float = true, size = "70% 70%" })

apply_to_tag("viewer", { float = true })

rule({ class = "([Zz]oom|onedriver|onedriver-launcher)$" }, { float = true })

rule({ class = "(org.gnome.Calculator)", title = "Calculator" }, { float = true })

rule({ class = "^(mpv|com.github.rafostar.Clapper)$" }, { float = true })

rule({ class = "^([Qq]alculate-gtk)$" }, { float = true })

rule({ title = "^(Picture-in-Picture)$" }, { float = true, pin = true, keep_aspect_ratio = true })

-- ============================================
-- DIALOGUES
-- ============================================

rule({ title = "^(Authentication Required)$" }, { float = true, center = true })

rule({ class = "(codium|codium-url-handler|VSCodium)", title = "negative:.*codium.*|.*VSCodium.*" }, { float = true })

rule({ class = "^(com.heroicgameslauncher.hgl)$", title = "negative:Heroic Games Launcher" }, { float = true })

rule({ class = "^([Ss]team)$", title = "negative:^([Ss]team)$" }, { float = true })

rule({ title = "^(Add Folder to Workspace)$" }, { float = true, center = true, size = "70% 60%" })

rule({ title = "^(Save As)$" }, { float = true, center = true, size = "70% 60%" })

rule({ initial_title = "Open Files" }, { float = true, size = "70% 60%" })

-- ============================================
-- OPACITY
-- ============================================

apply_to_tag("terminal", { opacity = "0.9 1.0" })

rule({ class = "^neovide$" }, { opacity = "0.9 1.0" })

apply_to_tag("multimedia", { opacity = "0.9 1.0" })

-- ============================================
-- SIZE
-- ============================================

rule({ class = "^([Ww]hatsapp-for-linux|ZapZap|com.rtosta.zapzap)$" }, { size = "60% 70%" })

-- ============================================
-- BLUR & FULLSCREEN
-- ============================================

apply_to_tag("games", { no_blur = true, fullscreen = true })

-- ============================================
-- FOCUS
-- ============================================

rule({ class = "^(jetbrains-.*)" }, { focus_on_activate = false })

rule({ title = "^(wind.*)$" }, { focus_on_activate = false })

-- ============================================
-- SPECIAL WORKSPACES
-- ============================================

rule({ class = "^(org.signal.Signal)$" }, { workspace = "special:signal" })

rule({ class = "^(org.keepassxc.KeePassXC)$" }, { workspace = "special:keepassxc" })

rule({ class = "^.*phanpy.*$" }, { workspace = "special:phanpy", float = true })

rule({ initial_title = "^(Writing.*)$" }, { fullscreen = true })
