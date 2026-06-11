#!/usr/bin/env bash
# Record a Claude session's state so WezTerm can badge its tab (cmux-style),
# and on "needs-input" fire a clickable macOS notification whose "Show" button
# focuses the EXACT WezTerm tab that's waiting.
#
# Called from Claude Code hooks. Keyed by the WezTerm pane id ($WEZTERM_PANE),
# so each tab maps to its own agent. No-op outside WezTerm (e.g. in cmux/tmux).
state="${1:-idle}"
pane="${WEZTERM_PANE:-}"
[ -z "$pane" ] && exit 0

dir="/tmp/wezterm-agent-state"
mkdir -p "$dir" 2>/dev/null || true
printf '%s' "$state" > "$dir/$pane" 2>/dev/null || true

# On "needs you", post an actionable notification that focuses this tab on click.
if [ "$state" = "needs-input" ] && command -v terminal-notifier >/dev/null 2>&1; then
  text="Claude is waiting for your input"
  if [ ! -t 0 ]; then                     # read the hook's stdin JSON, if piped
    payload=$(cat 2>/dev/null || true)
    parsed=$(printf '%s' "$payload" | python3 -c 'import sys,json
try: print(json.load(sys.stdin).get("message") or "")
except Exception: print("")' 2>/dev/null)
    [ -n "$parsed" ] && text="$parsed"
  fi
  proj=$(basename "$PWD")
  wez=wezterm
  for w in /opt/homebrew/bin/wezterm /usr/local/bin/wezterm /usr/bin/wezterm; do
    [ -x "$w" ] && { wez="$w"; break; }
  done
  terminal-notifier \
    -title "Claude Code" \
    -subtitle "$proj" \
    -message "$text" \
    -actions Show \
    -timeout 30 \
    -group "wezterm-agent-$pane" \
    -execute "$wez cli activate-pane --pane-id $pane >/dev/null 2>&1; open -a WezTerm" \
    >/dev/null 2>&1 &
fi
exit 0
