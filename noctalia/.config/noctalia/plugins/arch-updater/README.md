# Arch Updater
A plugin designed to allow you to see available updates, the currently installed version and the updated version.<br>
With optional Flatpak support, highlight for Noctalia updates, refresh timer, hide on empty, tooltip, toasts, desktop widget and launcher integration.

## Features

**Bar Widget**
- Update count
- Left click to open panel
- Right click to open context menu
- Middle click to refresh
- Tooltip with updates list

**Panel**
- Table of updates
- Copy names and versions by clicking on them
- Context menu to copy text, open package repo or visit homepage
- Refresh/Update buttons

**Desktop Widget**
- Update count
- Table of updates
- Left click to refresh
- Middle click to update

**IPC**
- Refresh with `qs -c noctalia-shell ipc call plugin:arch-updater refresh`
- Update with `qs -c noctalia-shell ipc call plugin:arch-updater update`

**Launcher Integration**
- Refresh with `>au-refresh`
- Update with `>au-update`
- View updates with `>au-search` and open their repo page in a browser

**Control Center Widget**
- Open panel

## Configuration
Configuration is done through the settings window accessible from the context menu, panel and desktop widget

## Requirements
- The default commands require `paru`, `pacman-contrib`, `flatpak`, `appstream` and `ghostty`
- `wl-copy` is required to copy names and versions from the panel
- Designed for Arch, although commands can be edited so it may be possible to make it work on other distros
- CPU (Optional)

### Note:
This is my first QML project, so I apologize for any sloppy code
