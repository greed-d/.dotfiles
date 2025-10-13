#!/usr/bin/env python3
# -*- coding: utf-8 -*-


# ---------------------------------------------------------------------------------------------------------------------
# %% Imports

import argparse
import json
import os
import signal
import socket
from collections import deque
from dataclasses import dataclass
from time import perf_counter, sleep

# ---------------------------------------------------------------------------------------------------------------------
# %% Args

# Set built-in defaults (helpful for debugging)
default_N = 3
default_delay_ms = 2500 if perf_counter() < 60 else 0
default_maximize_solos = True
default_maximize_solo_on_close = True
default_collapse_solos_on_open = True
default_apply_on_move = False
default_debug_names = False
default_debug_data = False

# Define script arguments
parser = argparse.ArgumentParser(
    description="Script which makes niri behave like an auto-tiler when there are fewer than 'N' windows"
)
parser.add_argument(
    "-n",
    default=default_N,
    type=int,
    help=f"Number of windows handled with auto-tiling (default {default_N})",
)
parser.add_argument(
    "-delay",
    default=default_delay_ms,
    type=int,
    help=f"Number of milliseconds to delay before listening to niri IPC (default: {default_delay_ms})",
)
parser.add_argument(
    "-x",
    action="store_false" if default_maximize_solos else "store_true",
    help=f"Auto-maximize first window opened on a workspace (default: {default_maximize_solos})",
)
parser.add_argument(
    "-xc",
    action="store_false" if default_maximize_solo_on_close else "store_true",
    help=f"When closing windows, if one window remains, auto-maximize it (default: {default_maximize_solo_on_close})",
)
parser.add_argument(
    "-c",
    action="store_false" if default_collapse_solos_on_open else "store_true",
    help=f"Collapse solo maximized window when opening a second window (default: {default_collapse_solos_on_open})",
)
parser.add_argument(
    "-m",
    action="store_false" if default_apply_on_move else "store_true",
    help=f"Apply tiling logic to windows that are moved into other workspaces (default: {default_apply_on_move})",
)
parser.add_argument(
    "-dn",
    action="store_false" if default_debug_names else "store_true",
    help="Enable event name printing, for debugging",
)
parser.add_argument(
    "-dd",
    action="store_false" if default_debug_data else "store_true",
    help="Enable event data printing, for debugging",
)

# Get script configs
args, _ = parser.parse_known_args()
TILE_TO_N = args.n
STARTUP_DELAY_MS = args.delay
MAXIMIZE_SOLOS = args.x
MAXIMIZE_SOLOS_ON_CLOSE = args.xc
COLLAPSE_SOLOS_ON_OPEN = args.c
APPLY_TO_MOVED_WINDOWS = args.m
ENABLE_EVENT_NAME_DEBUG_PRINT = args.dn
ENABLE_EVENT_DATA_DEBUG_PRINT = args.dd


# ---------------------------------------------------------------------------------------------------------------------
# %% Data types


@dataclass
class TimeKeeper:
    t1: int = 0
    t2: int = 0

    def get_time_elapsed_ms(self) -> int:
        """Reports the time (in ms) since the last time this function was called"""
        self.t1 = self.t2
        self.t2 = round(perf_counter() * 1000)
        delta_ms = self.t2 - self.t1
        return delta_ms


@dataclass
class FocusState:
    workspace_id: int = None
    window_id: int = None

    def copy_inplace(self, other_focus_state):
        """Overwrite current data with data from another object (avoids creating new instances)"""
        self.workspace_id = other_focus_state.workspace_id
        self.window_id = other_focus_state.window_id
        return self


# ---------------------------------------------------------------------------------------------------------------------
# %% Classes


