function enable_ayu_theme_dark
    set --universal fish_color_autosuggestion 4D5566 # ayu:common.ui        autosuggestions
    set --universal fish_color_command        39BAE6 # ayu:syntax.tag       commands
    set --universal fish_color_comment        626A73 # ayu:syntax.comment   code comments
    set --universal fish_color_cwd            59C2FF # ayu:syntax.entity    current working directory in the default prompt
    set --universal fish_color_end            F29668 # ayu:syntax.operator  process separators like ';' and '&'
    set --universal fish_color_error          FF3333 # ayu:syntax.error     highlight potential errors
    set --universal fish_color_escape         95E6CB # ayu:syntax.regexp    highlight character escapes like '\n' and '\x70'
    set --universal fish_color_match          F07178 # ayu:syntax.markup    highlight matching parenthesis
    set --universal fish_color_normal         B3B1AD # ayu:common.fg        default color
    set --universal fish_color_operator       E6B450 # ayu:syntax.accent    parameter expansion operators like '*' and '~'
    set --universal fish_color_param          B3B1AD # ayu:common.fg        regular command parameters
    set --universal fish_color_quote          C2D94C # ayu:syntax.string    quoted blocks of text
    set --universal fish_color_redirection    FFEE99 # ayu:syntax.constant  IO redirections
    set --universal fish_color_search_match   --background E6B450 # ayu:syntax.accent    highlight history search matches and the selected pager item (must be a background)
    set --universal fish_color_selection      E6B450 # ayu:syntax.accent    when selecting text (in vi visual mode)

    # color for fish default prompts item
    set --universal fish_color_cancel         0A0E14 # ayu:common.bg        the '^C' indicator on a canceled command
    set --universal fish_color_host           FFEE99 # ayu:syntax.constant  current host system in some of fish default prompts
    set --universal fish_color_host_remote    FFEE99 # ayu:syntax.constant  current host system in some of fish default prompts, if fish is running remotely (via ssh or similar)
    set --universal fish_color_user           FF8F40 # ayu:syntax.keyword   current username in some of fish default prompts
end