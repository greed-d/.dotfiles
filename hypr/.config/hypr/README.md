## BSPWM :

![Qtile2](./.screenshots/bspdesktop.png) ![Qtile](./.screenshots/bspwf.png)

![hypr1](./.screenshots/hyprwp.png) ![hypr2](./.screenshots/hyprofi.png)
![hypr2](./.screenshots/hypterm.png)

- Terminal Theme :
  [Catppuccin (Mocha Flavour)](https://github.com/catppuccin/alacritty)
- Neovim Theme :
  [Catppuccin (Mocha Flavour)](https://github.com/catppuccin/nvim)
- Terminal Font :
  [Jet Brains Mono](https://github.com/ryanoasis/nerd-fonts/releases/download/v2.3.3/JetBrainsMono.zip)

### Installation (Arch Based) :

Install qtile and it's dependencies :

```bash
sudo pacman -S hyprland
paru -S ttf-jetbrains-mono-nerd
```

Install Stow :

```bash
sudo pacman -S stow
```

Clone this repo:

```bash
https://github.com/greeid/.dotfiles
```

and use stow to implement all of my config :

```bash
stow */
```

If you want a specific config folder(say neovim):

```bash
stow nvim
```
