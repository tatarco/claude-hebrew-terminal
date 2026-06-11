---
name: claude-hebrew-terminal
description: Set up a terminal that renders Hebrew (and other RTL text) correctly for Claude Code and other TUIs, plus a cmux-style tabbed multi-agent workflow with live agent-state badges. Installs/configures WezTerm with BiDi, a monospace Hebrew font (Miriam Mono CLM), a project picker, and Claude Code hooks. Use when Hebrew/Arabic/RTL text shows up reversed, scrambled, or gappy in the terminal, or when the user mentions RTL rendering, Hebrew display, WezTerm, cmux, ghostty BiDi, or wanting a cmux-like multi-agent terminal.
---

# claude-hebrew-terminal

Hebrew/RTL renders broken in most terminals because they don't apply the Unicode
BiDi algorithm — the renderer's job, not the app's. This sets up WezTerm (real
BiDi) + a monospace Hebrew font, and makes it feel like cmux.

## Quick start

```bash
git clone https://github.com/tatarco/claude-hebrew-terminal
cd claude-hebrew-terminal && ./install.sh   # --no-hooks to skip Claude integration
open -a WezTerm
```

`./scripts/verify.sh` checks the config parses and Hebrew shapes RightToLeft.

## What the install does

1. `brew install --cask wezterm font-miriam-mono-clm` + `brew install fd`
2. Writes `~/.config/wezterm/wezterm.lua` (BiDi + Hebrew font + tabbed workflow)
   and `~/.config/wezterm/agent-state.sh`.
3. Merges three Claude Code hooks into `~/.claude/settings.json` (backed up,
   non-destructive): `UserPromptSubmit→working`, `Notification→needs-input`,
   `Stop→idle` — these drive the tab badges.

## Workflow keys

- **⌘P** project picker → new tab in that repo · **⌘⇧P** → tab + start `claude`
- **⌘1–9** jump tabs · **⌘←/→** move · **⌘T** new · **⌘W** close
- Tab badges: **○** idle · **◐** working · **●** needs you

## Two problems, two fixes

| Symptom | Cause | Fix |
|---|---|---|
| Hebrew reads reversed | terminal has no BiDi | `bidi_enabled = true` (WezTerm) |
| Gaps between Hebrew letters | proportional font in monospace cells | monospace Hebrew font (Miriam Mono CLM) |

Verify a font is monospace: `wezterm ls-fonts --text 'שלום'` — every glyph should
report the **same** `x_adv`.

## cmux / ghostty

cmux renders via `libghostty`, **LTR-only in all shipped releases**, so Hebrew
cannot render RTL there regardless of font. Use this WezTerm setup instead. BiDi is
in development for ghostty (https://github.com/ghostty-org/ghostty/discussions/9774);
when it ships, cmux inherits it.

For a tiling-window-manager variant (AeroSpace, one agent per window), see
[`alternatives/aerospace/`](alternatives/aerospace/).

## Known limitation

Claude Code's input line may not right-align for RTL
(https://github.com/anthropics/claude-code/issues/57511) — affects typing, not
reading output.
