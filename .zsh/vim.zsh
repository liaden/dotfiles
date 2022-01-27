bindkey -v

# change cursor between modes
# this also fixes cursor that was mutated by programs that load .inputrc
function zle-keymap-select zle-line-init
{
    # change cursor shape in iTerm2
    case $KEYMAP in
        vicmd)      print -n -- "\E]50;CursorShape=0\C-G";;  # block cursor
        viins|main) print -n -- "\E]50;CursorShape=1\C-G";;  # line cursor
    esac

    zle reset-prompt
    zle -R
}

function zle-line-finish
{
    print -n -- "\E]50;CursorShape=0\C-G"  # block cursor
}

zle -N zle-line-init
zle -N zle-line-finish
zle -N zle-keymap-select

# cause it is really only vi mode
bindkey -a -s "diw" "bde"
bindkey -a -s "daw" "bdw"
bindkey -a -s "diW" "bdE"
bindkey -a -s "daW" "bdW"

# shorten latency when escaping to normal mode
export KEYTIMEOUT=1

# add other features back into vim cli mode
bindkey '^P' up-history
bindkey '^N' down-history
bindkey '^?' backward-delete-char
bindkey '^h' backward-delete-char
bindkey '^w' backward-kill-word
bindkey '^r' history-incremental-search-backward

# toggle fg/bg (mostly vim) with c-z
function fg-bg {
    if [[ $#BUFFER -eq 0 ]]; then
        BUFFER=fg
        zle accept-line
    else
        zle push-input
    fi
}
zle -N fg-bg
bindkey '^z' fg-bg
