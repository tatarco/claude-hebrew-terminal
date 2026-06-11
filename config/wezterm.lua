-- claude-hebrew-terminal — WezTerm config for correct RTL/Hebrew rendering.
-- https://github.com/tatarco/claude-hebrew-terminal
local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- Bidirectional (RTL) text support.
-- WezTerm reorders RTL runs (Hebrew) for display but keeps logical order
-- internally, so copy-paste comes out correct. Hebrew needs no letter-joining
-- (unlike Arabic), so WezTerm's joining limitation does not apply here.
config.bidi_enabled = true
-- Base paragraph direction = LTR unless the first strong char is RTL.
-- Matches TUI output (lines usually start with English/markup; Hebrew runs flip).
config.bidi_direction = 'AutoLeftToRight'

-- Latin/code stays in Menlo; Hebrew is served by Miriam Mono CLM, a MONOSPACE
-- Hebrew font whose advance matches Menlo's exactly, so Hebrew glyphs fill their
-- cells with no inter-letter gaps. Arial Hebrew is proportional (uneven advances)
-- and causes gaps, so it is last-resort only.
config.font = wezterm.font_with_fallback {
  'Menlo',
  'Miriam Mono CLM',
  'Courier New',
  'Arial Hebrew',
}
config.font_size = 14.0

return config