class NiriSocket:
    """Helper used to read & write json messages to a niri socket connection"""

    def __init__(self, socket_path: str, buffer_size: int = 4096):
        # Sanity check
        is_bad_path = socket_path is None or str(socket_path) == ""
        assert not is_bad_path, "Cannot connect to niri, no socket path given..."

        self._skt = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        self._skt.connect(skt_path)
        self._bufsize = buffer_size

        # Storage for
        self._msg_queue = deque([])
        self._inprog_str = None

    def _read_next(self):
        # Read from existing (buffered) messages, if any
        if len(self._msg_queue) > 0:
            next_msg = self._msg_queue.popleft()
            return json.loads(next_msg)

        while True:
            # Listen for raw (binary) string data from socket
            # -> Will return 0 bytes if connection closes
            resp_binstr = self._skt.recv(self._bufsize)
            if len(resp_binstr) == 0:
                print("DEBUG - READNEXT: No data received!")
                return {}

            # If we have an in-progress result, append the new data to it
            resp_str = resp_binstr.decode("utf-8")
            if self._inprog_str is not None:
                resp_str = "".join((self._inprog_str, resp_str))
                self._inprog_str = None

            # Stop listening if got at least 1 message
            # - Expect response to look like: "message 1\nmessage 2\nmessage 3\n"
            # - If incomplete, we'll see something not ending with '\n': "message 1\nmessa"
            msg_list = resp_str.split("\n")
            last_msg_piece = msg_list.pop()
            contains_incomplete_message = len(last_msg_piece) > 0
            self._inprog_str = last_msg_piece if contains_incomplete_message else None
            if len(msg_list) > 0:
                break

        # Sanity check, make sure we read something
        if len(msg_list) == 0:
            raise IOError("Error reading next message (empty message list)!")

        # If we have more than 1 message, return only the 'next one
        # (future calls to this function will return the queued up messages)
        out_msg_str = msg_list[0]
        if len(msg_list) > 1:
            self._msg_queue.extend(msg_list[1:])

        return json.loads(out_msg_str)

    def _send_string(self, string: str):
        """Helper used to send simple string messages (e.g. for requests)"""
        return self._skt.sendall(f'"{string}"\n'.encode("utf-8"))

    def _send_json(self, json_data: dict):
        """Helper used to send json message (e.g. for actions)"""
        json_as_str = json.dumps(json_data, indent=None, separators=(",", ":"))
        return self._skt.sendall(("".join([json_as_str, "\n"])).encode("utf-8"))

    def close(self):
        self._skt.close()

    @staticmethod
    def get_niri_socket_path():
        return os.environ.get("NIRI_SOCKET")


class NiriRequests(NiriSocket):
    """
    Helper used to make requests to niri
    See: https://yalter.github.io/niri/niri_ipc/enum.Request.html
    """

    def get_version(self):
        return self.request("Version")

    def request(self, message: str):
        self._send_string(message)

        # Listen for ok/err response
        resp_json = self._read_next()
        is_ok_resp = "Ok" in resp_json.keys()
        resp_data = resp_json["Ok" if is_ok_resp else "Err"]
        return is_ok_resp, resp_data

    def read_eventstream(self):
        is_ok, evt_resp = self.request("EventStream")
        if not is_ok:
            print("DEBUG - EventStream response:", evt_resp, sep="\n")
            raise IOError("Error requesting EventStream")

        # Read events from stream, forever
        while True:
            event_json = self._read_next()
            event_name = tuple(event_json.keys())[0]
            event_data = event_json.get(event_name, None)
            yield event_name, event_data
        return


class NiriActions(NiriSocket):
    """
    Helper used to trigger actions through the niri IPC
    See: https://yalter.github.io/niri/niri_ipc/enum.Action.html
    """

    def action(self, message: str, **kwargs):
        # Build action request
        json_data = {"Action": {message: kwargs}}
        self._send_json(json_data)

        # Listen for ok/err response
        resp_json = self._read_next()
        is_ok_resp = "Err" not in resp_json.keys()
        resp_data = resp_json if is_ok_resp else resp_json["Err"]
        return is_ok_resp, resp_data


# ---------------------------------------------------------------------------------------------------------------------
# %% Functions


def catch_sigterm(signum, frame):
    """Turn SIGTERM events into exceptions for graceful shutdown"""
    raise InterruptedError


def make_workspace_state_from_WorkspacesChanged(event_data: dict) -> dict[int, dict]:
    return {info_dict["id"]: info_dict for info_dict in event_data["workspaces"]}


