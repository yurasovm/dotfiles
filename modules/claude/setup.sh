#!/usr/bin/env bash
# Модуль claude: установка Claude Code CLI. Конфиг (settings/statusline) линкует stow.
set -euo pipefail
. "$DOTFILES_DIR/lib/common.sh"
detect_os

if command -v claude >/dev/null 2>&1; then
  log "Claude Code уже установлен: $(claude --version 2>/dev/null || echo '?')"
else
  log "Ставлю Claude Code (официальный установщик)…"
  if ! curl -fsSL https://claude.ai/install.sh | bash; then
    warn "install.sh не сработал — пробую npm."
    command -v npm >/dev/null 2>&1 || die "Нет npm для fallback. Установи Node.js или Claude вручную."
    npm_sudo=""; [ "$OS" = "linux" ] && npm_sudo="$SUDO"
    $npm_sudo npm install -g @anthropic-ai/claude-code
  fi
fi

# statusline должен быть исполняемым (chmod идёт по симлинку на реальный файл в репе)
chmod +x "$HOME/.claude/statusline.sh" 2>/dev/null || true
log "Готово. Запусти 'claude' и авторизуйся (/login)."
