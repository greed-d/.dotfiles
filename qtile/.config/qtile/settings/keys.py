from libqtile.config import Key
from libqtile.command import lazy
from libqtile.core import manager
from libqtile import qtile


mod = "mod4"

keys = [Key(key[0], key[1], *key[2:]) for key in [
    # ------------ Window Configs ------------

    # Switch between windows in current stack pane
    ([mod], "j", lazy.layout.down()),
    ([mod], "k", lazy.layout.up()),
    ([mod], "h", lazy.layout.left()),
    ([mod], "l", lazy.layout.right()),

    # Change window sizes (MonadTall)
    ([mod, "shift"], "l", lazy.layout.grow()),
    ([mod, "shift"], "h", lazy.layout.shrink()),

    # Toggle floating
    ([mod, "shift"], "f", lazy.window.toggle_floating()),

    # Move windows up or down in current stack
    ([mod, "shift"], "j", lazy.layout.shuffle_down()),
    ([mod, "shift"], "k", lazy.layout.shuffle_up()),

    # Toggle between different layouts as defined below
    ([mod], "Tab", lazy.next_layout()),
    ([mod, "shift"], "Tab", lazy.prev_layout()),

    # Kill window
    ([mod], "c", lazy.window.kill()),

    # Switch focus of monitors
    ([mod], "period", lazy.next_screen()),
    ([mod], "comma", lazy.prev_screen()),

    # Restart Qtile
    ([mod, "control"], "r", lazy.restart()),

    ([mod, "control"], "q", lazy.shutdown()),

    ([mod, "shift"], "q", lazy.spawn("alacritty -e sudo shutdown now")),


    # ([mod], "r", lazy.spawncmd()),

    # ------------ App Configs ------------

    # Menu
    ([mod], "space", lazy.spawn("rofi -show drun")),

    # BetterLockscreen
    ([mod, "control"], "l", lazy.spawn(
        "betterlockscreen -l")),

    # Window Nav
    ([mod, "shift"], "space", lazy.spawn("rofi -show window")),

    # Kdocker
    (["control", "shift"], "k", lazy.spawn("kdocker")),

    # Browser
    ([mod], "b", lazy.spawn("firefox")),

    # Discord
    ([mod], "d", lazy.spawn("armcord")),

    # File Explorer
    ([mod], "e", lazy.spawn("thunar")),

    # Terminal
    ([mod], "Return", lazy.spawn("alacritty")),

    # Nvim
    ([mod], "v", lazy.spawn("alacritty -e nvim")),

    # Redshift
    ([mod], "r", lazy.spawn("redshift -O 2400")),
    ([mod, "shift"], "r", lazy.spawn("redshift -x")),

    # Screenshot
    ([mod], "s", lazy.spawn("/home/greed/.config/qtile/scripts/scrotshot.sh", shell=True)),
    ([mod, "shift"], "s", lazy.spawn(
        "/home/greed/.config/qtile/scripts/scrot_select.sh")),

    # mute mic
    ([mod], "m", lazy.spawn("/home/greed/.config/qtile/scripts/mic_toggle.sh")),

    # Spotify
    ([mod, "shift"], "m", lazy.spawn("spotify")),


    # ------------ Hardware Configs ------------

    # Volume
    ([], "XF86AudioLowerVolume", lazy.spawn(
        "pactl set-sink-volume @DEFAULT_SINK@ -5%"
    )),
    ([], "XF86AudioRaiseVolume", lazy.spawn(
        "pactl set-sink-volume @DEFAULT_SINK@ +5%"
    )),
    ([], "XF86AudioMute", lazy.spawn(
        "pactl set-sink-mute @DEFAULT_SINK@ toggle"
    )),

    # Brightness
    ([], "XF86MonBrightnessUp", lazy.spawn("brightnessctl set +10%")),
    ([], "XF86MonBrightnessDown", lazy.spawn("brightnessctl set 10%-")),
]]
