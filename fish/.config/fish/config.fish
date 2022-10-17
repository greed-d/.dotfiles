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
alias ll "exa -lah --color automatic --no-permissions --git --icons --group-directories-first --no-user" 
alias wl "nmcli device wifi list"
alias cw "echo 'nmcli device wifi connect SSID password PW'"
alias sw "nmcli device wifi show"
alias .. "cd .."
alias ... "cd ../.."
alias .... "cd ../../.."
alias lg "lazygit"
alias rm "trash --"


neofetch --config ~/dotfiles/neofetch/config2.conf

function fish_greeting
    echo Hello $USER!
    echo You logged in to $hostname at (set_color yellow; date +%T; set_color normal)
end
starship init fish | source
