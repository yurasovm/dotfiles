#!/usr/bin/env bash
# dotfiles/lib/modules.sh — каталог модулей, парсинг module.conf, deps, профили.
# Требует: MODULES_DIR, PROFILES_DIR, OS.

# module.conf — sourceable: desc, platforms, deps, default, probe
#   probe — команда-проверка «установлен ли модуль» (код 0 = да), напр. probe="command -v yazi"
_load_conf() {
  desc=""; platforms="mac linux"; deps=""; default="off"; probe=""
  # shellcheck disable=SC1090
  [ -f "$MODULES_DIR/$1/module.conf" ] && . "$MODULES_DIR/$1/module.conf"
}
module_desc()    { ( _load_conf "$1"; printf '%s' "$desc"; ); }
module_plats()   { ( _load_conf "$1"; printf '%s' "$platforms"; ); }
module_deps()    { ( _load_conf "$1"; printf '%s' "$deps"; ); }
module_default() { ( _load_conf "$1"; printf '%s' "$default"; ); }
module_probe()   { ( _load_conf "$1"; printf '%s' "$probe"; ); }

# Проверить, установлен ли модуль (по его probe).
#   0 — установлен | 1 — нет | 2 — probe не задан
module_installed() {
  local p; p="$(module_probe "$1")"
  [ -n "$p" ] || return 2
  eval "$p" >/dev/null 2>&1
}

module_exists() { [ -d "$MODULES_DIR/$1" ]; }

# Все модули (по алфавиту)
list_modules() { ls -1 "$MODULES_DIR" 2>/dev/null; }

# Совместим ли модуль с текущей ОС
platform_ok() {
  local p; p="$(module_plats "$1")"
  [ -z "$p" ] && return 0
  case " $p " in *" $OS "*) return 0 ;; *) return 1 ;; esac
}

# Модули, дефолтно включённые (default=on) и совместимые с ОС
default_modules() {
  local m out=""
  for m in $(list_modules); do
    platform_ok "$m" || continue
    [ "$(module_default "$m")" = "on" ] && out="$out $m"
  done
  printf '%s' "${out# }"
}

# Транзитивно раскрыть зависимости (deps раньше зависящего), дедуп
_dep_seen=""
_resolve_one() {
  case " $_dep_seen " in *" $1 "*) return ;; esac
  local d
  for d in $(module_deps "$1"); do _resolve_one "$d"; done
  _dep_seen="$_dep_seen $1"
}
resolve_deps() {
  _dep_seen=""; local m
  for m in "$@"; do
    module_exists "$m" || die "Неизвестный модуль: '$m' (есть: $(list_modules | tr '\n' ' '))."
    _resolve_one "$m"
  done
  printf '%s' "${_dep_seen# }"
}

# Профиль → список модулей
expand_profile() {
  local f="$PROFILES_DIR/$1"
  [ -f "$f" ] || die "Нет профиля '$1' ($f). Есть: $(ls -1 "$PROFILES_DIR" 2>/dev/null | tr '\n' ' ')"
  grep -vE '^[[:space:]]*(#|$)' "$f" | tr '\n' ' '
}
