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

# function fish_greeting
#     echo Hello $USER!
#     echo You logged in to $hostname at (set_color yellow; date +%T; set_color normal)
# end

#-------------------------------------->  Vim config switcher <--------------------------------------

function astronvim
    env NVIM_APPNAME=astronvim nvim
end

function vanvim
    env NVIM_APPNAME=vanvim nvim
end

function chad
    env NVIM_APPNAME=nvchad nvim
end

 function nvims
     set items astronvim nvchad lvim
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

alias ls "eza --icons --git --group-directories-first"
alias la "eza -a --icons --git --group-directories-first"
alias lt "eza -lah --icons --color  --no-user --git -T -L 3 --ignore-glob=".git" --group-directories-first" 
alias lf "yazi"
#alias lt "eza -lah --color automatic -T -L 2 --git --icons --group-directories-first --no-user" 

#--------------------------------------> userful alias <--------------------------------------

alias lvim "env NVIM_APPNAME=LazyNvim nvim"
alias tvim "env NVIM_APPNAME=testvim nvim"
alias .. "cd .."
alias ... "cd ../.."
alias .... "cd ../../.."
alias ..... "cd ../../../.."
alias e "thunar"
alias x "exit"
alias lg "lazygit"
abbr rt "trash"
alias vi "NVIM_APPNAME=vanvim nvim"
alias nvd "neovide"
alias hvd "env -u WAYLAND_DISPLAY neovide --multigrid"
alias ffetch "fastfetch --config ~/.config/fastfetch/22.jsonc"

#--------------------------------------> nmcli options <--------------------------------------

#alias cw "echo 'nmcli device wifi connect SSID password PW'"
alias wl "nmcli device wifi list"
alias sw "nmcli device wifi show"

#--------------------------------------> misc aliases <--------------------------------------

# alias clr "clear && neofetch --config ~/.config/neofetch/config.small.conf --ascii_distro arch_small"
alias clr "clear && neofetch"
# alias clr "echo -en '\x1b[2J\x1b[1;1H' ; echo; echo; seq 1 (tput cols) | sort -R | spark | lolcat; echo; echo"
alias ttc "tty-clock -SsctC5"
alias rr "curl -s -L https://raw.githubusercontent.com/keroserene/rickrollrc/master/roll.sh | bash"
abbr cc "qtile cmd-obj -o widget wifiicon -f eval -a 'self.is_connected' && qtile cmd-obj -o widget wifiicon -f eval -a 'self.check_connection()'"
abbr scrkey "screenkey -s small --opacity 0.6 -p fixed -g 30%x7%+69%-2%"
abbr discfix "curl https://raw.githubusercontent.com/fuwwy/Discord-Screenshare-Linux/main/scripts/install.sh -sSfL | bash -c" #Wayland fix for screensharing on discord using pipewire
abbr sdwm "startx ~/.config/chadwm/scripts/run.sh"

#--------------------------------------> tmux options <--------------------------------------

alias dot "tmux-sessionizer ~/.dotfiles"
alias tns "tmux new -s"
alias tas "tmux attach -t"
alias tls "tmux list-sessions"
alias tds "tmux detach"

bind \cf "tmux-sessionizer"

#--------------------------------------> PATH <--------------------------------------

set PATH "$PATH":"$HOME/.local/scripts/"
set PATH "$PATH":"$HOME/.local/bin/"
set PATH "$PATH":"/usr/local/bin"
set PATH "$PATH":"$HOME/.cargo/bin/"
set -gx BROWSER floorp
fish_add_path -g -p $HOME/flutter/bin
#set --export JAVA_HOME (dirname (dirname (readlink -f (which java)))) #[REAL JAVA]

