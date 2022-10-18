# dotfile

It's a collection of my dotfiles

## Qtile :

![Qtile](../.screenshots/qtile.png)

### Installation (Arch Based) :

Install qtile and it's dependencies :

```bash
sudo pacman -S qtile pacman-contrib
paru -S nerd-font-mono-ubuntu
pip3 install psutil
```

Install Stow :

```bash
sudo pacman -S stow
```

Clone this repo and use stow to implement all of my config :

```bash
stow */
```

If you want a specific config folder(say neovim):

```bash
stow nvim
```

In case the network widget is not working use `ip address` to find your wireless modem, then :

```python
#Open the file ../qtile/settings/widget.py :

#Here you should find a list called *primary_widget*
#Find the line :

    widget.Net(**base(bg='color3'), interface='wlan0',
               mouse_callbacks={'Button1': lazy.spawn('iwgtk')}),

#Change the interface argument to your modem name, in my case 'wlan0'
```

Remember all of the keybinding will not work unless if finds all the apps I use :
To install all of the apps I use :

```bash
sudo pacman -S rofi betterlockscreen firefox discord pcmanfm alacritty redshift scrot picom
```

I also have some scripts for minor things like screenshot and toggling the mic.
You can find them in ../qtile/scripts.

### Autostart

I have an autostart script that autostarts stuffs like the systray icons and compositor

To get the systray icons :

```bash
sudo pacman -S cbatticon pamixer
```

You can change if you don't like something starting up on `../qtile/autostart.sh`

### Themes:
