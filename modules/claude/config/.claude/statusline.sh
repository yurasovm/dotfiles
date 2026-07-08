#!/usr/bin/env bash
# statusline для Claude Code (портируемая версия, python из PATH).
input=$(cat)

PYTHON="$(command -v python3 || true)"; [ -n "$PYTHON" ] || PYTHON="$(command -v python || true)"
[ -n "$PYTHON" ] || PYTHON=/usr/bin/python3
export LC_NUMERIC=C

parse() {
    "$PYTHON" -c "
import sys, json
data = json.loads(sys.stdin.read())
keys = '$1'.split('.')
val = data
for k in keys:
    if isinstance(val, dict):
        val = val.get(k)
    else:
        val = None
        break
print(val if val is not None else '${2:-}')
" <<< "$input"
}

MODEL=$(parse "model.display_name")
DIR=$(parse "workspace.current_dir")
PCT=$(parse "context_window.used_percentage" "0" | cut -d. -f1)
IN_TOK=$(parse "context_window.total_input_tokens" "0")
OUT_TOK=$(parse "context_window.total_output_tokens" "0")
COST=$(parse "cost.total_cost_usd" "0")
FIVE_H=$(parse "rate_limits.five_hour.used_percentage")
WEEK=$(parse "rate_limits.seven_day.used_percentage")

CYAN='\033[36m'; BOLD_CYAN='\033[1;36m'; GREEN='\033[32m'; BOLD_GREEN='\033[1;32m'
BOLD_BLUE='\033[1;34m'; RED='\033[31m'; YELLOW='\033[33m'; DIM='\033[2m'; RESET='\033[0m'

GIT_INFO=""
if git -C "$DIR" rev-parse --git-dir --no-optional-locks > /dev/null 2>&1; then
    BRANCH=$(git -C "$DIR" branch --show-current 2>/dev/null)
    STAGED=$(git -C "$DIR" diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
    MODIFIED=$(git -C "$DIR" diff --numstat 2>/dev/null | wc -l | tr -d ' ')
    UNTRACKED=$(git -C "$DIR" ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')
    DIRTY=""
    [ "$STAGED" -gt 0 ]    && DIRTY="${DIRTY}${GREEN}+${STAGED}${RESET}"
    [ "$MODIFIED" -gt 0 ]  && DIRTY="${DIRTY} ${YELLOW}~${MODIFIED}${RESET}"
    [ "$UNTRACKED" -gt 0 ] && DIRTY="${DIRTY} ${DIM}?${UNTRACKED}${RESET}"
    if [ -n "$DIRTY" ]; then
        GIT_INFO=" ${BOLD_BLUE}git:(${RED}${BRANCH}${BOLD_BLUE}) ${YELLOW}x${RESET} ${DIRTY}"
    else
        GIT_INFO=" ${BOLD_BLUE}git:(${RED}${BRANCH}${BOLD_BLUE})${RESET}"
    fi
fi

LIMITS=""
[ -n "$FIVE_H" ] && [ "$FIVE_H" != "None" ] && LIMITS=" | 5h:$(printf '%.0f' "$FIVE_H")%"
[ -n "$WEEK" ]   && [ "$WEEK" != "None" ]   && LIMITS="${LIMITS} 7d:$(printf '%.0f' "$WEEK")%"

printf '%b\n' "${BOLD_GREEN}➜${RESET}  ${BOLD_CYAN}[${MODEL}]${RESET} ${CYAN}${DIR##*/}${RESET}${GIT_INFO}"

PCT=${PCT:-0}
if [ "$PCT" -ge 90 ]; then BAR_COLOR="$RED"
elif [ "$PCT" -ge 70 ]; then BAR_COLOR="$YELLOW"
else BAR_COLOR="$GREEN"; fi
BAR_WIDTH=20; FILLED=$((PCT * BAR_WIDTH / 100)); EMPTY=$((BAR_WIDTH - FILLED)); BAR=""
[ "$FILLED" -gt 0 ] && printf -v FILL "%${FILLED}s" && BAR="${FILL// /█}"
[ "$EMPTY"  -gt 0 ] && printf -v PAD  "%${EMPTY}s"  && BAR="${BAR}${PAD// /░}"

fmt_tok() { local t=$1; if [ "$t" -ge 1000 ] 2>/dev/null; then awk "BEGIN { printf \"%.1fk\", $t / 1000 }"; else echo "$t"; fi; }
IN_DISP=$(fmt_tok "$IN_TOK"); OUT_DISP=$(fmt_tok "$OUT_TOK")

COST_PART=""
if "$PYTHON" -c "import sys; sys.exit(0 if float('${COST:-0}') > 0.001 else 1)" 2>/dev/null; then
    COST_FMT=$(printf "%.3f" "$COST" 2>/dev/null || echo "$COST")
    COST_PART=" | ${DIM}\$${COST_FMT}${RESET}"
fi

printf '%b\n' "${BAR_COLOR}${BAR}${RESET} ${PCT}%${LIMITS}"
printf '%b\n' "${YELLOW}in:${IN_DISP} out:${OUT_DISP}${RESET}${COST_PART}"
