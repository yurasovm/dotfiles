#!/usr/bin/env bash
# Модуль zsh: oh-my-zsh + плагины + шелл по умолчанию.
set -euo pipefail
. "$DOTFILES_DIR/lib/common.sh"
detect_os

ZSH_DIR="$HOME/.oh-my-zsh"
CUSTOM="${ZSH_CUSTOM:-$ZSH_DIR/custom}"

if [ -d "$ZSH_DIR" ]; then
  log "oh-my-zsh уже установлен."
else
  log "Ставлю oh-my-zsh (unattended)…"
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

clone_plugin() {
  local name="$1" url="$2" dest="$CUSTOM/plugins/$1"
  if [ -d "$dest" ]; then
    git -C "$dest" pull --ff-only --quiet 2>/dev/null || true
  else
    log "Плагин $name…"; git clone --depth=1 "$url" "$dest"
  fi
}
clone_plugin zsh-autosuggestions     https://github.com/zsh-users/zsh-autosuggestions
clone_plugin zsh-syntax-highlighting https://github.com/zsh-users/zsh-syntax-highlighting

# zsh шеллом по умолчанию (если ещё нет)
ZSH_BIN="$(command -v zsh || true)"
if [ -n "$ZSH_BIN" ] && [ "${SHELL:-}" != "$ZSH_BIN" ]; then
  if grep -qx "$ZSH_BIN" /etc/shells 2>/dev/null; then
    log "Делаю zsh шеллом по умолчанию…"
    $SUDO chsh -s "$ZSH_BIN" "$(id -un)" 2>/dev/null || warn "chsh не удался — смени вручную: chsh -s $ZSH_BIN"
  fi
fi
