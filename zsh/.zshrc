# ========================================
# Shell Options and History Configuration
# ========================================

# Set history size and save size
HISTFILE=~/.history
HISTSIZE=100000
SAVEHIST=100000
# Save each command right after it's run
setopt inc_append_history


# =======================
# Aliases and Shortcuts
# =======================

alias v='nvim'
alias o='xdg-open'
alias g='git'

alias ls='ls --color=auto -hv'
alias grep='grep --color=auto'
alias diff='diff --color=auto'
alias ip='ip -c=auto'

alias l='ls'
alias ll='ls -l'
alias la='ls -lA'
alias mv='mv -i'


# ===========================
# Key Bindings (Vim + Search)
# ===========================

bindkey "\e[A" history-beginning-search-backward
bindkey "\e[B" history-beginning-search-forward

# Enable Vim mode
bindkey -v


# ====================
# Terminal Appearance
# ====================

# Set terminal window title to current path
precmd () { print -Pn "\e]2;%-3~\a"; }

# Show logo on startup (only for top-level shells)
if [[ $SHLVL -le 1 ]]; then
  fastfetch --logo small
fi

# Oh My Zsh
# Only load Oh My Zsh if available
export ZSH="$HOME/.oh-my-zsh"
if [ -d "$ZSH" ]; then
  ZSH_THEME="simple"
  plugins=(git zsh-syntax-highlighting zsh-autosuggestions zsh-vi-mode)
  source $ZSH/oh-my-zsh.sh
fi

# =================================
# Completions and Autoloads
# =================================

# Initialize Zsh's completion system
export PATH="$HOME/.local/bin:$PATH"
autoload -Uz compinit
compinit

# .NET CLI Completion 
export PATH="$PATH:/home/yarlaw/.dotnet/tools"

_dotnet_zsh_complete() {
  local completions=("$(dotnet complete "$words")")

  if [ -z "$completions" ]; then
    _arguments '*::arguments: _normal'
    return
  fi

  _values "${(ps:\n:)completions}"
}
compdef _dotnet_zsh_complete dotnet

# Angular CLI autocompletion
source <(ng completion script)

# Terraform completion (requires bashcompinit)
autoload -U +X bashcompinit && bashcompinit
complete -o nospace -C /usr/bin/terraform terraform

# NVM (Node Version Manager)
# Load NVM if it exists
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"


# Conda (Python)
# !! Contents within this block are managed by 'conda init' !!
# >>> conda initialize >>>
__conda_setup="$('/home/yarlaw/SDK/anaconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/yarlaw/SDK/anaconda3/etc/profile.d/conda.sh" ]; then
        . "/home/yarlaw/SDK/anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="/home/yarlaw/SDK/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<< 


# =================================
# System-Specific Configuration
# =================================

# Cosmic DE: Disable IBus input method modules to fix issues
unset QT_IM_MODULE
unset GTK_IM_MODULE
