HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

setopt HIST_SAVE_NO_DUPS
setopt INC_APPEND_HISTORY

setopt autocd
setopt CORRECT
setopt SHARE_HISTORY

autoload -Uz compinit
compinit

autoload -Uz vcs_info

precmd() { 
    vcs_info
    if [ $timer ]; then
        timer_show=$(($SECONDS - $timer))
        export RPROMPT="%F{blue}󱎫 ${timer_show}s%f"
        unset timer
    fi
}

preexec() {
    timer=$SECONDS
}

setopt prompt_subst
zstyle ':vcs_info:git:*' formats ' %F{magenta}(  %b )%f'
zstyle ':vcs_info:*' enable git

zstyle ':completion:*' menu select
zstyle ':completion::complete:*' gain-privileges 1

# pacman/brew zsh-syntax-highlighting zsh-autosuggestions
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

source <(fzf --zsh)

# Rebind to Home / End keys
bindkey "^[[H" beginning-of-line
bindkey "^[[F" end-of-line

#bindkey "^[[3~" delete-char

alias l='ls -lah --color=auto'
alias ls='ls -GaA --color=auto'
alias ..='cd ..'
alias g='git'
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'

# nvm setup
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

PROMPT='%F{8}╭─%f %F{green}󰉋 %~%f${vcs_info_msg_0_}
%F{8}╰─%f %(?.%F{green}.%F{red})❯%f '
