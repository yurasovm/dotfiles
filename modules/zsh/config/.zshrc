# ~/.zshrc — управляется dotfiles (модуль zsh). Машинно-специфичное → ~/.zshrc.local

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"

plugins=(
	git
	npm
	yarn
	zsh-autosuggestions
	zsh-syntax-highlighting
)
source "$ZSH/oh-my-zsh.sh"

# --- Общее -----------------------------------------------------------------
export LANG=en_US.UTF-8
export EDITOR='nvim'
export VISUAL='nvim'
export PATH="$HOME/.local/bin:$PATH"

alias vim='nvim'
alias vi='nvim'
alias dc='docker compose'
alias dps='docker ps'

# --- По ОС -----------------------------------------------------------------
if [[ "$OSTYPE" == darwin* ]]; then
  # macOS
  [ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
else
  # Linux
  [ -d /opt/nvim/bin ] && export PATH="/opt/nvim/bin:$PATH"
fi

# --- Локальное (секреты, host-specific) — не в гите ------------------------
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"
