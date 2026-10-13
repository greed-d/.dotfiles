# Niri
## 🖼️ Showcase
### 🖥️ Desktop :
![!niri1](./.screenshots/niri-desktop.png)
### Fetch
![!niri2](./.screenshots/niri-fetch.png)
### 🎵 Spotify :
![!niri2](./.screenshots/niri-music.png)
### 💬 Discord :
![!niri3](./.screenshots/niri-discord.png)
### 🧑‍💻 Neovim :
![nirinvim](./.screenshots/niri-nvim.png)
## 🛠️ Stuffs used

- **Shell** : [Noctalia](https://github.com/noctalia-dev/noctalia-shell)
- **Lockscreen** : [Made with Noctalia Widgets](https://github.com/noctalia-dev/noctalia-shell)
- **App Launcher** : [Vicinae](https://github.com/vicinaehq/vicinae)
- **Terminal** :
    - Emulator : [ghostty](https://ghostty.org/)
    - Shell : [Fish](https://fishshell.com/)
    - Prompt : [Starship](https://starship.rs/)
    - Font : [JetBrainsMono Nerd Font](https://github.com/ryanoasis/nerd-fonts)
- **Code Editor** : [Neovim](https://neovim.io/)
- **System Font** : [Google Sans](https://aur.archlinux.org/packages/ttf-google-sans)
- **Discord Client** : [vesktop](https://github.com/Vencord/Vesktop)
- **AUR Helper** : [paru](https://github.com/Morganamilo/paru)
- **File Browser** : Dolphin
- **Music Stream** : Spotify with spicetify

## 🗂️ Config structure
Everything is split by topic and included from `config.kdl` :
```
config.kdl            # entry point (includes everything below)
config/
  general.kdl         # workspaces, misc, cursor, debug, environment
  input.kdl           # keyboard, touchpad, mouse, gestures
  monitor.kdl         # outputs
  layout.kdl          # layout geometry (gaps, presets, borders...)
  theme.kdl           # all colors (swap this to restyle)
  animations.kdl      # animations + custom shaders
  blur.kdl            # blur settings
  window-rules.kdl    # window rules (floating, blur, workspaces...)
  layer-rules.kdl     # layer-shell rules (launcher, shadows, backdrops)
  keybinds.kdl        # all binds + Alt-Tab switcher
  startup.kdl         # spawn-at-startup
dms/                  # DMS shell alternative (disabled, see config.kdl)
```

## ⚙️ Installation
> [!WARNING]
> This is not a installation guide just a wireframe of what you'd want to install, please keep that in mind :

- Install fonts and other stuff :
```bash
paru -S ttf-jetbrains-mono-nerd ttf-google --noconfirm
```
- Install desktop portals :
```bash
paru -S xdg-desktop-portal-gtk xdg-desktop-portal --noconfirm
```
- Install required stuff :
```bash
paru -S niri-git noctalia-git ghostty vicinae-bin app2unit zoxide starship polkit-gnome webkit2gtk plasma-integration --noconfirm
```
- Install cursor theme :
```bash
paru -S bibata-cursor-git
```
## 👽 Extra Info : 
- **Wallpaper Repository :** [orangci's collection](https://github.com/orangci/walls-catppuccin-mocha)
- **Neovim config** : [Here]( https://github.com/greed-d/nvim )
