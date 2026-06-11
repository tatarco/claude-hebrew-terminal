#!/usr/bin/env bash
set -euo pipefail

# Verify the WezTerm Hebrew/RTL setup.
WEZ_CONF="$HOME/.config/wezterm/wezterm.lua"

command -v wezterm >/dev/null || { echo "FAIL: wezterm not installed"; exit 1; }
[[ -f "$WEZ_CONF" ]] || { echo "FAIL: missing $WEZ_CONF"; exit 1; }

if wezterm --config-file "$WEZ_CONF" show-keys >/dev/null 2>&1; then
  echo "ok: config parses (bidi_enabled accepted)"
else
  echo "FAIL: wezterm rejected the config"; exit 1
fi

echo "Hebrew shaping (expect 'RightToLeft' and Miriam Mono CLM with uniform x_adv):"
wezterm --config-file "$WEZ_CONF" ls-fonts --text 'שלום עולם' 2>&1 | head -4
