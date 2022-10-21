from libqtile import widget
from libqtile.command import lazy
from .theme import colors
from qtile_extras import widget

# Get the icons at https://www.nerdfonts.com/cheat-sheet (you need a Nerd Font)


def base(fg='text', bg='dark'):
    return {
        'foreground': colors[fg],
        'background': colors[bg]
    }


def separator():
    return widget.Sep(**base(), linewidth=0, padding=5)


def icon(fg='text', bg='dark', fontsize=16, text="?"):
    return widget.TextBox(
        **base(fg, bg),
        fontsize=fontsize,
        text=text,
        padding=3
    )


def powerline(fg="light", bg="dark"):
    return widget.TextBox(
        **base(fg, bg),
        text="",  # Icon: nf-oct-triangle_left
        fontsize=37,
        padding=-2.5
    )


def powerline_rounded(fg="light", bg="dark"):
    return widget.TextBox(
        **base(fg, bg),
        text="",  # Icon: nf-oct-triangle_left
        fontsize=26,
        padding=-0.5
    )


def powerline_right(fg="light", bg="dark"):
    return widget.TextBox(
        **base(fg, bg),
        text="",  # Icon: nf-oct-triangle_right
        fontsize=37,
        padding=-2.6
    )


def workspaces():
    return [
        separator(),
        widget.GroupBox(
            **base(fg='light'),
            font='UbuntuMono Nerd Font',
            fontsize=17,
            margin_y=3,
            margin_x=0,
            padding_y=8,
            padding_x=3,
            borderwidth=3.5,
            active=colors['active'],
            inactive=colors['inactive'],
            rounded=False,
            hide_unused='true',
            highlight_method='line',
            urgent_alert_method='block',
            urgent_border=colors['urgent'],
            this_current_screen_border=colors['focus'],
            this_screen_border=colors['grey'],
            other_current_screen_border=colors['dark'],
            other_screen_border=colors['dark'],
            disable_drag=True
        ),
        separator(),
        widget.WindowName(**base(fg='focus'), fontsize=14, padding=5),
        separator(),
    ]


primary_widgets = [
    *workspaces(),

    separator(),

    powerline_rounded('color4', 'dark'),

    icon(bg="color4", text=' '),  # Icon: nf-fa-download

    widget.CheckUpdates(
        background=colors['color4'],
        colour_have_updates=colors['text'],
        colour_no_updates=colors['text'],
        no_update_string='0',
        display_format='{updates}',
        update_interval=1800,
        custom_command='checkupdates',
    ),

    powerline('color3', 'color4'),

    # icon(bg="color3", text=' '),  # Icon: nf-fa-feed

    widget.WiFiIcon(
        **base(bg='color3'),
        padding_y=4,
        active_colour=colors['light'],
        expand_timeout=2,
    ),

    widget.Wlan(
        **base(bg='color3'),
        format=" {essid} ({percent:2.0%}) ",
        interface='wlan0',
        mouse_callbacks={'Button1': lazy.spawn('iwgtk')},

    ),

    # widget.Net(**base(bg='color3'), interface='wlan0',
    #            mouse_callbacks={'Button1': lazy.spawn('iwgtk')}),

    powerline('color2', 'color3'),

    widget.CurrentLayoutIcon(**base(bg='color2'), scale=0.65),

    widget.CurrentLayout(**base(bg='color2'), padding=5),

    powerline('color1', 'color2'),

    icon(bg="color1", fontsize=17, text=' '),  # Icon: nf-mdi-calendar_clock

    widget.Clock(**base(bg='color1'), format='[%a %d %b][%H:%M] '),

    powerline('black', 'color1'),

    widget.Mpris2(
        foreground='ffffff',
        name="spotify",
        paused_text="  : {track}",
        stop_text="  ",
        display_metadata=["xesam:title", "xesam:artist"],
        objname="org.mpris.MediaPlayer2.spotify",
        width=200,
        # max_char=25,
        scroll_interval=0.3,
    ),

    powerline_right('black', 'grey'),

    widget.Systray(background=colors['grey'], padding=5),

]

secondary_widgets = [
    *workspaces(),

    separator(),

    powerline('color1', 'dark'),

    widget.CurrentLayoutIcon(**base(bg='color1'), scale=0.65),

    widget.CurrentLayout(**base(bg='color1'), padding=5),

    powerline('color2', 'color1'),

    widget.Clock(**base(bg='color2'), format='%d/%m/%Y - %H:%M '),

    powerline('dark', 'color2'),
]

widget_defaults = {
    'font': 'UbuntuMono Nerd Font',
    'fontsize': 14,
    'padding': 1,
}
extension_defaults = widget_defaults.copy()