set --export ANDROID_HOME ~/Android/Sdk/
# set PATH "$PATH":"$HOME/.fluttercont/flutter/bin"
set PATH "$PATH":"$HOME/Android/Sdk/platform-tools/"
set PATH "$PATH":"$ANDROID_HOME/tools/"
set -gx ANDROID_SDK_ROOT ~/Android/Sdk/
# set PATH "$PATH":"$ANDROID_HOME/platform-tools/"
# export -Ux JAVA_HOME "/usr/bin/java"
## java 11 jdk

# set --export JAVA_HOME /usr/lib/jvm/java-17-openjdk 
# set --export JAVA_HOME /usr/lib/jvm/java-11-openjdk 
# set --export CM_LAUNCHER (/usr/bin/rofi)

set -e JAVA_OPTS
set -gx PATH $JAVA_HOME $PATH
#--------------------------------------> Load neofetch <--------------------------------------

# echo -en '\x1b[2J\x1b[1;1H' ; echo; echo; seq 1 (tput cols) | sort -R | spark | lolcat; echo; echo
# neofetch --config ~/.config/neofetch/config.small.conf --ascii_distro arch_small
# neofetch

#--------------------------------------> starship <--------------------------------------

starship init fish | source

#--------------------------------------> jump shell <--------------------------------------

zoxide init fish | source

#--------------------------------------> spicetify <--------------------------------------

fish_add_path /home/greed/.spicetify



### SPARK ###
# set -g spark_version 1.0.0
#
# complete -xc spark -n __fish_use_subcommand -a --help -d "Show usage help"
# complete -xc spark -n __fish_use_subcommand -a --version -d "$spark_version"
# complete -xc spark -n __fish_use_subcommand -a --min -d "Minimum range value"
# complete -xc spark -n __fish_use_subcommand -a --max -d "Maximum range value"
#
# function spark -d "sparkline generator"
#     if isatty
#         switch "$argv"
#             case {,-}-v{ersion,}
#                 echo "spark version $spark_version"
#             case {,-}-h{elp,}
#                 echo "usage: spark [--min=<n> --max=<n>] <numbers...>  Draw sparklines"
#                 echo "ezamples:"
#                 echo "       spark 1 2 3 4"
#                 echo "       seq 100 | sort -R | spark"
#                 echo "       awk \\\$0=length spark.fish | spark"
#             case \*
#                 echo $argv | spark $argv
#         end
#         return
#     end
#
#     command awk -v FS="[[:space:],]*" -v argv="$argv" '
#         BEGIN {
#             min = match(argv, /--min=[0-9]+/) ? substr(argv, RSTART + 6, RLENGTH - 6) + 0 : ""
#             max = match(argv, /--max=[0-9]+/) ? substr(argv, RSTART + 6, RLENGTH - 6) + 0 : ""
#         }
#         {
#             for (i = j = 1; i <= NF; i++) {
#                 if ($i ~ /^--/) continue
#                 if ($i !~ /^-?[0-9]/) data[count + j++] = ""
#                 else {
#                     v = data[count + j++] = int($i)
#                     if (max == "" && min == "") max = min = v
#                     if (max < v) max = v
#                     if (min > v ) min = v
#                 }
#             }
#             count += j - 1
#         }
#         END {
#             n = split(min == max && max ? "▅ ▅" : "▁ ▂ ▃ ▄ ▅ ▆ ▇ █", blocks, " ")
#             scale = (scale = int(256 * (max - min) / (n - 1))) ? scale : 1
#             for (i = 1; i <= count; i++)
#                 out = out (data[i] == "" ? " " : blocks[idx = int(256 * (data[i] - min) / scale) + 1])
#             print out
#         }
#     '
# end
### END OF SPARK ###


#THIS MUST BE AT THE END OF THE FILE FOR platform-tools TO WORK!!!
set PATH "$PATH":"$HOME/Android_Stuff/SDK/platform-tools"

# pnpm
set -gx PNPM_HOME "/home/greed/.local/share/pnpm"
if not string match -q -- $PNPM_HOME $PATH
  set -gx PATH "$PNPM_HOME" $PATH
end
# pnpm end
