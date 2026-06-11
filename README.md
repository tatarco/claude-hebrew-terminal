<div align="center">

# 🪬 claude-hebrew-terminal

### Read Hebrew (and any RTL) correctly in your terminal — with a cmux-style multi-agent workflow built in.

One command. WezTerm + a monospace Hebrew font + a tabbed, project-aware, agent-state-aware setup for [Claude Code](https://claude.com/claude-code) and any terminal AI agent.

</div>

---

## The problem

Most terminals don't apply the Unicode **bidirectional (BiDi)** algorithm, so Hebrew comes out **reversed**, and proportional Hebrew fonts add **gaps between letters**. Your AI agent's output is correct — the terminal just draws it wrong.

```
broken:   ומוק ירבח דס      ← reversed words, gappy
correct:  סך חברי קומו       ← right-to-left, tight
```

The fix lives in the **renderer**, so this repo sets you up on **WezTerm** — one of the only terminals with real BiDi — and then makes it feel like the multi-agent terminal you already love.

## Install (one command)

```bash
git clone https://github.com/tatarco/claude-hebrew-terminal
cd claude-hebrew-terminal && ./install.sh
open -a WezTerm
```

Installs WezTerm + `Miriam Mono CLM` + `fd`, writes the config, and wires up Claude Code hooks. Existing configs are backed up. Use `./install.sh --no-hooks` to skip the Claude integration.

## What you get

| Press | Does |
|---|---|
| **⌘P** | Fuzzy-pick a project → opens it in a new tab (then run `claude`) |
| **⌘⇧P** | Fuzzy-pick a project → opens a tab **and** starts `claude` |
| **⌘1–9** | Jump to a tab · **⌘←/→** move · **⌘T** new · **⌘W** close |

- **Correct Hebrew/RTL** in every tab — right-to-left, no letter gaps, copy-paste stays in logical order.
- **A tab per agent**, each labeled with its project — your cmux-style strip.
- **Live agent-state badges**, the cmux killer feature, right in the tab:

  | Badge | Meaning |
  |---|---|
  | ○ grey | idle / done |
  | ◐ yellow | Claude is working |
  | ● red | Claude needs you (input or permission) |

- **Desktop notification** when an agent finishes and needs you.

## How it works

- **Direction** — `bidi_enabled` in WezTerm reorders RTL runs for display while keeping logical order internally (copy-paste stays correct). Hebrew needs no letter-joining, so WezTerm's one BiDi limitation doesn't apply.
- **Spacing** — Hebrew is served by **Miriam Mono CLM**, a monospace font whose advance matches the Latin font, so glyphs fill their cells with no gaps. (Diagnose any font: `wezterm ls-fonts --text 'שלום'` — uniform `x_adv` = monospace.)
- **Agent state** — Claude Code hooks (`UserPromptSubmit`/`Notification`/`Stop`) write each session's state to a file keyed by the WezTerm pane id; WezTerm polls it and recolors the tab.

## Why not cmux / Ghostty / iTerm / Warp?

They render with engines that are **LTR-only** today (Ghostty — and therefore cmux — has no shipped BiDi; iTerm/Warp likewise). A font can't fix direction; the renderer must. WezTerm is the pragmatic answer that also gives you a great multi-agent workflow. See [`alternatives/`](alternatives/) for a tiling-window-manager (AeroSpace) variant.

## Use as a Claude Code skill

Drop this repo into `~/.claude/skills/claude-hebrew-terminal/` — the agent reads [SKILL.md](SKILL.md) and can run the whole setup on request ("set up my terminal to read Hebrew").

## License

MIT
