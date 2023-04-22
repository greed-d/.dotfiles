## BSPWM :

![Qtile2](./.screenshots/bspdesktop.png) ![Qtile](./.screenshots/bspwf.png)

- Terminal Theme :
  [Catppuccin (Mocha Flavour)](https://github.com/catppuccin/alacritty)
- Neovim Theme :
  [Catppuccin (Mocha Flavour)](https://github.com/catppuccin/nvim)
- Terminal Font :
  [Caskaydia Cove](https://github.com/ryanoasis/nerd-fonts/releases/download/v2.2.2/CascadiaCode.zip)

### Installation (Arch Based) :

Install qtile and it's dependencies :

```bash
sudo pacman -S bspwm sxhkd
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
