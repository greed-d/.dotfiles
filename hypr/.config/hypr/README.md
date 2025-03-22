# Hyprland Dots

## Stuffs used

|  Stuffs used   |                       Links                            |
| :------------: | :----------------------------------------------------: |
|   AUR Helper   |[paru](https://github.com/Morganamilo/paru)             |
|    Browser     |[Zen Browser](zen-browser.app)                          |
|     Fetch      |[nitch](https://github.com/ssleert/nitch)               |
| File Explorer  |thunar                                                  |
|    Terminal    |[ghostty](https://ghostty.org/)                         |
|    Panel       |[HyprPanel](https://github.com/Jas-SinghFSU/HyprPanel)  |
| Discord Client |[vesktop](https://github.com/Vencord/Vesktop)           |
| YT Music Theme |[catppuccin](https://github.com/catppuccin/youtubemusic)|
|   GTK theme    |[catppuccin](https://github.com/catppuccin/gtk)         |

## Screenshots

![hypr1](./.screenshots/wallpaper.png)

![hypr2](./.screenshots/fetch.png)


![hypr3](./.screenshots/tabliss.png)

![hypr3](./.screenshots/explorer.png)
![hypr3](./.screenshots/spotify.png)

![hypr3](./.screenshots/discord.png)

## Installation

### Install hyprland and other required packages
#### Pacman
```bash
sudo pacman -S hyprland hypridle hyprlock pacman-contrib ghostty thunar spotify-launcher fish ttf-jetbrains-mono-nerd thunar cliphist brightnessctl wireplumber playerctl
```
#### AUR

```
paru -S ags-hyprpanel-git rofi-lbonn-wayland-only-git youtube-music-bin vesktop-bin
```

Install Stow

```bash
sudo pacman -S stow
```

Clone the repo :

```bash
git clone https://github.com/greeid/.dotfiles ~/.dotfiles/ -b catppuccin --depth=1
```

Stow the repo

```bash
cd ~/.dotfiles/
stow hypr/ alacritty/ fish/ scripts/ rofi/ hyprpanel/ scripts/
```

> [!NOTE]  
> More packages may be needed to be installed in order for WM to work properly

