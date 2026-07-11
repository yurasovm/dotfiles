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

# yazi: обёртка y — при выходе (q) меняет каталог шелла на текущий в yazi.
# ВАЖНО: плагин yarn задаёт `alias y='yarn'`. Снимаем его ОТДЕЛЬНОЙ строкой до
# определения функции — иначе zsh раскроет алиас при разборе (parse error).
# unalias вне if: чтобы выполнился раньше, чем zsh прочитает тело функции.
unalias y 2>/dev/null || true
if command -v yazi >/dev/null 2>&1; then
  y() {
    local tmp cwd
    tmp="$(mktemp -t yazi-cwd.XXXXXX)"
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
      builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
  }
fi

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
