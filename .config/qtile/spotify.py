from subprocess import CompletedProcess, run
from typing import List

from libqtile.group import _Group
from libqtile.config import Screen

from libqtile.widget import base

SPOTIFY = "Spotify"


class Spotify(base.ThreadPoolText):
    """
    A widget to interact with spotify via dbus.
    """

    defaults = [
        ("play_icon", "", "icon to display when playing music"),
        ("pause_icon", "", "icon to display when music paused"),
        ("update_interval", 0.5, "polling rate in seconds"),
        ("format", "{icon} {artist}:{album} - {track}",
         "Spotify display format"),
    ]

    def __init__(self, **config) -> None:
        base.ThreadPoolText.__init__(self, text="", **config)
        self.add_defaults(Spotify.defaults)
        self.add_callbacks(
            {
                "Button3": self.toggle_between_groups,
                "Button1": self.toggle_music,
            }
        )

    def _is_proc_running(self, proc_name: str) -> bool:
        # create regex pattern to search for to avoid similar named processes
        pattern = proc_name + "$"

        # pgrep will return a string of pids for matching processes
        proc_out = run(["pgrep", "-fli", pattern], capture_output=True).stdout.decode(
            "utf-8"
        )

        # empty string means nothing started
        is_running = proc_out != ""

        return is_running

    def toggle_between_groups(self) -> None:
        """
        remember which group you were on before you switched to spotify
        so you can toggle between the 2 groups
        """
        current_screen: Screen = self.qtile.current_screen
        current_group_info = self.qtile.current_group.info()
        windows = current_group_info["windows"]
        if SPOTIFY in windows:
            # go to previous group
            current_screen.previous_group.cmd_toscreen()
        else:
            self.go_to_spotify()

    def go_to_spotify(self) -> None:
        """
        Switch to whichever group has the current spotify instance
        if none exists then we will spawn an instance on the current group
        """
        # spawn spotify if not already running
        if not self._is_proc_running("spotify"):
            self.qtile.cmd_spawn("spotify", shell=True)
            return

        all_groups: List[_Group] = self.qtile.groups
        # we need to find the group that has spotify in it
        for group in all_groups:
            info = group.info()
            # get a list of windows for the group.  We look for 'Spotify here'
            windows = info["windows"]
            name = group.name
            if SPOTIFY in windows:
                # switch to 'name' group
                spotify_group = self.qtile.groups_map[name]
                spotify_group.cmd_toscreen()
                break

    def poll(self) -> str:
        """Poll content for the text box"""
        vars = {}
        if self.playing:
            vars["icon"] = self.play_icon
        else:
            vars["icon"] = self.pause_icon

        vars["artist"] = self.artist
        vars["track"] = self.song_title
        vars["album"] = self.album

        return self.format.format(**vars)

    def toggle_music(self) -> None:
        run(
            "dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.PlayPause",
            shell=True,
        )

    def get_proc_output(self, proc: CompletedProcess) -> str:
        if proc.stderr.decode("utf-8") != "":
            return (
                ""
                if "org.mpris.MediaPlayer2.spotify" in proc.stderr.decode("utf-8")
                else proc.stderr.decode("utf-8")
            )

        output = proc.stdout.decode("utf-8").rstrip()
        return output

    @property
    def _meta(self) -> str:
        proc = run(
            "dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.freedesktop.DBus.Properties.Get string:'org.mpris.MediaPlayer2.Player' string:'Metadata'",
            shell=True,
            capture_output=True,
        )

        output: str = proc.stdout.decode("utf-8").replace("'", "ʼ").rstrip()
        return "" if ("org.mpris.MediaPlayer2.spotify" in output) else output

    @property
    def artist(self) -> str:
        proc: CompletedProcess = run(
            "dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.freedesktop.DBus.Properties.Get string:'org.mpris.MediaPlayer2.Player' string:'Metadata' | grep -m1 'xesam:artist' -b2 | tail -n 1 | grep -o '\".*\"' | sed 's/\"//g' | sed -e 's/&/and/g'",
            shell=True,
            capture_output=True,
        )

        output = self.get_proc_output(proc)
        return output

    @property
    def song_title(self) -> str:
        proc: CompletedProcess = run(
            f"echo '{self._meta}' | grep -m1 'xesam:title' -b1 | tail -n1 | grep -o '\".*\"' | sed 's/\"//g' | sed -e 's/&/and/g'",
            shell=True,
            capture_output=True,
        )

        output = self.get_proc_output(proc)
        return output

    @property
    def album(self) -> str:
        proc = run(
            f"echo '{self._meta}' | grep -m1 'xesam:album' -b1 | tail -n1 | grep -o '\".*\"' | sed 's/\"//g' | sed -e 's/&/and/g'",
            shell=True,
            capture_output=True,
        )

        output: str = self.get_proc_output(proc)
        return output

    @property
    def playing(self) -> bool:
        play = run(
            "dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.freedesktop.DBus.Properties.Get string:'org.mpris.MediaPlayer2.Player' string:'PlaybackStatus' | grep -o Playing",
            shell=True,
            capture_output=True,
        ).stdout.decode("utf-8")

        is_running = play != ""
        return is_running
