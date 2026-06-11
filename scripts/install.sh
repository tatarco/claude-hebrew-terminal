#!/usr/bin/env bash
set -euo pipefail

# claude-hebrew-terminal installer.
# Sets up WezTerm with BiDi + a monospace Hebrew font so Hebrew/RTL text renders
# correctly in Claude Code and other terminal UIs.
#
# Usage:
#   ./install.sh                 # install + configure WezTerm
#   ./install.sh --prestage-cmux # also add a Hebrew fallback font to ghostty/cmux
#                                 # (harmless today; useful once ghostty ships BiDi)

note() { printf '\033[1;36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m  %s\n' "$*"; }
ok()   { printf '\033[1;32mok\033[0m  %s\n' "$*"; }

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PRESTAGE_CMUX=0
[[ "${1:-}" == "--prestage-cmux" ]] && PRESTAGE_CMUX=1

[[ "$(uname)" == "Darwin" ]] || warn "This installer targets macOS; continuing anyway."
command -v brew >/dev/null || { echo "Homebrew required: https://brew.sh"; exit 1; }

note "Installing WezTerm + Miriam Mono CLM (Hebrew monospace font)…"
brew install --cask wezterm font-miriam-mono-clm

# --- WezTerm config (back up anything we didn't write) ---
WEZ_DIR="$HOME/.config/wezterm"
WEZ_CONF="$WEZ_DIR/wezterm.lua"
mkdir -p "$WEZ_DIR"
if [[ -f "$WEZ_CONF" ]] && ! grep -q "claude-hebrew-terminal" "$WEZ_CONF"; then
  cp "$WEZ_CONF" "$WEZ_CONF.bak.$(date +%s)"
  warn "Existing wezterm.lua backed up (*.bak.*); merge custom settings if needed."
fi
cp "$REPO_ROOT/config/wezterm.lua" "$WEZ_CONF"
ok "Wrote $WEZ_CONF"

# --- Optional: pre-stage cmux/ghostty ---
# ghostty (and therefore cmux) has no BiDi yet, so this does NOT make Hebrew RTL
# today. It only adds a monospace Hebrew fallback so cmux is ready the day ghostty
# ships BiDi. Only appends when a primary font-family already exists, so it never
# silently changes your code font.
if [[ "$PRESTAGE_CMUX" == "1" ]]; then
  GH_CONF="$HOME/.config/ghostty/config"
  if [[ -f "$GH_CONF" ]] && grep -q '^font-family' "$GH_CONF"; then
    if ! grep -q "Miriam Mono CLM" "$GH_CONF"; then
      cp "$GH_CONF" "$GH_CONF.bak.$(date +%s)"
      {
        echo ""
        echo "# claude-hebrew-terminal: Hebrew monospace fallback (for future ghostty BiDi)."
        echo 'font-family = "Miriam Mono CLM"'
      } >> "$GH_CONF"
      ok "Added Hebrew fallback font to $GH_CONF (reload cmux: Cmd+Shift+,)"
    else
      ok "ghostty config already has Miriam Mono CLM."
    fi
  else
    warn "Skipped cmux pre-stage: no primary 'font-family' in ~/.config/ghostty/config."
  fi
fi

echo
note "Verifying…"
"$REPO_ROOT/scripts/verify.sh" || true

cat <<'DONE'

Done. Next:
  1. Open WezTerm:  open -a WezTerm
  2. Launch your tool inside it, e.g.:  claude
  3. Hebrew now reads right-to-left, with no letter gaps.

Note: cmux/ghostty stays LTR-only until ghostty ships BiDi — use WezTerm to read Hebrew.
DONE
