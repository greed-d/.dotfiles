# Timer

Timer is a countdown timer with three UI surfaces — a bar widget, a panel, and
a desktop widget — that are all thin clients of one headless service. They
share a single countdown through Noctalia's plugin state, so starting, pausing,
or resetting from any surface updates them all live.

## Plugin

| Field | Value |
| --- | --- |
| ID | `noctalia/timer` |
| Entries | Service: `timer`; bar widget: `bar`; panel: `panel`; desktop widget: `desktop` |

## Usage

### Bar Widget and Panel

The headless `timer` service owns countdown logic and state. The `bar` widget
and `panel` communicate with the service through shared plugin state.

Add the `bar` bar widget to your bar. It displays an hourglass icon when idle,
or the formatted countdown when running. Click the widget to open the timer
panel for duration input and controls. When the timer completes, clicking the
bar widget resets it.

On vertical bars, the widget shows an hourglass with the time as a tooltip.
On horizontal bars, the widget shows the hourglass and countdown side by side,
with an option to hide the countdown when idle.

You can also open the timer panel over IPC:

```sh
noctalia msg panel-toggle noctalia/timer:panel
```

### Desktop Widget

Add the `desktop` desktop widget from Noctalia's desktop-widget editor. Because
desktop widgets cannot take keyboard focus, it sets the duration with
keyboard-free `-1m`/`+1m`/`+5m` buttons instead of typed input, then starts,
pauses, and resets the countdown.

The desktop widget owns no timer logic: it drives the same shared countdown as
the bar widget and panel through the `timer` service, so all three stay in sync,
and the service sends a notification when the countdown reaches zero.

## Settings

### Bar Widget

| Setting | Type | Default | Description |
| --- | --- | --- | --- |
| `show_idle_on_horizontal` | `bool` | `true` | Shows or hides the countdown on horizontal bars when idle. |

### Desktop Widget

| Setting | Type | Default | Description |
| --- | --- | --- | --- |
| `color` | `color` | `primary` | Accent color for the time and progress bar. |
| `show_progress` | `bool` | `true` | Shows or hides the progress bar. |

## Notes

This plugin is a reference implementation for `[[desktop_widget]]` entries,
`[[widget]]` bar widget entries, and Noctalia's declarative `ui.*` widget tree.
