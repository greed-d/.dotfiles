# Implementation Progress

This file records the changes made for the cross-distribution install work and
the verification that was performed.  It is intentionally kept in the
repository as a short maintenance log.

## Step 1 - Repository inspection

- [x] Inspected every top-level Stow package and the Niri, Noctalia,
      DankMaterialShell (DMS), fish, ghostty, tmux, MPV, systemd and scripts
      configuration trees.
- [x] Identified commands and resources referenced by the active configuration:
      `niri`, `noctalia`, `dms`, `foot`/`footclient`, `ghostty`, `fish`,
      `starship`, `zoxide`, `fzf`, `eza`, `yazi`, `tmux`, `nvim`, `btop`,
      `lazygit`, `fastfetch`, `bat`, `fd`, `rg`, `wl-clipboard`, `wtype`,
      `fuzzel`, `nautilus`, `helium`, `vicinae`, `app2unit`, `spotify-launcher`,
      `vesktop`, `mpv`, `ffmpeg`, `yt-dlp`, `playerctl`, `pamixer`,
      `brightnessctl`, `wf-recorder`, `grim`, `slurp`, `jq`, `curl`, `unzip`,
      `matugen`, `JetBrainsMono Nerd Font`, `Google Sans`, `Google Sans Flex`
      and the Bibata cursor theme.
- [x] Confirmed GNU Stow is the deployment mechanism and that multiple packages
      share `~/.config`; the installer therefore simulates a full restow before
      changing anything.

## Step 2 - Remove YTM and Zed

- [x] Removed `ytm/` and `zed/` from the working tree and from Git tracking
      with `git rm -r ytm zed`.
- [x] Disabled DMS's `matugenTemplateZed` generation flag so it no longer
      creates Zed theme files.
- [x] Checked for remaining active references; none remain.

## Step 3 - Remove Rofi from active tracking

- [x] Removed `rofi/` from the working tree and from Git tracking with
      `git rm -r rofi`.
- [x] Removed the Rofi layer rule from
      `niri/.config/niri/config/layer-rules.kdl`.
- [x] Removed the commented Rofi launcher line from
      `fish/.config/fish/config.fish`.
- [x] Removed `CM_LAUNCHER:rofi` from
      `fish/.config/fish/fish_variables`.
- [x] Confirmed Rofi history is still available with
      `git log --all -- rofi` (no history rewrite was performed).

## Step 4 - Replace the MPV OSC with material-osc

- [x] Inspected the upstream material-osc README and release `0.0.14`.
- [x] Removed `modernx.lua` and `modernx-osc-icon.ttf` from Git tracking and
      the working tree.
- [x] Installed the upstream release files:
      - `mpv/.config/mpv/scripts/material-osc.lua`
      - `mpv/.config/mpv/fonts/material-osc_icons.otf`
      - `mpv/.config/mpv/fonts/material-osc_google_sans_flex.ttf`
- [x] Replaced `mpv/.config/mpv/scripts/thumbfast.lua` with the current
      upstream Thumbfast script required for thumbnail previews.
- [x] Kept the existing `script-opts/thumbfast.conf` settings intact.
- [x] Added `mpv/.config/mpv/script-opts/material-osc.conf` with the Catppuccin
      Mocha mauve accent (`#cba6f7`).  No unrelated MPV settings were added.
- [x] The upstream script disables mpv's native OSC itself
      (`mp.set_property("osc", "no")`), so no extra `mpv.conf` entry is needed.
- [x] MPV runtime dependencies are covered by the installer: `mpv`, `ffmpeg`,
      `yt-dlp` and optional `python3-guessit`/`python-guessit`.

## Step 5 - Create install.sh

- [x] Added `install.sh` with:
      - Arch/Fedora detection through `/etc/os-release`.
      - Non-root execution with lazy `sudo` validation.
      - Idempotent installed-package checks before every transaction.
      - Separate Arch and Fedora installation sections.
      - Arch source order: official repositories, AUR, upstream fallback.
      - Fedora source order: enabled DNF repositories, relevant third-party
        repositories (RPM Fusion), COPR, upstream fallback.
      - AUR helper bootstrap from `paru-bin` when no `paru`/`yay` is present.
      - COPR enablement only when a package is not already available.
      - User-local fallback fonts from the official Google Fonts and Nerd Fonts
        releases when distro packages do not provide them.
      - Fedora fallbacks for Vesktop (official GitHub RPM), Spotify
        (RPM Fusion `lpf` or COPR) and neofetch (official archived upstream
        script).
      - `stow --simulate --restow` before any real Stow operation; conflicts
        abort the link step instead of overwriting user files.
      - Cleanup of stale symlinks that point into the removed `rofi`/`ytm`/`zed`
        packages (real user files are never touched).
      - `--dry-run`, `--no-packages`/`--stow-only`, `--no-stow`, `--skip-fonts`
        and `--help`.
- [x] Added the small compatibility shims required by the existing config:
      `/usr/local/bin/helium` on Arch (AUR installs `helium-browser`), a
      `/opt/Vesktop/vesktop` link on Arch, and a Fedora `spotify-launcher`
      wrapper when RPM Fusion's `spotify-client` is present.

## Step 6 - Verification and tests

- [x] `bash -n install.sh` passes.
- [x] `install.sh --help` works and returns 0.
- [x] `install.sh --dry-run --no-stow` completes without changing the system.
- [x] `install.sh --dry-run --stow-only` completes without conflicts.
- [x] `stow --dir="$PWD" --target="$HOME" --simulate --restow ...` succeeds for
      all 15 active packages.
- [x] Ran `install.sh --stow-only` twice against a temporary `HOME`; both runs
      returned 0 and the second run was idempotent.
- [x] Verified conflict safety in the temporary `HOME`: placing a real
      `~/.config/ghostty/config` made the Stow simulation abort with exit 1
      while leaving the real file untouched.
- [x] `git ls-files` contains no `rofi/`, `ytm/` or `zed/` paths.
- [x] Rofi history remains visible through `git log --all -- rofi`.
- [x] No active Rofi references remain in tracked configuration (the only
      mention is the explanatory comment in `install.sh`).
- [x] Material-osc and Thumbfast files are present in the live
      `~/.config/mpv` tree through the existing Stow link.
- [x] Fontconfig detects `JetBrainsMono Nerd Font`, `Google Sans` and
      `Google Sans Flex` on the current Fedora system.

## Known limitations / remaining manual steps

- Arch package installation was not executed on this Fedora 45 machine.  The
  Arch package names were verified against `archlinux.org` and the AUR RPC;
  the actual pacman/AUR transaction still needs to be run on an Arch host.
- A real end-to-end Fedora package transaction was not run in this session; the
  dry-run and repository metadata checks were used instead.
- Fedora Spotify uses the `lpf` workflow, which requires accepting Spotify's
  EULA interactively.  Run `sudo lpf update spotify-client` after the installer,
  then re-run `./install.sh` so the `spotify-launcher` wrapper is created.
- Fedora does not package neofetch for current releases; the installer uses the
  archived official 7.1.0 script.  `fastfetch` is installed as the maintained
  alternative.
- `fish` plugins (fisher, nvm.fish, fzf.fish, catppuccin/fish, etc.) are already
  tracked as configuration but are not updated by `install.sh`; run
  `fisher update` if those plugins need to be refreshed.