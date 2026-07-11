#!/usr/bin/env bash
# dotfiles/lib/common.sh — общие функции (логи, ОС, пакеты, stow-линковка).
# Совместимо с bash 3.2 (macOS) и bash 5 (Linux).

c_blue='\033[1;34m'; c_green='\033[1;32m'; c_yellow='\033[1;33m'; c_red='\033[1;31m'
c_dim='\033[2m'; c_bold='\033[1m'; c_rst='\033[0m'
log()  { printf "${c_blue}▸${c_rst} %s\n" "$*" >&2; }
ok()   { printf "${c_green}✓${c_rst} %s\n" "$*" >&2; }
warn() { printf "${c_yellow}⚠${c_rst}  %s\n" "$*" >&2; }
die()  { printf "${c_red}✗ %s${c_rst}\n" "$*" >&2; exit 1; }

# --- Презентация / прогресс ------------------------------------------------
have_tty() { [ -t 2 ]; }                     # stderr — терминал? (для прогресс-баров)

# Заголовок модуля: hdr <i> <n> <имя> [описание]
hdr()  { printf "\n${c_bold}${c_blue}📦 [%s/%s] %s${c_rst}  ${c_dim}%s${c_rst}\n" "$1" "$2" "$3" "${4:-}" >&2; }
# Под-шаг внутри модуля: step <текст> [emoji]
step() { printf "   ${2:-·} %s\n" "$1" >&2; }

# Скачать файл: прогресс-бар в терминале, иначе тихо; с таймаутами и ретраями.
#   dl <url> <out>
dl() {
  local pv="--silent --show-error"
  have_tty && pv="--progress-bar"
  # shellcheck disable=SC2086
  curl -fL $pv --connect-timeout 15 --retry 2 --retry-delay 2 "$1" -o "$2"
}

# Выполнить команду с общим таймаутом (если есть coreutils timeout).
#   with_timeout <секунды> <команда...>   → код 124 при истечении времени
with_timeout() {
  local t="$1"; shift
  if command -v timeout >/dev/null 2>&1; then timeout "$t" "$@"; else "$@"; fi
}

# --- Совместимость системы -------------------------------------------------
# Версия glibc, напр. "2.31" (пусто, если musl/не определить).
glibc_version() {
  local v
  v="$(getconf GNU_LIBC_VERSION 2>/dev/null)" || v=""
  case "$v" in
    glibc\ *) printf '%s' "${v#glibc }" ;;
    *)        ldd --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+' | tail -1 ;;
  esac
}
# glibc >= X.Y ?  0 — да (или версию не определить — не блокируем), 1 — старее.
glibc_atleast() {
  local want_ma="$1" want_mi="$2" v ma mi
  v="$(glibc_version)"; [ -n "$v" ] || return 0
  ma="${v%%.*}"; mi="${v#*.}"; mi="${mi%%.*}"
  [ "$ma" -gt "$want_ma" ] && return 0
  [ "$ma" -lt "$want_ma" ] && return 1
  [ "$mi" -ge "$want_mi" ]
}

# --- ОС: OS = mac | linux --------------------------------------------------
detect_os() {
  case "$(uname -s)" in
    Darwin) OS=mac ;;
    Linux)  OS=linux ;;
    *) die "Неподдерживаемая ОС: $(uname -s)" ;;
  esac
}

SUDO=""
[ "$(id -u)" -eq 0 ] 2>/dev/null || SUDO="sudo"

# Пользовательские бинари (yazi, oxker, herdr…) ставятся сюда — чтобы install,
# probe и --status видели их независимо от того, из bash или zsh запущен скрипт.
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) PATH="$HOME/.local/bin:$PATH" ;; esac
export PATH

# --- Установка пакетов -----------------------------------------------------
# apt_install pkg…   /   brew_install pkg…
apt_install() {
  [ "$#" -gt 0 ] || return 0
  export DEBIAN_FRONTEND=noninteractive
  $SUDO apt-get install -y --no-install-recommends "$@"
}
brew_install() {
  [ "$#" -gt 0 ] || return 0
  brew install "$@"
}

# Установить пакеты модуля из packages.apt / packages.brew (по одной строке на пакет)
install_packages_for() {
  local mdir="$1" file pkgs
  case "$OS" in
    linux) file="$mdir/packages.apt" ;;
    mac)   file="$mdir/packages.brew" ;;
  esac
  [ -f "$file" ] || return 0
  # собрать непустые, некомментированные строки
  pkgs="$(grep -vE '^\s*(#|$)' "$file" 2>/dev/null | tr '\n' ' ')"
  [ -n "$pkgs" ] || return 0
  log "Пакеты ($OS): $pkgs"
  # shellcheck disable=SC2086
  case "$OS" in
    linux) apt_install $pkgs ;;
    mac)   brew_install $pkgs ;;
  esac
}

# --- stow --------------------------------------------------------------------
ensure_stow() {
  command -v stow >/dev/null 2>&1 && return 0
  log "Ставлю stow…"
  case "$OS" in
    linux) $SUDO apt-get update -y && apt_install stow ;;
    mac)   brew_install stow ;;
  esac
  command -v stow >/dev/null 2>&1 || die "Не удалось установить stow."
}

# Слинковать config/ модуля в $HOME. Конфликтующие реальные файлы — в бэкап.
stow_module() {
  local mdir="$1" pkg="$1/config"
  [ -d "$pkg" ] || return 0          # config-less модуль — нечего линковать
  # бэкап реальных (не-symlink) файлов, которые перекрыл бы stow
  local rel tgt
  while IFS= read -r rel; do
    rel="${rel#./}"
    tgt="$HOME/$rel"
    if [ -e "$tgt" ] && [ ! -L "$tgt" ]; then
      mv "$tgt" "$tgt.pre-dotfiles.bak"
      warn "Бэкап: ~/$rel → ~/$rel.pre-dotfiles.bak"
    fi
  done < <(cd "$pkg" && find . \( -type f -o -type l \))
  stow -d "$mdir" -t "$HOME" --restow config
}

# Отвязать config/ модуля
unstow_module() {
  local mdir="$1"
  [ -d "$mdir/config" ] || return 0
  stow -d "$mdir" -t "$HOME" -D config 2>/dev/null || true
}
