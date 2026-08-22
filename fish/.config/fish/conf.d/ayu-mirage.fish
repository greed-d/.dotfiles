function enable_ayu_theme_mirage
    set --universal fish_color_autosuggestion 707A8C # ayu:common.ui        autosuggestions
    set --universal fish_color_command        5CCFE6 # ayu:syntax.tag       commands
    set --universal fish_color_comment        5C6773 # ayu:syntax.comment   code comments
    set --universal fish_color_cwd            73D0FF # ayu:syntax.entity    current working directory in the default prompt
    set --universal fish_color_end            F29E74 # ayu:syntax.operator  process separators like ';' and '&'
    set --universal fish_color_error          FF3333 # ayu:syntax.error     highlight potential errors
    set --universal fish_color_escape         95E6CB # ayu:syntax.regexp    highlight character escapes like '\n' and '\x70'
    set --universal fish_color_match          F28779 # ayu:syntax.markup    highlight matching parenthesis
    set --universal fish_color_normal         CBCCC6 # ayu:common.fg        default color
    set --universal fish_color_operator       FFCC66 # ayu:syntax.accent    parameter expansion operators like '*' and '~'
    set --universal fish_color_param          CBCCC6 # ayu:common.fg        regular command parameters
    set --universal fish_color_quote          BAE67E # ayu:syntax.string    quoted blocks of text
    set --universal fish_color_redirection    D4BFFF # ayu:syntax.constant  IO redirections
    set --universal fish_color_search_match   --background FFCC66 # ayu:syntax.accent    highlight history search matches and the selected pager item (must be a background)
    set --universal fish_color_selection      FFCC66 # ayu:syntax.accent    when selecting text (in vi visual mode)

    # color for fish default prompts item
    set --universal fish_color_cancel         1F2430 # ayu:common.bg        the '^C' indicator on a canceled command
    set --universal fish_color_host           D4BFFF # ayu:syntax.constant  current host system in some of fish default prompts
    set --universal fish_color_host_remote    D4BFFF # ayu:syntax.constant  current host system in some of fish default prompts, if fish is running remotely (via ssh or similar)
    set --universal fish_color_user           FFA759 # ayu:syntax.keyword   current username in some of fish default prompts
end