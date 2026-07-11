#!/usr/bin/env bash
# Модуль herdr: agent multiplexer (https://github.com/ogulcancelik/herdr).
# macOS — через packages.brew (herdr). Linux — официальный скрипт herdr.dev/install.sh,
# обёрнутый в таймаут: чтобы не висеть вечно, если сеть/сайт недоступны.
set -euo pipefail
. "$DOTFILES_DIR/lib/common.sh"
detect_os

export PATH="$HOME/.local/bin:$HOME/.herdr/bin:$PATH"

if command -v herdr >/dev/null 2>&1; then
  step "herdr уже установлен: $(herdr --version 2>/dev/null || echo '?')" "✓"
  exit 0
fi

if [ "$OS" != "linux" ]; then
  warn "herdr не найден — на macOS ставится через brew (packages.brew)."
  exit 0
fi

step "Ставлю herdr (herdr.dev/install.sh, до 5 мин — тянет бинарь)…" "📥"
rc=0
with_timeout 300 sh -c 'curl -fsSL --connect-timeout 15 --retry 2 https://herdr.dev/install.sh | sh' || rc=$?

hash -r 2>/dev/null || true
if command -v herdr >/dev/null 2>&1; then
  step "herdr установлен: $(herdr --version 2>/dev/null || echo ок)" "✅"
  exit 0
fi

# Не установился — сообщаем причину и НЕ валим остальную установку (herdr опционален).
if [ "$rc" -eq 124 ]; then
  warn "herdr: таймаут 5 мин (herdr.dev/сеть недоступны) — пропускаю."
elif [ "$rc" -ne 0 ]; then
  warn "herdr: установщик завершился с ошибкой (код $rc) — пропускаю."
else
  warn "herdr: скрипт отработал, но бинарь не в PATH — подхватится после нового входа."
fi
warn "Поставить позже вручную:  curl -fsSL https://herdr.dev/install.sh | sh"
exit 0
