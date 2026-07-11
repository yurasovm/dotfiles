#!/usr/bin/env bash
# Модуль oxker: TUI для docker-контейнеров (https://github.com/mrjackwills/oxker).
# macOS — через packages.brew (oxker). Linux — prebuilt-бинарь в ~/.local/bin.
# Рантайм: нужен доступ к /var/run/docker.sock (модуль docker ставится в bootstrap).
set -euo pipefail
. "$DOTFILES_DIR/lib/common.sh"
detect_os

export PATH="$HOME/.local/bin:$PATH"

if command -v oxker >/dev/null 2>&1; then
  log "oxker уже установлен: $(oxker --version 2>/dev/null || echo '?')"
  exit 0
fi

if [ "$OS" = "mac" ]; then
  warn "oxker не найден — должен ставиться через brew (packages.brew)."
  exit 0
fi

# Linux: prebuilt-бинарь
case "$(uname -m)" in
  x86_64|amd64)  a="x86_64" ;;
  aarch64|arm64) a="arm64" ;;
  *) die "Неизвестная архитектура: $(uname -m)" ;;
esac
BINDIR="$HOME/.local/bin"; mkdir -p "$BINDIR"
url="https://github.com/mrjackwills/oxker/releases/latest/download/oxker_linux_${a}.tar.gz"
step "Качаю oxker (${a})…" "📥"
tmp="$(mktemp -d)"
dl "$url" "$tmp/oxker.tar.gz" || die "Не удалось скачать oxker."
tar -xzf "$tmp/oxker.tar.gz" -C "$tmp" oxker
install -Dm755 "$tmp/oxker" "$BINDIR/oxker"
rm -rf "$tmp"
step "oxker готов: $("$BINDIR/oxker" --version 2>/dev/null || echo установлен). Запуск: oxker" "✅"
