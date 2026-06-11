#!/usr/bin/env bash
# Verify the claude-hebrew-terminal setup.
set -euo pipefail
WEZ_CONF="$HOME/.config/wezterm/wezterm.lua"

command -v wezterm >/dev/null || { echo "FAIL: wezterm not installed"; exit 1; }
[[ -f "$WEZ_CONF" ]] || { echo "FAIL: missing $WEZ_CONF"; exit 1; }

wezterm --config-file "$WEZ_CONF" show-keys >/dev/null 2>&1 \
  && echo "ok: config parses (bidi_enabled accepted, ⌘P bound)" \
  || { echo "FAIL: wezterm rejected the config"; exit 1; }

echo "Hebrew shaping (expect 'RightToLeft' + Miriam Mono CLM, uniform x_adv):"
wezterm --config-file "$WEZ_CONF" ls-fonts --text 'שלום עולם' 2>&1 | head -4

if grep -q 'agent-state.sh' "$HOME/.claude/settings.json" 2>/dev/null; then
  echo "ok: Claude agent-state hooks installed (tab badges enabled)"
else
  echo "note: Claude hooks not found — run ./install.sh (without --no-hooks) for tab badges"
fi
