
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


alias ls "exa -a --icons --group-directories-first"
alias ll "exa -lah --color automatic --git --icons --group-directories-first --no-user" 
alias wl "nmcli device wifi list"
alias cw "echo 'nmcli device wifi connect SSID password PW'"
alias sw "nmcli device wifi show"
alias .. "cd .."
alias ... "cd ../.."
alias .... "cd ../../.."
alias e "thunar ."
alias x "exit"
alias lg "lazygit"
alias tns "tmux new -s"
alias tas "tmux attach -t"
alias tls "tmux list-sessions"
alias tds "tmux detach"
alias rem "trash --"
alias clr "clear && neofetch --config ~/.config/neofetch/config.small.conf"
alias cc "qtile cmd-obj -o widget wifiicon -f eval -a 'self.is_connected' && qtile cmd-obj -o widget wifiicon -f eval -a 'self.check_connection()'"
alias ttc "tty-clock -SsctC5"

#bind \cm "finder"

set PATH "$PATH":"$HOME/.local/share/scripts/"

neofetch --config ~/.config/neofetch/config.small.conf

function fish_greeting
    echo Hello $USER!
    echo You logged in to $hostname at (set_color yellow; date +%T; set_color normal)
end
starship init fish | source
