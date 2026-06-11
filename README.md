# claude-hebrew-terminal

Make Hebrew (and other right-to-left) text render correctly in your terminal —
for [Claude Code](https://claude.com/claude-code) and any other TUI.

Most terminals don't apply the Unicode bidirectional (BiDi) algorithm, so Hebrew
comes out **reversed**, and proportional Hebrew fonts add **gaps between letters**.
This repo installs and configures [WezTerm](https://wezterm.org) — one of the few
terminals with real BiDi — plus a monospace Hebrew font, so Hebrew reads
right-to-left with clean spacing. The app's output is already correct; only the
display layer needed fixing.

| Before (no BiDi) | After (WezTerm + BiDi + mono Hebrew) |
|---|---|
| `ומוק ירבח דס` (reversed, gappy) | `סך חברי קומו` (correct RTL, tight) |

## Install

```bash
git clone https://github.com/tatarco/claude-hebrew-terminal
cd claude-hebrew-terminal
./scripts/install.sh
open -a WezTerm        # then run `claude` (or any TUI) inside it
```

This installs WezTerm + `Miriam Mono CLM` via Homebrew and writes
`~/.config/wezterm/wezterm.lua`. An existing config is backed up first. Verify with
`./scripts/verify.sh`.

## How it works

Two independent problems, two fixes — see [SKILL.md](SKILL.md) for the full table:

- **Direction** — `bidi_enabled = true` in WezTerm reorders RTL runs for display
  while keeping logical order internally, so copy-paste stays correct.
- **Spacing** — Hebrew is served by `Miriam Mono CLM`, a monospace font whose
  glyph advance matches the Latin font's cell width, eliminating inter-letter gaps.
  (Diagnose any font with `wezterm ls-fonts --text 'שלום'`: uniform `x_adv` = mono.)

## Does it work in cmux / ghostty?

**Not yet.** cmux renders with `libghostty`, which is LTR-only in every shipped
release — Hebrew can't go RTL there regardless of font. BiDi is in active
development for ghostty; when it lands, cmux inherits it. Run `./scripts/install.sh
--prestage-cmux` to seed the Hebrew fallback font into `~/.config/ghostty/config`
now so cmux is ready then. Until then, WezTerm is the read-Hebrew workflow.

Tracking: [ghostty BiDi #9774](https://github.com/ghostty-org/ghostty/discussions/9774)
· [ghostty macOS RTL #12183](https://github.com/ghostty-org/ghostty/issues/12183)

## Want the cmux workflow *and* BiDi?

cmux is a GUI terminal app with a fixed renderer (ghostty), so you can't swap
WezTerm in — and the other GUI alternatives ([Warp](https://www.warp.dev),
[wmux](https://github.com/amirlehmam/wmux)) bring their own renderers too. The fix
is to use a **terminal-agnostic** agent orchestrator — a TUI you run *inside*
WezTerm, so it inherits WezTerm's BiDi:

- **[Claude Squad](https://github.com/smtg-ai/claude-squad)** — closest to cmux's
  model: manages multiple agents (Claude Code, Codex, Gemini, Aider, OpenCode, Amp)
  each in its own tmux session + git worktree, with diff review. Runs in WezTerm.
- **Herdr** — single Rust binary, tmux-native, agent-aware, lives in your existing
  terminal.
- **WezTerm's built-in multiplexer** (tabs, panes, workspaces) covers much of
  cmux's multitasking on its own.

Caveat: these orchestrate agents via tmux; WezTerm still applies BiDi to displayed
cells, so Hebrew *content* reads RTL, but test tmux status bars/borders in
Hebrew-heavy panes.

## Use as a Claude Code skill

Drop this repo into `~/.claude/skills/claude-hebrew-terminal/` (or add it as a
plugin). The agent loads [SKILL.md](SKILL.md) and can run the setup on request —
e.g. "set up my terminal to read Hebrew."

## License

MIT
