#!/usr/bin/env bash
# Модуль zsh: oh-my-zsh + плагины + шелл по умолчанию.
set -euo pipefail
. "$DOTFILES_DIR/lib/common.sh"
detect_os

ZSH_DIR="$HOME/.oh-my-zsh"
CUSTOM="${ZSH_CUSTOM:-$ZSH_DIR/custom}"

if [ -d "$ZSH_DIR" ]; then
  step "oh-my-zsh уже установлен." "✓"
else
  step "Ставлю oh-my-zsh (unattended, до 2 мин)…" "📥"
  # скачиваем установщик с таймаутом, затем запускаем (curl|sh мог бы висеть вечно)
  omz="$(with_timeout 120 curl -fsSL --connect-timeout 15 \
        https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || true
  if [ -n "$omz" ]; then
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$omz" \
      || warn "oh-my-zsh: установщик завершился с ошибкой (конфиг всё равно слинкован)."
  else
    warn "oh-my-zsh: не скачался (таймаут/сеть) — тема/плагины будут недоступны до повторной установки."
  fi
fi

clone_plugin() {
  local name="$1" url="$2" dest="$CUSTOM/plugins/$1"
  if [ -d "$dest" ]; then
    git -C "$dest" pull --ff-only --quiet 2>/dev/null || true
  else
    step "Плагин $name…" "🔌"; git clone --depth=1 "$url" "$dest"
  fi
}
clone_plugin zsh-autosuggestions     https://github.com/zsh-users/zsh-autosuggestions
clone_plugin zsh-syntax-highlighting https://github.com/zsh-users/zsh-syntax-highlighting

# --- zsh как логин-шелл ----------------------------------------------------
ZSH_BIN="$(command -v zsh || true)"
if [ -z "$ZSH_BIN" ]; then
  warn "zsh не найден в PATH — пакет zsh не установился?"
elif [ "$(basename "${SHELL:-}")" = zsh ]; then
  step "zsh уже логин-шелл." "✓"
elif grep -qx "$ZSH_BIN" /etc/shells 2>/dev/null; then
  if $SUDO chsh -s "$ZSH_BIN" "$(id -un)" 2>/dev/null; then
    step "zsh назначен логин-шеллom — вступит в силу при СЛЕДУЮЩЕМ входе (сейчас: $(basename "${SHELL:-?}"))." "🔀"
  else
    warn "chsh не удался. Смени вручную:  chsh -s $ZSH_BIN   (или запусти сразу: exec zsh)"
  fi
else
  warn "$ZSH_BIN нет в /etc/shells — автоназначение логин-шелла пропущено. Запусти сразу: exec zsh"
fi
