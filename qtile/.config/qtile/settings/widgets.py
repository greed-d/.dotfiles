from libqtile import widget
from libqtile.command import lazy
from libqtile.bar import CALCULATED

from qtile_extras import widget
from qtile_extras.widget import decorations

from .theme import colors


# Get the icons at https://www.nerdfonts.com/cheat-sheet (you need a Nerd Font)


def base(fg='text', bg='dark'):
    return {
        'foreground': colors[fg],
        'background': colors[bg]
    }


def separator():
    return widget.Sep(**base(), linewidth=0, padding=5)


def powerline(fg="light", bg="dark"):
    return widget.TextBox(
        **base(fg, bg),
    )


decoration_updates = {
    "decorations": [
        decorations.RectDecoration(
            use_widget_background=True,
            filled=True,
            group=True,
            radius=[10, 0, 0, 10]

        ),
        decorations.PowerLineDecoration(
            path="forward_slash",
        )

    ]
}

decoration_slash = {
    "decorations": [
        decorations.PowerLineDecoration(
            path="forward_slash"
        )
    ]
}

decoration_spotify = {
    "decorations": [
        decorations.PowerLineDecoration(
            path="rounded_left"

        )
    ]
}

decoration_systray = {

    "decorations": [
        decorations.RectDecoration(
            use_widget_background=False,
            filled=True,
            group=True,
            radius=[0, 10, 10, 0]

        ),

    ]
}


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

        widget.Spacer(**base(bg='dark')),
        widget.WindowName(**base(fg='focus'), fontsize=16, padding=5,
                          format='{name}', max_chars=60, width=CALCULATED),
        widget.Spacer(**base(bg='dark')),

        separator(),
    ]


primary_widgets = [
    *workspaces(),

    separator(),

    widget.CheckUpdates(
        **decoration_updates,
        background=colors['color4'],
        colour_have_updates=colors['text'],
        colour_no_updates=colors['text'],
        no_update_string='0',
        display_format='{updates}',
        update_interval=1800,
        custom_command='checkupdates',
        fmt='   {}'
    ),

    widget.WiFiIcon(
        **base(bg='color3'),
        padding_y=4,
        active_colour=colors['light'],
        # expand_timeout=2,
        show_ssid=True,
        mouse_callbacks={'Button1': lazy.spawn(
            'nm-applet')},
        **decoration_slash
    ),

    widget.CurrentLayoutIcon(**base(bg='color2'), scale=0.65),

    widget.CurrentLayout(**base(bg='color2'), padding=5, **decoration_slash),

    widget.Clock(**base(bg='color1'),

                 format='[%a %d %b]-[%H:%M]',
                 **decoration_slash,
                 fmt=' {}'
                 ),


    widget.Mpris2(
        **decoration_spotify,
        foreground='ffffff',
        name="spotify",
        paused_text=" : {track}",
        stop_text="  ",
        display_metadata=["xesam:title", "xesam:artist"],
        objname="org.mpris.MediaPlayer2.spotify",
        width=175,
        scroll_interval=0.3,
    ),

    widget.Systray(background=colors['grey'], padding=5),
]

secondary_widgets = [
    *workspaces(),

    separator(),

    # powerline('color1', 'dark'),

    widget.CurrentLayoutIcon(**base(bg='color1'), scale=0.65),

    widget.CurrentLayout(**base(bg='color1'), padding=5, **decoration_slash),

    # powerline('color2', 'color1'),

    widget.Clock(**base(bg='color2'),
                 format='[%d/%m/%Y] - [%H:%M]', **decoration_slash),

    powerline('dark', 'color2'),
]

widget_defaults = {
    'font': 'UbuntuMono Nerd Font',
    'fontsize': 14,
    'padding': 1,
}
extension_defaults = widget_defaults.copy()
