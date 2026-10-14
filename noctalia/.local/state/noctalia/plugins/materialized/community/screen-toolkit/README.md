# Screen Toolkit

A Noctalia v5 plugin for color picking, OCR, QR/barcode scanning, palette
extraction, Google Lens search, annotation, pixel measuring, screen recording,
and image sharing.

## Attribution

Screen Toolkit was originally created for Noctalia v4 by the author(s) of the
[legacy screen-toolkit plugin](https://github.com/noctalia-dev/legacy-v4-plugins/tree/main/screen-toolkit).
This repository is an independent Noctalia v5 remake/port by `alexander`; it is
not the original implementation.

## Plugin

| Field | Value |
| --- | --- |
| ID | `alexander/screen-toolkit` |
| Entries | Bar widget: `widget`; control-center shortcut: `toggle`; panels: `panel` (standard tools), `panel-legacy` (legacy layout), `result` (result view); service: `service` |

## Requirements

Install the tools used by the features you want on `PATH`. Missing tools are
reported when that feature is started. Screenshots, region selection, and
annotation run through the shell's own screenshot stack (no extra binaries);
only pixel processing and recording need external tools.

- **`slurp`** — region crosshair for region recording; invisible click waiter for Annotate Window
- **`hyprpicker`** — pixel color picking
- **`tesseract`** — OCR engine (plus your language packs, e.g. `tesseract-data-eng`)
- **`imagemagick`** — image processing
- **`zbar`** — QR / barcode scanning (`zbarimg`)
- **`curl`** + **`jq`** — image uploads (uguu.se / x02.me) and Google Lens
- **`ffmpeg`** + **`ffprobe`** — recording / GIF conversion and thumbnail generation
- **`bc`** — GIF duration and frame-rate calculations
- **`stat`** — recording file size
- **`pkill`** — stopping active recording backends
- **`xdg-open`** — opening URLs, OCR search results, and shared-link targets
- **`mpv`** — open recording preview in legacy mode subpanel
- **`pactl`** — resolve the default audio source for single-source wf-recorder / wl-screenrec recording

Recording requires at least one backend:

- **`gpu-screen-recorder`** — recommended for fullscreen recording, especially on NVIDIA (NVENC)
- **`wl-screenrec`** — preferred for region recording and microphone audio
- **`wf-recorder`** — fallback recorder for region and fullscreen capture

Optional:

- **`translate-shell`** (`trans`) — OCR translation
- **`hyprctl`** — window geometry and hover highlight for Annotate Window (Hyprland; the highlight needs a Lua-dispatch build)
- **`niri`** — Annotate Window on Niri captures the focused window

Screenshots and annotation use the shell's own screenshot stack
(`screenshot-region`, `screenshot-fullscreen`, `annotate`), so captures land
in the shell's screenshot directory with its filename pattern. `Annotate
Window` hovers to aim — everything dims except the window under the cursor —
then the click captures that window. On Niri it captures the focused window
directly.

## Usage

Add the `Screen Toolkit` widget to a bar, and/or the shortcut tile in
Settings → Control Center shortcuts. Left-click either one opens the main panel
(or stops a recording); right-clicking the bar widget quick-picks a color. While
a recording is active, the widget and shortcut show a pulsing red dot.

The main panel has two layouts, selected by the `panel-mode` setting (default:
**Standard**):

- **Standard** — a dense grid grouped into tinted sections (`panel`, 380×260).
- **Legacy** — recreates the Noctalia-v4 layout (`panel-legacy`, 380×260).

### Legacy mode
Legacy mode recreates the original Noctalia v4 screen-toolkit layout:

> **Note:** The features below are exclusive to the **Legacy** layout.

- Dedicated Markup and Recording subpanels.
- Preview and one-click access to the most recent screenshot or recording.
- Quick microphone and system audio toggles in the `Record` subpanel.

The widget and shortcut open the panel matching the `panel-mode` setting; the
panel footnote under Settings → Plugins shows placement/position options.

Toggle the tools panel (opens the panel matching `panel-mode`):

```sh
noctalia msg plugin alexander/screen-toolkit:service all toggle
```

For example, bind it to `SUPER+P` in Hyprland:

```ini
bind = SUPER, P, exec, noctalia msg plugin alexander/screen-toolkit:service all toggle
```

Open the standard tools panel:

```sh
noctalia msg panel-toggle alexander/screen-toolkit:panel
```

Open the legacy tools panel (the 4×2 grid with subpanels):

```sh
noctalia msg panel-toggle alexander/screen-toolkit:panel-legacy
```

Open the result panel (shows the last capture/recording output):

```sh
noctalia msg panel-toggle alexander/screen-toolkit:result
```

The tools panel contains the capture actions. When a capture tool finishes, a
**result panel** opens with the output and its actions; close it to return to
the tools panel.

Region tools (OCR, QR, Palette, Lens, Measure, Markup) use the shell's
interactive region overlay — drag to select a region, then release. Region
recording draws a `slurp` crosshair instead, to get a geometry for the
external recorder. Recording starts immediately and the bar widget shows the
pulsing dot; click the dot, the widget, the shortcut, or the panel's **Stop**
button to end it. Unless "Skip Save Confirmation" is on, the panel then
offers **Save MP4**, **Save GIF**, **Copy**, and **Discard**.

The `hide-cursor` setting excludes the cursor from **recordings** (default:
hidden). Screenshots follow the shell's own screenshot cursor setting.
gpu-screen-recorder and wl-screenrec receive their corresponding cursor
options. wf-recorder does not expose a portable cursor flag, so its behavior
depends on the compositor.

- **Markup** captures the region and opens it in the shell's annotation
  editor; Copy and Save deliver the annotated PNG per the shell's screenshot
  policy. **Markup FS** captures the focused monitor. **Markup Window** dims
  the screen except the hovered window — click captures that window
  (Hyprland; Niri captures the focused window instead).
- **Measure** reports the region's pixel size and copies it to the clipboard.
- **OCR** extracts text and copies it to the clipboard. The result includes the
  capture preview and an editable multiline text area, so you can correct, trim,
  or extend the OCR output before copying, searching, translating, or sharing
  it. Detected URLs can be opened directly and detected email addresses can
  open a mail composer.
- **QR** decodes a code and copies the text to the clipboard.
- **Palette** copies the extracted hex colors (one per line) to the clipboard.
- **Share** uploads the current capture and copies the link (uguu.se by default,
  or up.x02.me with an API key).

Results are delivered to the clipboard with a notification — the panel itself
only holds the tools. Results persist across restarts in the plugin's data
directory. Captures land in the shell's screenshot directory and persist —
except for the text-only tools (OCR, QR, Palette, Measure, Lens), which work
off a temp copy and delete the screenshot right away, so they leave no file
behind. Window crops and recording thumbnails live in `/tmp`.

## Settings

All settings live in Settings → Plugins (gear on the plugin's row).

| Setting | Type | Default | Description |
| --- | --- | --- | --- |
| `video-path` | `folder` | `~/Videos` | Where recordings are saved. |
| `filename-format` | `string` | `%Y-%m-%d_%H-%M-%S` | Filename template; the extension is added automatically. |
| `selected-ocr-lang` | `string` | `eng` | Tesseract language code; combine with `+` (e.g. `eng+fra`). |
| `search-engine-url` | `string` | *(Google)* | Search URL prefix, or a URL containing `{text}`. The OCR text is URL-encoded. |
| `x02-api-key` | `string` | *(empty)* | up.x02.me key for longer-lived, larger uploads. |
| `x02-expiry` | `select` | `7d` | Link lifetime when an x02 key is set: `1h`, `1d`, `7d`, `30d`, or `permanent`. |
| `share-skip-popover` | `bool` | `false` | Compatibility setting retained from v4. The v5 result panel copies share links directly. |
| `record-audio-out` | `bool` | `false` | Record the desktop's audio output. |
| `record-audio-in` | `bool` | `false` | Record the default microphone. |
| `hide-cursor` | `bool` | `true` | Exclude the cursor from recordings. Screenshots follow the shell's screenshot cursor setting. |
| `record-codec` | `select` | `h264` | Codec for `gpu-screen-recorder` fullscreen capture: `h264`, `hevc`, or `av1`. `h264` is the safest NVIDIA NVENC default; `av1` needs a recent GPU. |
| `record-fps` | `int` | `60` | Frame rate for `gpu-screen-recorder` fullscreen capture (15–240). |
| `record-skip-confirmation` | `bool` | `false` | Save automatically when a recording ends, skipping the save dialog. |
| `record-copy-to-clipboard` | `bool` | `false` | Finalize to MP4 and copy the file URI when recording ends. |
| `gif-max-seconds` | `int` | `30` | Cap for GIF recordings (1–600 s). |
| `panel-mode` | `select` | `standard` | Main panel layout: `standard` (dense grid, 380×260) or `legacy` (4×2 legacy grid, 380×260). |

## IPC

The service is a singleton with no output, so the IPC target is `all`:

```sh
noctalia msg plugin alexander/screen-toolkit:service all toggle
noctalia msg plugin alexander/screen-toolkit:service all colorPicker
noctalia msg plugin alexander/screen-toolkit:service all ocr
noctalia msg plugin alexander/screen-toolkit:service all qr
noctalia msg plugin alexander/screen-toolkit:service all palette
noctalia msg plugin alexander/screen-toolkit:service all lens
noctalia msg plugin alexander/screen-toolkit:service all measure
noctalia msg plugin alexander/screen-toolkit:service all annotate
noctalia msg plugin alexander/screen-toolkit:service all annotateFullscreen
noctalia msg plugin alexander/screen-toolkit:service all annotateWindow
noctalia msg plugin alexander/screen-toolkit:service all record
noctalia msg plugin alexander/screen-toolkit:service all recordMp4
noctalia msg plugin alexander/screen-toolkit:service all recordFullscreen
noctalia msg plugin alexander/screen-toolkit:service all recordFullscreenMp4
noctalia msg plugin alexander/screen-toolkit:service all recordStop
noctalia msg plugin alexander/screen-toolkit:service all recordSave
noctalia msg plugin alexander/screen-toolkit:service all recordCopy
noctalia msg plugin alexander/screen-toolkit:service all recordDiscard
noctalia msg plugin alexander/screen-toolkit:service all ocrSearch
noctalia msg plugin alexander/screen-toolkit:service all clearResult
noctalia msg plugin alexander/screen-toolkit:service all clearHistory
```

`toggle` opens the panel matching the `panel-mode` setting. The bar widget and
control-center shortcut use the same logic.

Commands that take a payload:

```sh
# Translate the current OCR text into a language (language code payload)
noctalia msg plugin alexander/screen-toolkit:service all ocrTranslate en
# Search the current OCR text (or a payload.text) with the configured engine
noctalia msg plugin alexander/screen-toolkit:service all ocrSearch
# Share a file on disk (absolute path payload)
noctalia msg plugin alexander/screen-toolkit:service all share /path/to/image.png
# Save the finished recording (payload format: "gif" or "mp4")
noctalia msg plugin alexander/screen-toolkit:service all recordSave mp4
# Show or hide the cursor in captures (payload: "true" or "false")
noctalia msg plugin alexander/screen-toolkit:service all setCursorHidden true
```

Summary of every service command:

| Command | Payload | Action |
| --- | --- | --- |
| `toggle` | — | Open/close the tools panel (matches `panel-mode`) |
| `colorPicker` | — | Pick a color from the screen (hyprpicker magnifier) |
| `ocr` | — | Extract text from a region |
| `qr` | — | Decode a QR / barcode from a region |
| `palette` | — | Extract hex colors from a region |
| `lens` | — | Google Lens search on a region |
| `measure` | — | Report a region's pixel size |
| `annotate` | — | Open a region in the annotation editor |
| `annotateFullscreen` | — | Annotate the full screen |
| `annotateWindow` | — | Hover-aim and capture a window (Hyprland) / focused window (Niri) |
| `record` | — | Record a region as GIF |
| `recordMp4` | — | Record a region as MP4 |
| `recordFullscreen` | — | Record the full screen as GIF |
| `recordFullscreenMp4` | — | Record the full screen as MP4 |
| `recordStop` | — | Stop the active recording |
| `recordSave` | `"gif"` / `"mp4"` | Save the finished recording |
| `recordCopy` | — | Finalize to MP4 and copy the file URI |
| `recordDiscard` | — | Discard the finished recording |
| `ocrSearch` | optional `{text}` | Search OCR text with the configured engine |
| `ocrTranslate` | language code | Translate OCR text |
| `share` | file path | Upload a file and copy the link |
| `clearResult` | — | Clear the current result panel state |
| `clearHistory` | — | Clear the color history |
| `setCursorHidden` | \"true\" / \"false\" | Exclude/include the cursor in recordings |

## Notes

- **Two panel entries, one layout setting.** Panel size is host-owned: the host
  sizes each `[[panel]]` entry from its `width`/`height`, and there is no runtime
  resize. So the two layouts are two entries sharing `panel.luau`:
  `panel` (380×260, the standard grid) and `panel-legacy` (380×260, the legacy grid).
  The `panel-mode` setting picks which one `toggle` opens; changing the setting
  only affects which panel opens next time; an already-open panel keeps its
  current size until closed.
- This is a port of the legacy v4
  [screen-toolkit](https://github.com/noctalia-dev/legacy-v4-plugins/tree/main/screen-toolkit)
  plugin. Tools that relied on freeform v4 QML overlays are adapted: region
  selection and annotation go through the shell's screenshot stack, window
  aiming dims everything except the hovered window (`hyprctl dim_around` on
  Hyprland), and measure reports region dimensions instead of drawing a line
  overlay. **Pin** (floating screen overlays) and **Webcam Mirror** could not
  be ported — the v5 plugin UI has no canvas or always-on-top surfaces — so
  they are not included.
- Recording auto-detects its backend: **fullscreen** uses `gpu-screen-recorder`
  when installed (NVENC hardware encoding — the best option on NVIDIA GPUs,
  where wl-screenrec's VAAPI path is unreliable), falling back to
  `wl-screenrec` then `wf-recorder`. **Region** capture uses `wl-screenrec` then
  `wf-recorder`, because `gpu-screen-recorder` cannot record an arbitrary
  sub-region. Microphone audio is only supported by `wl-screenrec`; with
  `wf-recorder` only a single audio source (system *or* microphone) is available, and gpu-screen-recorder's audio
  follows its own source selection.
- Region coordinates are captured in physical pixels; `recordFullscreen`
  multiplies the focused output's logical geometry by its scale.
- Files are written to your configured screenshot/video directories and the
  plugin's persistent data directory (state, color history). Captures in `/tmp`
  are transient.
- Network calls: Google Lens upload (uguu.se), share uploads (uguu.se or
  up.x02.me), and `xdg-open` for search/URL results.

## License

This remake is released under the MIT license. It is an independent v5 port of
the original legacy plugin; see [Attribution](#attribution) for the original
project and source.
