---
name: claude-hebrew-terminal
description: Set up a terminal that renders Hebrew (and other RTL) correctly for Claude Code and other TUIs, plus a cmux-style tabbed multi-agent workflow with live agent-state badges and an actionable notification. Installs/configures WezTerm with BiDi, a monospace Hebrew font (Miriam Mono CLM), a project picker, smart link handling, and Claude Code hooks. Use when Hebrew/Arabic/RTL text shows up reversed, scrambled, or gappy in the terminal, or when the user mentions RTL rendering, Hebrew display, WezTerm, cmux, ghostty BiDi, or wanting a cmux-like multi-agent terminal.
---

# claude-hebrew-terminal — setup runbook

This is an executable runbook. Follow it top to bottom on macOS. Each phase ends
with a **verify** gate — do not proceed if it fails; diagnose first.

## Why (so you can adapt, not just copy)

- Terminals render Hebrew **reversed** because they don't run the Unicode BiDi
  algorithm. Fixing direction is the **renderer's** job — a font cannot fix it.
- **cmux/Ghostty/iTerm/Warp are LTR-only today**, so the fix is to run on
  **WezTerm** (real BiDi).
- Hebrew also shows **gaps between letters** when a *proportional* Hebrew font is
  used in monospace cells. Fix: a **monospace** Hebrew font (Miriam Mono CLM).
- WezTerm's child PATH is the bare launchd PATH (`/usr/bin:/bin:…`) — so any
  `fd`/`claude` invocation must use an absolute path or a login shell, else
  "not found".

## Phase 1 — Install

```bash
brew install --cask wezterm font-miriam-mono-clm
brew install fd glow terminal-notifier
```

**Verify:** `wezterm --version` prints a version; `fd --version` works.

## Phase 2 — WezTerm config

Copy `config/wezterm.lua` from this repo to `~/.config/wezterm/wezterm.lua`
(back up any existing file first). It sets: `bidi_enabled`, the Menlo→Miriam Mono
font fallback, a `⌘P`/`⌘⇧P` project picker, tab badges, smart link handling, and
close-confirmation.

**Verify (must load AND shape Hebrew RTL):**
```bash
wezterm --config-file ~/.config/wezterm/wezterm.lua ls-fonts --text 'שלום עולם' | head -4
```
Expect `RightToLeft`, glyphs served by **Miriam Mono CLM**, and a **uniform**
`x_adv` across letters. Uneven `x_adv` = proportional font = gaps → fix the font
fallback. (Use `ls-fonts`, not `show-keys`, to validate — `show-keys` does **not**
catch invalid config fields.)

## Phase 3 — Helpers

Copy to `~/.config/wezterm/` and `chmod +x`:
- `scripts/agent-state.sh` — writes per-tab agent state + posts the actionable
  notification (keyed by `$WEZTERM_PANE`).
- `scripts/file-open.sh` — native popup menu for file links.

Generate a nice notification icon (best-effort):
```bash
src="$(find /Applications/Claude.app -name '*.icns' 2>/dev/null | head -1)"
[ -n "$src" ] && sips -s format png "$src" --out ~/.config/wezterm/notif-icon.png -Z 256
```

## Phase 4 — Claude Code hooks (live tab badges + notification)

Run `python3 scripts/merge-claude-hooks.py ~/.config/wezterm/agent-state.sh`.
It backs up `~/.claude/settings.json` and **merges** (non-destructive) three hooks:
`UserPromptSubmit→working`, `Notification→needs-input`, `Stop→idle`.

**Verify:** `grep agent-state.sh ~/.claude/settings.json` shows the three commands,
and the file is still valid JSON.

## Phase 5 — Use it

```bash
open -a WezTerm
```
- **⌘P** pick project → tab in it · **⌘⇧P** → tab + `claude` · **⌘1–9** switch tabs.
- Tab badges: `○` idle · `◐` working · `●` needs you.
- "Claude is waiting · **Show**" notification focuses the exact tab.

## Gotchas (learned the hard way)

| Symptom | Cause | Fix |
|---|---|---|
| Hebrew reversed | no BiDi | `bidi_enabled = true` (WezTerm) |
| Gaps between letters | proportional Hebrew font | Miriam Mono CLM (uniform `x_adv`) |
| ⌘P does nothing | `fd` not on WezTerm's launchd PATH | call `fd` by absolute path |
| `claude` "not found" / opens in `~` | bare PATH + login-shell cwd reset | `mux_window():spawn_tab{cwd=…}` then `send_text 'claude\n'` |
| config "valid" but GUI errors | `show-keys` doesn't validate fields | validate with `ls-fonts` |
| tmux/cmux still reversed | their renderer has no BiDi | use WezTerm windows/tabs, not a multiplexer |

## Known limitation

Claude Code's input line may not right-align for RTL
(https://github.com/anthropics/claude-code/issues/57511) — affects typing, not
reading output. For a tiling-window-manager variant, see `alternatives/aerospace/`.