def make_window_state_from_WindowsChanged(
    event_data: dict, workspace_state, output_width_lut: dict
) -> dict[int, dict]:
    state = {}
    for info_dict in event_data["windows"]:
        win_id = info_dict["id"]
        win_aug_data = get_additional_window_data(
            info_dict, workspace_state, output_width_lut
        )
        info_dict.update(win_aug_data)
        state[win_id] = info_dict
    return state


def get_windows_by_conditions(
    window_state: dict[int, dict], **conditions
) -> dict[int, dict]:
    """Function used to filter window state data according to key-value conditions"""
    meets_conditions = lambda data: all(data[k] == v for k, v in conditions.items())
    return {
        winid: windata
        for winid, windata in window_state.items()
        if meets_conditions(windata)
    }


def get_additional_window_data(
    window_data: dict,
    workspace_state: dict,
    output_width_lut: dict,
    max_width_threshold: float = 0.8,
) -> dict:
    """Helper used to generate addition windowing data (particularly 'is_maximized' flag)"""
    # Set up augmentation data
    win_pos = window_data["layout"]["pos_in_scrolling_layout"]
    win_col, win_row = win_pos if win_pos is not None else (None, None)
    augment_dict = {
        "col_idx": win_col,
        "row_idx": win_row,
        "is_maximized": False,
    }

    # Try to figure out if window is maximized
    win_wspace_id = window_data["workspace_id"]
    win_output = workspace_state.get(win_wspace_id, {}).get("output", None)
    output_width = output_width_lut.get(win_output, None)
    if output_width is not None:
        win_width = window_data["layout"]["window_size"][0]
        augment_dict["is_maximized"] = (win_width / output_width) > max_width_threshold

    return augment_dict


def toggle_window_maximization(target_window_id: int, focused_window_id: int):
    """Helper used to toggle the maximization state of a window, without messing with current focused window"""

    if target_window_id == focused_window_id:
        niri_action.action("MaximizeColumn")
    else:
        niri_action.action("FocusWindow", id=target_window_id)
        niri_action.action("MaximizeColumn")
        niri_action.action("FocusWindow", id=focused_window_id)

    return


def maximize_window(
    window_state: dict, focus_state: FocusState, target_window_id: int
) -> bool:
    """
    Helper used to maximize a window if it's not already maximized.
    This function assumes window state includes 'is_maximized' flag!
    Returns True if the window needed maximization, false otherwise
    """

    solo_win_data = window_state[target_window_id]
    need_maximization = not solo_win_data["is_maximized"]
    if need_maximization:
        solo_id = solo_win_data["id"]
        toggle_window_maximization(solo_id, focus_state.window_id)
        win_state[solo_id]["is_maximized"] = True

    return need_maximization


def collapse_window(
    window_state: dict, focus_state: FocusState, target_window_id: int
) -> bool:
    """
    Helperused to collapse a maximized window. This function assumes
    that the window state includes 'is_maximized' flag!
    Returns: True if window needed collapse, false otherwise
    """

    solo_win_data = window_state[target_window_id]
    need_collapse = solo_win_data["is_maximized"]
    if need_collapse:
        solo_id = solo_win_data["id"]
        toggle_window_maximization(solo_id, focus_state.window_id)
        win_state[solo_id]["is_maximized"] = False

    return need_collapse


# ---------------------------------------------------------------------------------------------------------------------
# %% Setup

# Handle startup delay (prevent listening to niri during potentially busy startup)
if STARTUP_DELAY_MS > 0:
    sleep(STARTUP_DELAY_MS / 1000)

# Get niri socket from env
skt_path = NiriSocket.get_niri_socket_path()
if skt_path is None or skt_path == "":
    print("Couldn't find niri socket! (from env: NIRI_SOCKET)")
    quit()

# Create separate read/write sockets, since eventstream reader cannot issue actions
niri_reader = NiriRequests(skt_path)
niri_action = NiriActions(skt_path)

# Sanity check. Make sure we have the right version
is_version_ok, version_resp = niri_reader.request("Version")
expected_version, actual_version = (
    "25.08 (af4b5f9)",
    version_resp.get("Version", "unknown"),
)
if actual_version != expected_version:
    print(
        "",
        "WARNING - Unexpected niri version!",
        f"expected: {expected_version}",
        f"  actual: {actual_version}",
        "Errors may occur...",
        sep="\n",
    )


