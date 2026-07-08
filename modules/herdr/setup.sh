#!/usr/bin/env bash
# Модуль herdr: agent multiplexer (https://github.com/ogulcancelik/herdr).
# macOS — ставится через packages.brew (herdr). Linux — официальный скрипт.
set -euo pipefail
. "$DOTFILES_DIR/lib/common.sh"
detect_os

export PATH="$HOME/.local/bin:$HOME/.herdr/bin:$PATH"

if command -v herdr >/dev/null 2>&1; then
  log "herdr уже установлен: $(herdr --version 2>/dev/null || echo '?')"
  exit 0
fi

if [ "$OS" = "linux" ]; then
  log "Ставлю herdr (herdr.dev/install.sh)…"
  curl -fsSL https://herdr.dev/install.sh | sh || die "Установщик herdr завершился с ошибкой."
  command -v herdr >/dev/null 2>&1 \
    && log "Готово: $(herdr --version 2>/dev/null || echo установлен)" \
    || warn "herdr поставлен, но не в PATH текущей сессии (подхватится после входа)."
else
  warn "herdr не найден — должен был поставиться через brew (packages.brew)."
fi
