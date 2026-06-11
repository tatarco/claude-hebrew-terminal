#!/usr/bin/env bash
# Record a Claude session's state so WezTerm can badge its tab (cmux-style).
# Called from Claude Code hooks. Keyed by the WezTerm pane id ($WEZTERM_PANE),
# so each tab maps to its own agent. No-op outside WezTerm (e.g. in cmux/tmux).
state="${1:-idle}"
pane="${WEZTERM_PANE:-}"
[ -z "$pane" ] && exit 0
dir="/tmp/wezterm-agent-state"
mkdir -p "$dir" 2>/dev/null || true
printf '%s' "$state" > "$dir/$pane" 2>/dev/null || true
exit 0
