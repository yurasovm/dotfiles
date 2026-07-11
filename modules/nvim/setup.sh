#!/usr/bin/env bash
# Модуль nvim: свежий Neovim (Linux — tarball), stylua, web-LSP, headless-синк плагинов.
# Конфиг линкуется через stow (config/.config/nvim). Здесь — только бинарники/инструменты.
set -euo pipefail
. "$DOTFILES_DIR/lib/common.sh"
detect_os

# --- Neovim ----------------------------------------------------------------
if [ "$OS" = "linux" ]; then
  # Свежие релизы Neovim собираются на Ubuntu 22.04 и требуют glibc >= 2.34.
  # На старых системах (напр. Ubuntu 20.04 = glibc 2.31) prebuilt-бинарь падает
  # с 'GLIBC_2.xx not found', а musl-сборки у Neovim нет. Честно пропускаем.
  if ! glibc_atleast 2 34; then
    warn "nvim пропущен: нужен glibc ≥ 2.34, в системе — $(glibc_version 2>/dev/null || echo '?')."
    warn "Prebuilt-бинарь Neovim тут не запустится. Варианты: обновить ОС или собрать nvim из исходников вручную."
    if command -v nvim >/dev/null 2>&1 && ! nvim --version >/dev/null 2>&1; then
      warn "Найден нерабочий nvim от прошлой попытки — удали: \$SUDO rm -f /usr/local/bin/nvim && \$SUDO rm -rf /opt/nvim"
    fi
    exit 0
  fi
  # apt-версия старая → ставим официальный tarball в /opt/nvim
  arch="$(uname -m)"
  case "$arch" in
    x86_64|amd64)  tb="nvim-linux-x86_64.tar.gz" ;;
    aarch64|arm64) tb="nvim-linux-arm64.tar.gz" ;;
    *) die "Неизвестная архитектура: $arch" ;;
  esac
  step "Качаю Neovim ($tb) → /opt/nvim…" "📥"
  tmp="$(mktemp -d)"
  dl "https://github.com/neovim/neovim/releases/latest/download/${tb}" "$tmp/nvim.tar.gz" \
    || die "Не удалось скачать Neovim."
  $SUDO rm -rf /opt/nvim && $SUDO mkdir -p /opt/nvim
  $SUDO tar -xzf "$tmp/nvim.tar.gz" -C /opt/nvim --strip-components=1
  $SUDO ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim
  rm -rf "$tmp"

  # stylua (форматтер lua)
  if ! command -v stylua >/dev/null 2>&1; then
    case "$arch" in x86_64|amd64) sa="linux-x86_64" ;; aarch64|arm64) sa="linux-aarch64" ;; *) sa="" ;; esac
    if [ -n "$sa" ]; then
      tmp="$(mktemp -d)"
      if dl "https://github.com/JohnnyMorganz/StyLua/releases/latest/download/stylua-${sa}.zip" "$tmp/s.zip"; then
        unzip -q "$tmp/s.zip" -d "$tmp" && $SUDO install -m755 "$tmp/stylua" /usr/local/bin/stylua
      else
        warn "stylua не скачался — форматирование lua недоступно."
      fi
      rm -rf "$tmp"
    fi
  fi

  # fd симлинк (в Debian бинарь — fdfind)
  if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
    $SUDO ln -sf "$(command -v fdfind)" /usr/local/bin/fd
  fi
fi
# на macOS neovim/ripgrep/fd/jq/node/stylua ставятся через packages.brew

NVIM_BIN="$(command -v nvim || echo /usr/local/bin/nvim)"
log "Neovim: $($NVIM_BIN --version | head -1)"

# --- Web LSP (html/css/tailwind) — опционально -----------------------------
if command -v npm >/dev/null 2>&1; then
  log "Языковые серверы web (html/css/tailwind)…"
  npm_sudo=""; [ "$OS" = "linux" ] && npm_sudo="$SUDO"
  $npm_sudo npm install -g vscode-langservers-extracted @tailwindcss/language-server >/dev/null 2>&1 \
    || warn "web-LSP через npm не установились (не критично)."
fi

# --- Синк плагинов (headless) — конфиг уже слинкован install'ом ------------
step "Ставлю плагины (lazy sync, headless — может занять минуту, без прогресса)…" "🔌"
with_timeout 300 "$NVIM_BIN" --headless "+Lazy! sync" +qa 2>/dev/null \
  || warn "Автосинк плагинов не завершился — доустановятся при первом запуске nvim."
step "treesitter-парсеры докачаются при первом запуске nvim." "ℹ️ "
