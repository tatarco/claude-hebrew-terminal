# Alternative: AeroSpace (tiling window manager)

Prefer **one agent per window**, tiled i3-style, instead of tabs in one WezTerm
window? This variant uses [AeroSpace](https://github.com/nikitabobko/AeroSpace) to
tile separate WezTerm windows — each is real WezTerm, so Hebrew/BiDi is native and
there's no multiplexer in the path.

Trade-off vs the default tabbed setup: no integrated tab strip and no live
agent-state badges (those rely on WezTerm tabs). Most people prefer the default.

## Setup

```bash
brew install --cask nikitabobko/tap/aerospace
brew install fzf fd
cp aerospace.toml ~/.aerospace.toml
cp agent-sessionizer.sh ~/.config/wezterm/agent-sessionizer.sh
chmod +x ~/.config/wezterm/agent-sessionizer.sh
open -a AeroSpace   # then grant Accessibility in System Settings
```

Edit absolute paths in `~/.aerospace.toml` (the `wezterm` binary and the
sessionizer script) if your Homebrew prefix or home dir differ.

## Keys

- **⌥+Enter** pick a project → shell there · **⌥+P** pick a project → run `claude`
- **⌥+Shift+Enter** plain shell in home
- **⌥+H/J/K/L** focus · **⌥+1..9** workspaces · **⌥+Shift+1..9** move window
- Only WezTerm tiles; everything else floats.
