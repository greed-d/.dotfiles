#--------------------------------------> Bang Bang command <--------------------------------------
function __history_previous_command
    switch (commandline -t)
        case "!"
            commandline -t $history[1]
            commandline -f repaint
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

function postexec_test --on-event fish_postexec
    echo
end

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
    env NVIM_APPNAME=nvim.chad nvim
end

function kvim
    env NVIM_APPNAME=nvim.bak nvim
end

function nvims
    set items astronvim nvchad lvim kvim
    set config (printf "%s\n" $items | fzf --prompt=" Neovim Config  " --height=~50% --layout=reverse --border --exit-0)
    if [ -z $config ]
        echo "Nothing selected"
        return 0
    else if [ $config = default ]
        set config ""
    end
    env NVIM_APPNAME=$config nvim $argv
end

bind \ca nvims

#--------------------------------------> Alias for direcotry <--------------------------------------

alias ls "eza --icons --git --group-directories-first"
alias la "eza -a --icons --git --group-directories-first"
alias lt "eza -lah --icons --color  --no-user --git -T -L 3 --ignore-glob=".git" --group-directories-first"
alias lf yazi
#alias lt "eza -lah --color automatic -T -L 2 --git --icons --group-directories-first --no-user" 

#--------------------------------------> userful alias <--------------------------------------

alias lvim "env NVIM_APPNAME=lazyvim nvim"
alias tvim "env NVIM_APPNAME=testvim nvim"
alias kvim "env NVIM_APPNAME=nvim-bak nvim"
alias .. "cd .."
alias ... "cd ../.."
alias .... "cd ../../.."
alias ..... "cd ../../../.."
alias e thunar
alias x exit
alias lg lazygit
abbr rt trash
alias ggu "git config --get user.name"
alias vi "NVIM_APPNAME=vanvim nvim"
alias nvd neovide
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

bind \cf tmux-sessionizer

#--------------------------------------> PATH <--------------------------------------

set PATH "$PATH":"$HOME/.local/scripts/"
set PATH "$PATH":"$HOME/ghostty/zig-out/bin/"
set PATH "$PATH":"$HOME/.local/bin/"
set PATH "$PATH":"$HOME/.local/colorscripts/"
set PATH "$PATH":"$HOME/.sdkman/candidates/gradle/current/bin/"
set PATH "$PATH":"/usr/local/bin"
set PATH "$PATH":"$HOME/.cargo/bin/"
set PATH "$PATH":"$HOME/.local/share/bob/nvim-bin"
set -gx BROWSER floorp
# set -gx GRIMBLAST_HIDE_CURSOR 0
fish_add_path -g -p $HOME/flutter/bin
#set --export JAVA_HOME (dirname (dirname (readlink -f (which java)))) #[REAL JAVA]

set --export ANDROID_HOME ~/Android/Sdk/
# set PATH "$PATH":"$HOME/.fluttercont/flutter/bin"
set PATH "$PATH":"/opt/android-sdk/platform-tools/"
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

#THIS MUST BE AT THE END OF THE FILE FOR platform-tools TO WORK!!!
set PATH "$PATH":"$HOME/Android_Stuff/SDK/platform-tools"

# pnpm
set -gx PNPM_HOME "/home/greed/.local/share/pnpm"
if not string match -q -- $PNPM_HOME $PATH
    set -gx PATH "$PNPM_HOME" $PATH
end
# pnpm end
