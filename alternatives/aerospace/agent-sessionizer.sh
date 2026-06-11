#!/usr/bin/env bash
# Fuzzy-pick a git project, then open it here.
#   mode "shell" (default): cd into it and start a shell (prompt shows project+branch)
#   mode "agent"          : cd into it and launch claude
# Bound in AeroSpace: alt-enter -> shell, alt-p -> agent.
set -euo pipefail

mode="${1:-shell}"

roots=("$HOME/PycharmProjects" "$HOME/dev" "$HOME/code" "$HOME/src" "$HOME/projects")
existing=()
for r in "${roots[@]}"; do [ -d "$r" ] && existing+=("$r"); done
[ ${#existing[@]} -eq 0 ] && existing=("$HOME")

proj=$(fd -H -t d -d 3 '^\.git$' "${existing[@]}" 2>/dev/null \
  | sed 's#/\.git/\{0,1\}$##' \
  | sort -u \
  | fzf --prompt="open project ▶ " --height=100% --reverse --border) || exit 0

[ -z "${proj:-}" ] && exit 0
cd "$proj"

name=$(basename "$proj")
branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '-')
clear
printf '\n  \033[1;35m📁 %s\033[0m  \033[2mon\033[0m \033[33m%s\033[0m\n\n' "$name" "$branch"

if [ "$mode" = "agent" ]; then
  exec claude
else
  exec "$SHELL" -l
fi
