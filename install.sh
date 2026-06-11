#!/usr/bin/env bash
# claude-hebrew-terminal — one-command setup.
# Hebrew/RTL renders correctly in your terminal, with a cmux-style tabbed
# multi-agent workflow (project picker + live agent-state badges) in WezTerm.
#
#   ./install.sh              # full setup (WezTerm + font + config + Claude hooks)
#   ./install.sh --no-hooks   # skip the Claude Code hooks (no agent-state badges)
set -euo pipefail

note() { printf '\033[1;36m==>\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m ok\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m !!\033[0m %s\n' "$*"; }

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS=1
[[ "${1:-}" == "--no-hooks" ]] && HOOKS=0

[[ "$(uname)" == "Darwin" ]] || { warn "Built for macOS; continuing anyway."; }
command -v brew >/dev/null || { echo "Homebrew required — https://brew.sh"; exit 1; }

note "Installing WezTerm, Miriam Mono CLM (Hebrew font), fd, glow, terminal-notifier…"
brew install --cask wezterm font-miriam-mono-clm
brew install fd glow terminal-notifier

WEZ_DIR="$HOME/.config/wezterm"
mkdir -p "$WEZ_DIR"

# WezTerm config (back up anything we didn't write)
if [[ -f "$WEZ_DIR/wezterm.lua" ]] && ! grep -q "claude-hebrew-terminal" "$WEZ_DIR/wezterm.lua"; then
  cp "$WEZ_DIR/wezterm.lua" "$WEZ_DIR/wezterm.lua.bak.$(date +%s)"
  warn "Existing wezterm.lua backed up — merge any custom settings."
fi
cp "$ROOT/config/wezterm.lua" "$WEZ_DIR/wezterm.lua"
cp "$ROOT/scripts/agent-state.sh" "$WEZ_DIR/agent-state.sh"
chmod +x "$WEZ_DIR/agent-state.sh"
ok "Installed config + helper to $WEZ_DIR"

# Nice notification icon (Claude app icon → png), best-effort.
ICON="$WEZ_DIR/notif-icon.png"
if [[ ! -f "$ICON" ]]; then
  src="$(/usr/bin/find /Applications/Claude.app -name '*.icns' 2>/dev/null | head -1)"
  [[ -z "$src" ]] && src="/Applications/WezTerm.app/Contents/Resources/terminal.icns"
  [[ -f "$src" ]] && sips -s format png "$src" --out "$ICON" -Z 256 >/dev/null 2>&1 \
    && ok "Notification icon set (drop any PNG at $ICON to change it)" || true
fi

# Claude Code hooks → live agent-state badges in the tab strip
if [[ "$HOOKS" == "1" ]]; then
  note "Adding Claude Code agent-state hooks (backed up, merged, non-destructive)…"
  python3 "$ROOT/scripts/merge-claude-hooks.py" "$WEZ_DIR/agent-state.sh"
else
  warn "Skipped Claude hooks (--no-hooks): tabs work, but without agent-state badges."
fi

cat <<'DONE'

────────────────────────────────────────────────────────
Done. Open WezTerm and use it like cmux:

  open -a WezTerm
  ⌘P   pick a project → opens a tab in it (then run `claude`)
  ⌘⇧P  pick a project → opens a tab AND starts claude
  ⌘1-9 jump tabs · ⌘←/→ move · ⌘T new · ⌘W close

Tab badges:  ○ idle   ◐ working   ● needs you
Hebrew/RTL renders correctly in every tab.
(New Claude sessions pick up the badges; existing ones don't.)
────────────────────────────────────────────────────────
DONE
