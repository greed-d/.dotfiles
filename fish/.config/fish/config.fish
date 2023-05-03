
### SPARK ###
set -g spark_version 1.0.0

complete -xc spark -n __fish_use_subcommand -a --help -d "Show usage help"
complete -xc spark -n __fish_use_subcommand -a --version -d "$spark_version"
complete -xc spark -n __fish_use_subcommand -a --min -d "Minimum range value"
complete -xc spark -n __fish_use_subcommand -a --max -d "Maximum range value"

function spark -d "sparkline generator"
    if isatty
        switch "$argv"
            case {,-}-v{ersion,}
                echo "spark version $spark_version"
            case {,-}-h{elp,}
                echo "usage: spark [--min=<n> --max=<n>] <numbers...>  Draw sparklines"
                echo "examples:"
                echo "       spark 1 2 3 4"
                echo "       seq 100 | sort -R | spark"
                echo "       awk \\\$0=length spark.fish | spark"
            case \*
                echo $argv | spark $argv
        end
        return
    end

    command awk -v FS="[[:space:],]*" -v argv="$argv" '
        BEGIN {
            min = match(argv, /--min=[0-9]+/) ? substr(argv, RSTART + 6, RLENGTH - 6) + 0 : ""
            max = match(argv, /--max=[0-9]+/) ? substr(argv, RSTART + 6, RLENGTH - 6) + 0 : ""
        }
        {
            for (i = j = 1; i <= NF; i++) {
                if ($i ~ /^--/) continue
                if ($i !~ /^-?[0-9]/) data[count + j++] = ""
                else {
                    v = data[count + j++] = int($i)
                    if (max == "" && min == "") max = min = v
                    if (max < v) max = v
                    if (min > v ) min = v
                }
            }
            count += j - 1
        }
        END {
            n = split(min == max && max ? "▅ ▅" : "▁ ▂ ▃ ▄ ▅ ▆ ▇ █", blocks, " ")
            scale = (scale = int(256 * (max - min) / (n - 1))) ? scale : 1
            for (i = 1; i <= count; i++)
                out = out (data[i] == "" ? " " : blocks[idx = int(256 * (data[i] - min) / scale) + 1])
            print out
        }
    '
end
### END OF SPARK ###
#--------------------------------------> Bang Bang command <--------------------------------------
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

#--------------------------------------> End of bang bang <--------------------------------------


#--------------------------------------> Greeting <--------------------------------------

function fish_greeting
    echo Hello $USER!
    echo You logged in to $hostname at (set_color yellow; date +%T; set_color normal)
end

#-------------------------------------->  Vim config switcher <--------------------------------------

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

#--------------------------------------> Alias for direcotry <--------------------------------------

alias ls "exa -a --icons --group-directories-first"
alias lt "exa -lah --icons --color automatic --no-user --git -T -L 4 --ignore-glob=".git" --group-directories-first" 
alias lt "exa -lah --color automatic -T -L 2 --git --icons --group-directories-first --no-user" 

#--------------------------------------> userful alias <--------------------------------------

alias .. "cd .."
alias ... "cd ../.."
alias .... "cd ../../.."
alias e "nautilus ."
alias x "exit"
alias lg "lazygit"
alias man "batman"
alias rt "trash"
alias vi "NVIM_APPNAME=nvchad nvim"

#--------------------------------------> nmcli options <--------------------------------------

#alias cw "echo 'nmcli device wifi connect SSID password PW'"
alias wl "nmcli device wifi list"
alias sw "nmcli device wifi show"

#--------------------------------------> misc aliases <--------------------------------------

# alias clr "clear && neofetch --config ~/.config/neofetch/config.small.conf --ascii_distro arch_small"
alias clr "echo -en '\x1b[2J\x1b[1;1H' ; echo; echo; seq 1 (tput cols) | sort -R | spark | lolcat; echo; echo"
alias cc "qtile cmd-obj -o widget wifiicon -f eval -a 'self.is_connected' && qtile cmd-obj -o widget wifiicon -f eval -a 'self.check_connection()'"
alias ttc "tty-clock -SsctC5"
alias scrkey "screenkey -s small --opacity 0.6 -p fixed -g 30%x7%+69%-2%"
alias rr "curl -s -L https://raw.githubusercontent.com/keroserene/rickrollrc/master/roll.sh | bash"
alias discfix "curl https://raw.githubusercontent.com/fuwwy/Discord-Screenshare-Linux/main/scripts/install.sh -sSfL | bash -c" #Wayland fix for screensharing on discord using pipewire

#--------------------------------------> tmux options <--------------------------------------

alias dot "tmux-sessionizer ~/.dotfiles"
alias tns "tmux new -s"
alias tas "tmux attach -t"
alias tls "tmux list-sessions"
alias tds "tmux detach"

bind \cf "tmux-sessionizer"

#--------------------------------------> PATH <--------------------------------------

set PATH "$PATH":"$HOME/.local/scripts/"
set PATH "$PATH":"$HOME/.flutter_install/flutter/bin"
set PATH "$PATH":"$HOME/Android/Sdk/platform-tools/"

#--------------------------------------> Load neofetch <--------------------------------------

echo -en '\x1b[2J\x1b[1;1H' ; echo; echo; seq 1 (tput cols) | sort -R | spark | lolcat; echo; echo
# neofetch --config ~/.config/neofetch/config.small.conf --ascii_distro arch_small

#--------------------------------------> starship <--------------------------------------

starship init fish | source

#--------------------------------------> jump shell <--------------------------------------

jump shell fish | source

#--------------------------------------> spicetify <--------------------------------------

fish_add_path /home/greed/.spicetify

