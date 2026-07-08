#!/usr/bin/env bash
# dotfiles/lib/picker.sh — интерактивный мультивыбор модулей.
# UI рисуется в stderr; итоговый список печатается в stdout (для перехвата).
# Требует: module_desc (из modules.sh), цвета/логи (из common.sh).

# pick_modules "предвыбор" mod1 mod2 …   → печатает выбранные (через пробел) в stdout
pick_modules() {
  local pre="$1"; shift
  local names=("$@")
  local n=${#names[@]} i cur=0
  local CHECKED=()
  for ((i=0; i<n; i++)); do
    case " $pre " in *" ${names[i]} "*) CHECKED[i]=1 ;; *) CHECKED[i]=0 ;; esac
  done

  # без tty — просто вернуть предвыбор (пересечение с кандидатами)
  if ! { [ -t 0 ] && [ -t 2 ]; }; then
    local out=""
    for ((i=0; i<n; i++)); do [ "${CHECKED[i]}" -eq 1 ] && out="$out ${names[i]}"; done
    printf '%s' "${out# }"
    return 0
  fi

  local lines=$((n + 3)) drawn=0
  _pdraw() {
    [ "$drawn" -eq 1 ] && printf '\033[%dA' "$lines" >&2
    drawn=1
    printf '\033[K%bВыбор модулей%b\n' "$c_bold" "$c_rst" >&2
    printf '\033[K%b  ↑/↓ или j/k · Пробел — вкл/выкл · a — все · d — сброс · Enter — ок · q — выход%b\n' "$c_dim" "$c_rst" >&2
    printf '\033[K\n' >&2
    for ((i=0; i<n; i++)); do
      local box='[ ]'; [ "${CHECKED[i]}" -eq 1 ] && box='[x]'
      local ptr='  ';   [ "$i" -eq "$cur" ] && ptr='➜ '
      if [ "$i" -eq "$cur" ]; then
        printf '\033[K%b%s%s %-8s%b %b%s%b\n' "$c_blue" "$ptr" "$box" "${names[i]}" "$c_rst" "$c_dim" "$(module_desc "${names[i]}")" "$c_rst" >&2
      else
        printf '\033[K%s%s %-8s %b%s%b\n' "$ptr" "$box" "${names[i]}" "$c_dim" "$(module_desc "${names[i]}")" "$c_rst" >&2
      fi
    done
  }

  _pdraw
  local key rest
  while true; do
    IFS= read -rsn1 key || break
    if [ "$key" = $'\033' ]; then IFS= read -rsn2 rest 2>/dev/null || rest=''; key="$key$rest"; fi
    case "$key" in
      $'\033[A'|k) cur=$(( (cur - 1 + n) % n )) ;;
      $'\033[B'|j) cur=$(( (cur + 1) % n )) ;;
      ' ')         CHECKED[cur]=$(( 1 - CHECKED[cur] )) ;;
      a|A)         for ((i=0; i<n; i++)); do CHECKED[i]=1; done ;;
      d|D)         for ((i=0; i<n; i++)); do CHECKED[i]=0; done ;;
      ''|$'\n'|$'\r') break ;;
      q|Q)         printf '\n' >&2; die "Отменено." ;;
    esac
    _pdraw
  done
  printf '\n' >&2

  local out=""
  for ((i=0; i<n; i++)); do [ "${CHECKED[i]}" -eq 1 ] && out="$out ${names[i]}"; done
  printf '%s' "${out# }"
}
