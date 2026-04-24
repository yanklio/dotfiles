# Enable Vim mode first, then re-apply custom bindings on top
bindkey -v
bindkey "\e[A" history-beginning-search-backward
bindkey "\e[B" history-beginning-search-forward

# Terminal Appearance: Set title to current path
_set_terminal_title() { print -Pn "\e]2;%-3~\a" }
precmd_functions+=(_set_terminal_title)

# Show logo on startup (only for top-level shells)
if [[ $SHLVL -le 1 ]] && command -v fastfetch >/dev/null 2>&1; then
  fastfetch
fi

# Add local bin to path
export PATH="$HOME/.local/bin:$PATH"

if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh --cmd cd)"
fi

# Prompt/theme via oh-my-zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="simple"
plugins=(git)

if [[ -r "$ZSH/oh-my-zsh.sh" ]]; then
  source "$ZSH/oh-my-zsh.sh"
else
  autoload -Uz compinit
  compinit
fi

if [[ -r /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
  source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

if [[ -r /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
  source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# Aliases
alias v="nvim"
alias o="xdg-open"
alias g="git"
alias grep="grep --color=auto"
alias diff="diff --color=auto"
alias ip="ip -c=auto"
alias mv="mv -i"

if command -v eza >/dev/null 2>&1; then
  alias ls="eza"
  alias l="eza"
  alias ll="eza -l"
  alias la="eza -lA"
else
  alias l="ls"
  alias ll="ls -l"
  alias la="ls -lA"
fi

# History
HISTSIZE=100000
SAVEHIST=100000
HISTFILE=~/.history

# Editor
export EDITOR="nvim"
export VISUAL="nvim"
