# Bongo Cat

Bongo Cat adds a bar widget that idles, blinks, sleeps, and slaps its paws when
you type or when audio beats are detected.

## Plugin

| Field | Value |
| --- | --- |
| ID | `noctalia/bongocat` |
| Entry | Bar widget: `cat` |

## Usage

Add the `cat` widget to a bar from Noctalia's widget picker. Click the cat to
pause or resume it.

Keyboard reactivity is disabled until `input_devices` is configured. Use stable
paths from `/dev/input/by-id/` or `/dev/input/by-path/` when possible because
`/dev/input/eventN` names can change after device or kernel updates. Some
devices, including Bluetooth keyboards, may not expose a stable path; using
their `/dev/input/eventN` path is supported.

Audio reactivity is controlled separately with `audio_spectrum`. When enabled,
the widget can tap to the beat, flash rave colors on beat, and optionally ignore
audio unless MPRIS reports media playback.

## Requirements

Keyboard reactivity requires `evtest` and permission to read the selected input
devices. On many systems that means adding your user to the `input` group and
logging in again.

Audio reactivity uses Noctalia's PipeWire spectrum callback.

## Settings

| Setting | Type | Default | Description |
| --- | --- | --- | --- |
| `input_devices` | `string_list` | `[]` | Input device paths or globs to read with `evtest`. |
| `executable_path` | `file` | `evtest` | Path to the input reader executable. |
| `audio_spectrum` | `bool` | `false` | Enables PipeWire audio spectrum events. |
| `tappy_mode` | `bool` | `false` | Makes the cat tap its paws to detected beats. |
| `rave_mode` | `bool` | `false` | Flashes cat colors on detected beats. |
| `use_mpris_filter` | `bool` | `false` | Reacts only while an MPRIS player is playing. |

## IPC

The widget accepts simple runtime controls:

```sh
noctalia msg plugin noctalia/bongocat:cat focused pause
noctalia msg plugin noctalia/bongocat:cat focused resume
noctalia msg plugin noctalia/bongocat:cat focused toggle
```

## CREDITS

- **[@StrayRogue](https://x.com/StrayRogue)** — Creator of the original Bongo Cat artwork used by the bongocat widget
