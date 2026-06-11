---
name: claude-hebrew-terminal
description: Set up a terminal that renders Hebrew (and other RTL text) correctly for Claude Code and other TUIs. Installs and configures WezTerm with BiDi enabled and a monospace Hebrew font (Miriam Mono CLM). Use when Hebrew/Arabic/RTL text shows up reversed, scrambled, or with gaps between letters in the terminal, or when the user mentions RTL rendering, Hebrew display, WezTerm, cmux, or ghostty BiDi.
---

# claude-hebrew-terminal

Makes Hebrew/RTL text readable in a terminal UI. The fix lives in the terminal
**renderer**, not in the app's output — Claude Code already emits correct logical
text; most terminals just don't apply the Unicode BiDi algorithm.

## Quick start

```bash
git clone https://github.com/tatarco/claude-hebrew-terminal
cd claude-hebrew-terminal
./scripts/install.sh        # add --prestage-cmux to also seed ghostty/cmux
open -a WezTerm
# then run `claude` (or any TUI) inside WezTerm
```

`./scripts/verify.sh` checks the config parses and Hebrew shapes RightToLeft.

## What it does

1. `brew install --cask wezterm font-miriam-mono-clm`
2. Writes `~/.config/wezterm/wezterm.lua` with:
   - `bidi_enabled = true` + `bidi_direction = 'AutoLeftToRight'` → RTL display,
     logical order preserved internally (copy-paste stays correct).
   - Font fallback `Menlo → Miriam Mono CLM → Courier New` → Latin/code in Menlo,
     Hebrew in a **monospace** font whose advance matches Menlo (no letter gaps).

## Two problems, two fixes

| Symptom | Cause | Fix |
|---|---|---|
| Hebrew reads reversed / wrong direction | terminal has no BiDi | `bidi_enabled = true` (WezTerm) |
| Gaps between Hebrew letters | proportional font in monospace cells | monospace Hebrew font (Miriam Mono CLM) |

Verify a font is monospace: `wezterm ls-fonts --text 'שלום'` — every glyph should
report the **same** `x_adv`. Uneven advances = proportional = will cause gaps.

## cmux / ghostty

cmux renders via `libghostty`, which is **LTR-only in all shipped releases** — so
Hebrew cannot render RTL inside cmux today, regardless of font. This is a renderer
limitation, not a config gap. Use WezTerm to read Hebrew; keep cmux for everything
else.

BiDi is in active development for ghostty (fribidi + HarfBuzz). When it ships, cmux
inherits it. `--prestage-cmux` seeds the Hebrew fallback font into
`~/.config/ghostty/config` now so it's ready then. Tracking:
- ghostty BiDi: https://github.com/ghostty-org/ghostty/discussions/9774
- ghostty macOS RTL: https://github.com/ghostty-org/ghostty/issues/12183

## Known limitation

Claude Code's input line may not right-align for RTL
(https://github.com/anthropics/claude-code/issues/57511) — affects typing, not
reading output. Unrelated to WezTerm.
