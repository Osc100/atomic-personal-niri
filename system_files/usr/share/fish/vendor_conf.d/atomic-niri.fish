# Defaults for every user, adapted from CachyOS's fish config. Anything here can
# be overridden in ~/.config/fish/config.fish.

fish_add_path ~/.local/bin ~/.cargo/bin

status is-interactive; or return

function fish_greeting
    fastfetch
end

function history
    builtin history --show-time='%F %T ' $argv
end

# !! and !$ like in bash
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

if test "$fish_key_bindings" = fish_vi_key_bindings
    bind -Minsert ! __history_previous_command
    bind -Minsert '$' __history_previous_command_arguments
else
    bind ! __history_previous_command
    bind '$' __history_previous_command_arguments
end

command -q mise; and mise activate fish | source
command -q starship; and starship init fish | source