# ---------------------------------------------------------------------------------------------------------------------
# %% *** IPC listening loop ***

# Get monitor into
is_outputs_ok, outputs_resp = niri_reader.request("Outputs")
if not is_outputs_ok:
    print("Error requesting info about monitors", outputs_resp, sep="\n")
    quit()
output_full_info = {
    out_key: out_dict["logical"]
    for out_key, out_dict in outputs_resp["Outputs"].items()
}
output_width_lut = {
    out_key: out_info["width"] for out_key, out_info in output_full_info.items()
}

# Initialize state tracking
prev_focus_state = FocusState()
focus_state = FocusState()
timekeeper = TimeKeeper()
win_state = None
wspace_state = None

# Main listening loop
signal.signal(signal.SIGTERM, catch_sigterm)
try:
    init_time = timekeeper.get_time_elapsed_ms()
    for evt_name, evt_data in niri_reader.read_eventstream():
        # For debugging printouts, add spaces between events that don't occur together
        time_elapsed_ms = timekeeper.get_time_elapsed_ms()
        if ENABLE_EVENT_NAME_DEBUG_PRINT or ENABLE_EVENT_DATA_DEBUG_PRINT:
            if time_elapsed_ms > 250:
                print(
                    "",
                    f"Time elapsed (sec): {(timekeeper.t2 - init_time) // 1000}",
                    sep="\n",
                )
            if ENABLE_EVENT_NAME_DEBUG_PRINT:
                print(evt_name)
            if ENABLE_EVENT_DATA_DEBUG_PRINT:
                print(evt_data)

        # Handle all IPC stream events
        prev_focus_state.copy_inplace(focus_state)
        closed_window_data, newest_window_data = None, None
        if evt_name == "WorkspacesChanged":
            # Replace existing workspace info
            wspace_state = make_workspace_state_from_WorkspacesChanged(evt_data)
            for item in wspace_state.values():
                if item["is_focused"]:
                    focus_state.workspace_id = item["id"]

        elif evt_name == "WorkspaceUrgencyChanged":
            # Update our existing workspace state
            evt_wspace_id = evt_data["id"]
            wspace_state[evt_wspace_id]["is_urgent"] = evt_data["urgent"]

        elif evt_name == "WorkspaceActivated":
            # Record new focused workspace (ignore 'active' state, we don't use it)
            if evt_data["focused"]:
                focus_state.workspace_id = evt_data["id"]
                wspace_state[prev_focus_state.workspace_id]["is_focused"] = False
            pass

        elif evt_name == "WorkspaceActiveWindowChanged":
            # Not using this...?
            # print(
            #     f"DEBUG EVENT - *{evt_name}*  |  Not using...?",
            #     "  Data:",
            #     f"    active_window_id: {evt_data['active_window_id']}",
            #     f"        workspace_id: {evt_data['workspace_id']}",
            #     sep="\n",
            # )
            pass

        elif evt_name == "WindowsChanged":
            # Replace existing window state
            win_state = make_window_state_from_WindowsChanged(
                evt_data, wspace_state, output_width_lut
            )
            for item in win_state.values():
                if item["is_focused"]:
                    focus_state.window_id = item["id"]

        elif evt_name == "WindowOpenedOrChanged":
            # Decide if we have a new/moved window
            evt_win_id = evt_data["window"]["id"]
            evt_win_wspace_id = evt_data["window"]["workspace_id"]
            evt_is_new_window = evt_win_id not in win_state.keys()
            evt_is_moved_window, prev_win_wspace_id = False, None
            if not evt_is_new_window:
                prev_win_wspace_id = win_state[evt_win_id]["workspace_id"]
                evt_is_moved_window = prev_win_wspace_id != evt_win_wspace_id

            # Update focus, if needed
            if evt_data["window"]["is_focused"]:
                focus_state.window_id = evt_win_id

            # Replace existing window state for the target window
            win_aug_data = get_additional_window_data(
                evt_data["window"], wspace_state, output_width_lut
            )
            win_state[evt_win_id] = {**evt_data["window"], **win_aug_data}
            need_check_rearrange = evt_is_new_window or (
                evt_is_moved_window and APPLY_TO_MOVED_WINDOWS
            )
            newest_window_data = win_state[evt_win_id] if need_check_rearrange else None

        elif evt_name == "WindowClosed":
            # Delete closed window state data & remove from windows-per-workspace mapping
            evt_win_id = evt_data["id"]
            closed_window_data = win_state.pop(evt_win_id)

        elif evt_name == "WindowFocusChanged":
            # Update existing focus state
            focus_state.window_id = evt_data["id"]

        elif evt_name == "WindowUrgencyChanged":
            # Update our existing window state
            evt_win_id = evt_data["id"]
            win_state[evt_win_id]["is_urgent"] = evt_data["urgent"]

        elif evt_name == "WindowLayoutsChanged":
            # Replace existing window layout data
            for evt_win_id, evt_new_layout in evt_data["changes"]:
                win_state[evt_win_id]["layout"] = evt_new_layout
                win_aug_data = get_additional_window_data(
                    win_state[evt_win_id], wspace_state, output_width_lut
                )
                win_state[evt_win_id].update(win_aug_data)
            pass

        elif evt_name == "KeyboardLayoutsChanged":
            # Not doing anything with keyboard...
            pass

        elif evt_name == "KeyboardLayoutSwitched":
            # Not doing anything with keyboard...
            pass

        elif evt_name == "OverviewOpenedOrClosed":
            # Not doing anything with overview...
            evt_is_overview_open = evt_data["is_open"]

        elif evt_name == "ConfigLoaded":
            # Not doing anything with config...
            pass

        else:
            print("Unknown event:", evt_name)

        # Handle max-on-close
        if closed_window_data is not None:
            if MAXIMIZE_SOLOS_ON_CLOSE:
                curr_wspace_id = closed_window_data["workspace_id"]
                curr_wins = get_windows_by_conditions(
                    win_state, workspace_id=curr_wspace_id, is_floating=False
                )
                if len(curr_wins) == 1:
                    solo_id = tuple(curr_wins.keys())[0]
                    maximize_window(win_state, focus_state, solo_id)
                pass

        # Handle window-creation behaviors
        if newest_window_data is not None:
            # Ignore newly created maximized or floating windows
            # -> Assume opened maximized windows are done by user window rules (don't want to interfere)
            # -> Tiling logic shouldn't apply to floating windows
            if newest_window_data["is_maximized"] or newest_window_data["is_floating"]:
                continue

            # Don't bother trying to re-arrange/tile if we already have more than 'N' windows
            curr_wspace_id = newest_window_data["workspace_id"]
            curr_tile_wins = get_windows_by_conditions(
                win_state, workspace_id=curr_wspace_id, is_floating=False
            )
            num_tile_wins = len(curr_tile_wins)
            if num_tile_wins == 0 or num_tile_wins > TILE_TO_N:
                continue

            # Auto-maximize solo windows, if needed
            if MAXIMIZE_SOLOS and num_tile_wins == 1:
                solo_id = tuple(curr_tile_wins.keys())[0]
                maximize_window(win_state, focus_state, solo_id)

            # Collapse maximized windows, if needed
            curr_max_wins: dict = get_windows_by_conditions(
                curr_tile_wins, is_maximized=True
            )
            num_max_wins = len(curr_max_wins)
            if COLLAPSE_SOLOS_ON_OPEN and num_max_wins == 1 and num_tile_wins == 2:
                solo_max_id = tuple(curr_max_wins.keys())[0]
                collapse_window(win_state, focus_state, solo_max_id)
                num_max_wins -= 1

            # Apply tiling if needed
            is_zero_max_windows = num_max_wins == 0
            if is_zero_max_windows and (2 < num_tile_wins <= TILE_TO_N):
                is_new_win_onscreen = newest_window_data["col_idx"] == 2
                consume_action = (
                    "ConsumeOrExpelWindowRight"
                    if is_new_win_onscreen
                    else "ConsumeOrExpelWindowLeft"
                )
                niri_action.action(consume_action, id=newest_window_data["id"])

            pass

except (KeyboardInterrupt, InterruptedError):
    pass

finally:
    niri_action.close()
    niri_reader.close()
    print("", f"({os.path.basename(__file__)}) - Closed niri IPC connection", sep="\n")
