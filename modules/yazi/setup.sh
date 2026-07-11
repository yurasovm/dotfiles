#!/usr/bin/env bash
# Модуль yazi: TUI-файловый менеджер (https://github.com/sxyazi/yazi).
# macOS — через packages.brew (yazi). Linux — prebuilt-бинари в ~/.local/bin.
# Ставятся оба бинаря релиза: yazi (сам менеджер) и ya (CLI/плагины).
set -euo pipefail
. "$DOTFILES_DIR/lib/common.sh"
detect_os

export PATH="$HOME/.local/bin:$PATH"

if command -v yazi >/dev/null 2>&1; then
  log "yazi уже установлен: $(yazi --version 2>/dev/null || echo '?')"
  exit 0
fi

if [ "$OS" = "mac" ]; then
  warn "yazi не найден — должен ставиться через brew (packages.brew)."
  exit 0
fi

# Linux: prebuilt-бинари (glibc)
case "$(uname -m)" in
  x86_64|amd64)  target="x86_64-unknown-linux-gnu" ;;
  aarch64|arm64) target="aarch64-unknown-linux-gnu" ;;
  *) die "Неизвестная архитектура: $(uname -m)" ;;
esac

command -v unzip >/dev/null 2>&1 || { log "Ставлю unzip…"; $SUDO apt-get update -y && apt_install unzip; }

BINDIR="$HOME/.local/bin"; mkdir -p "$BINDIR"
url="https://github.com/sxyazi/yazi/releases/latest/download/yazi-${target}.zip"
step "Качаю yazi (${target})…" "📥"
tmp="$(mktemp -d)"
dl "$url" "$tmp/yazi.zip" || die "Не удалось скачать yazi."
unzip -q "$tmp/yazi.zip" -d "$tmp" || die "Не удалось распаковать yazi."
for bin in yazi ya; do
  src="$(find "$tmp" -type f -name "$bin" 2>/dev/null | head -1)"
  [ -n "$src" ] || die "В релизе не найден бинарь '$bin'."
  install -Dm755 "$src" "$BINDIR/$bin"
done
rm -rf "$tmp"
step "yazi готов: $("$BINDIR/yazi" --version 2>/dev/null || echo установлен). Запуск: yazi (или обёртка y)" "✅"
