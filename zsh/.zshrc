HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

setopt HIST_SAVE_NO_DUPS
setopt INC_APPEND_HISTORY

setopt autocd
setopt CORRECT
setopt SHARE_HISTORY

autoload -Uz compinit
# Only run the full security audit (stat every dir in $fpath) once a day;
# the rest of the day just load the completion dump without re-checking.
zcompdump="${ZDOTDIR:-$HOME}/.zcompdump"
if [[ -n ${zcompdump}(#qN.mh+24) ]]; then
    compinit
else
    compinit -C
fi
unset zcompdump

zmodload zsh/datetime

setopt prompt_subst

preexec() {
    cmd_start=$EPOCHREALTIME
}

# Formats an elapsed time (in seconds, float) as "123ms", "1,65s" or "08:04"
format_elapsed() {
    local elapsed=$1
    local ms=$(( elapsed * 1000 ))
    if (( ms < 1000 )); then
        printf '%.0fms' $ms
    elif (( elapsed < 60 )); then
        local s=$(printf '%.2f' $elapsed)
        print -n "${s//./,}s"
    else
        local total=${elapsed%.*}
        printf '%02d:%02d' $(( total / 60 )) $(( total % 60 ))
    fi
}

precmd() {
    local cmd_exit=$?

    if [[ -n "$cmd_start" ]]; then
        elapsed_show=$(format_elapsed $(( EPOCHREALTIME - cmd_start )))
        unset cmd_start
    else
        elapsed_show=""
    fi

    if (( cmd_exit == 0 )); then
        prompt_arrow="%F{green}❯%f"
    else
        prompt_arrow="%F{red}✗%f"
    fi

    local folder
    if [[ "$PWD" == "$HOME" ]]; then
        folder="~"
    elif [[ "$PWD" == "/" ]]; then
        folder=".\\"
    else
        folder=".\\${PWD:t}\\"
    fi

    local git_segment=""
    local branch
    branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
    if [[ -n "$branch" ]]; then
        git_segment="%F{8}|%f %F{yellow}${branch}%f "
    fi

    print ""
    if [[ -n "$elapsed_show" ]]; then
        print -rP "%F{8}╭─%f %F{8}%n%f %F{green}󰝰 ${folder}%f ${git_segment}%F{8}|%f %F{blue}󱎫 ${elapsed_show}%f"
    else
        print -rP "%F{8}╭─%f %F{8}%n%f %F{green}󰝰 ${folder}%f ${git_segment}"
    fi
}

zstyle ':completion:*' menu select
zstyle ':completion::complete:*' gain-privileges 1

# pacman/brew zsh-syntax-highlighting zsh-autosuggestions
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
# source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh

if (( ${+commands[fzf]} )); then
    source <(fzf --zsh)
fi

# zsh-syntax-highlighting must be sourced last, after all other widget/keybinding
# plugins (fzf, autosuggestions), or it can silently stop working.
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
# source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Rebind to Home / End keys
bindkey "^[[H" beginning-of-line
bindkey "^[[F" end-of-line

#bindkey "^[[3~" delete-char

# brew/pacman lsd
alias ls='lsd --group-dirs=first --icon=always -a'
alias l='ls -l'
alias la='ls -a'
alias lla='ls -la'
alias lt='ls --tree'

alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'

PROMPT='%F{8}╰─%f ${prompt_arrow}%f '
RPROMPT='%F{8}%D{%H:%M:%S}%f'

goto() {
    local location="$1"
    case "$location" in
        repo|r)
            cd /home/ccc/git/ || echo "Directory not found"
            ;;
        home|h)
            cd ~ || echo "Directory not found"
            ;;
        *)
            echo "Invalid location"
            ;;
    esac
}

alias g='goto'
