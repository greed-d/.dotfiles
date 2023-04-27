
# Bang Bang command
function __history_previous_command
  switch (commandline -t)
  case "!"
    commandline -t $history[1]; commandline -f repaint
  case "*"
    commandline -i !
  end
end

function __history_previous_command_arguments
  switch (commandline -t)
  case "!"
    commandline -t ""
    commandline -f history-token-search-backward
  case "*"
    commandline -i '$'
  end
end
bind ! __history_previous_command
bind '$' __history_previous_command_arguments

# set up the same key bindings for insert mode if using fish_vi_key_bindings
if test "$fish_key_bindings" = 'fish_vi_key_bindings'
    bind --mode insert ! __history_previous_command
    bind --mode insert '$' __history_previous_command_arguments
end

function _plugin-bang-bang_uninstall --on-event plugin-bang-bang_uninstall
    bind --erase --all !
    bind --erase --all '$'
    functions --erase _plugin-bang-bang_uninstall
end
#End of bang bang

function fish_greeting
    echo Hello $USER!
    echo You logged in to $hostname at (set_color yellow; date +%T; set_color normal)
end

# Vim config switcher
function astronvim
    env NVIM_APPNAME=astronvim nvim
end

function nvchad
    env NVIM_APPNAME=nvchad nvim
end

 function nvims
     set items astronvim nvchad
     set config (printf "%s\n" $items | fzf --prompt=" Neovim Config  " --height=~50% --layout=reverse --border --exit-0)
     if [ -z $config ]
         echo "Nothing selected"
         return 0
     else if [ $config = "default" ]
         set config ""
     end
     env NVIM_APPNAME=$config nvim $argv
 end

bind \ca 'nvims'

alias ls "exa -a --icons --group-directories-first"
alias lt "exa -lah --icons --color automatic --no-user --git -T -L 4 --ignore-glob=".git" --group-directories-first" 
alias lt "exa -lah --color automatic -T -L 2 --git --icons --group-directories-first --no-user" 
alias wl "nmcli device wifi list"
#alias cw "echo 'nmcli device wifi connect SSID password PW'"
alias sw "nmcli device wifi show"
alias .. "cd .."
alias ... "cd ../.."
alias .... "cd ../../.."
alias e "nautilus ."
alias x "exit"
alias lg "lazygit"
alias tns "tmux new -s"
alias tas "tmux attach -t"
alias tls "tmux list-sessions"
alias tds "tmux detach"
alias rm "trash"
alias clr "clear && neofetch --config ~/.config/neofetch/config.small.conf --ascii_distro arch_small"
alias cc "qtile cmd-obj -o widget wifiicon -f eval -a 'self.is_connected' && qtile cmd-obj -o widget wifiicon -f eval -a 'self.check_connection()'"
alias ttc "tty-clock -SsctC5"
alias dot "tmux-sessionizer ~/.dotfiles"
alias vi "NVIM_APPNAME=nvchad nvim"
alias scrkey "screenkey -s small --opacity 0.6 -p fixed -g 30%x7%+69%-2%"
# alias discfix "bash -c '$(curl https://raw.githubusercontent.com/fuwwy/Discord-Screenshare-Linux/main/scripts/install.sh -sSfL)'"

bind \cf "tmux-sessionizer"

set PATH "$PATH":"$HOME/.local/scripts/"
set PATH "$PATH":"$HOME/.flutter_install/flutter/bin"
set PATH "$PATH":"$HOME/Android/Sdk/platform-tools/"
neofetch --config ~/.config/neofetch/config.small.conf --ascii_distro arch_small
# macchina


starship init fish | source

jump shell fish | source
fish_add_path /home/greed/.spicetify

