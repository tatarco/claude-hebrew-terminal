-- claude-hebrew-terminal — WezTerm: correct RTL/Hebrew + a cmux-style tabbed
-- multi-agent workflow with live agent-state badges, all in one window.
-- https://github.com/tatarco/claude-hebrew-terminal
local wezterm = require 'wezterm'
local act = wezterm.action
local config = wezterm.config_builder()

-- ── Bidirectional (RTL) text ──────────────────────────────────────────────
config.bidi_enabled = true
config.bidi_direction = 'AutoLeftToRight'

-- ── Fonts (Hebrew = Miriam Mono CLM, monospace → no inter-letter gaps) ─────
config.font = wezterm.font_with_fallback {
  'Menlo', 'Miriam Mono CLM', 'Courier New', 'Arial Hebrew',
}
config.font_size = 14.0
config.color_scheme = 'Catppuccin Mocha'

-- ── Tab bar = your list of agents/projects (like cmux's tab strip) ────────
config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = false
config.use_fancy_tab_bar = true
config.tab_max_width = 32
config.window_padding = { left = 6, right = 6, top = 4, bottom = 4 }

-- Don't lose agents by accident: prompt before closing a tab/window that has a
-- real program running (claude, etc.). Idle shells still close instantly.
config.window_close_confirmation = 'AlwaysPrompt'
config.skip_close_confirmation_for_processes_named = { 'bash', 'sh', 'zsh', 'fish', 'nu' }

local HOME = os.getenv 'HOME' or ''
local function basename(s)
  if s == nil then return '~' end
  if type(s) ~= 'string' then s = s.file_path or tostring(s) end
  s = s:gsub('^file://[^/]*', ''):gsub('[/\\]+$', '')
  if s == HOME or s == '' then return '~' end
  return (s:gsub('.*[/\\]', ''))
end

-- ── Live agent state (Claude hooks write /tmp/wezterm-agent-state/<pane>) ──
local STATE = {
  ['needs-input'] = { '●', '#f38ba8' }, -- red:    Claude needs you
  ['working']     = { '◐', '#f9e2af' }, -- yellow: Claude is working
  ['idle']        = { '○', '#6c7086' }, -- grey:   idle / done
}
local function agent_state(pane)
  local f = io.open('/tmp/wezterm-agent-state/' .. tostring(pane.pane_id), 'r')
  if not f then return 'idle' end
  local s = f:read '*a'; f:close()
  s = (s or ''):gsub('%s+', '')
  return STATE[s] and s or 'idle'
end

wezterm.on('format-tab-title', function(tab)
  local b = STATE[agent_state(tab.active_pane)]
  return {
    { Foreground = { Color = b[2] } },
    { Text = ' ' .. b[1] .. ' ' },
    { Foreground = { Color = '#cdd6f4' } },
    { Text = string.format('%d ▸ %s ', tab.tab_index + 1, basename(tab.active_pane.current_working_dir)) },
  }
end)
wezterm.on('format-window-title', function(tab)
  return basename(tab.active_pane.current_working_dir) .. ' — wezterm'
end)

-- Periodic refresh so badges update even when you're not touching the tab.
config.status_update_interval = 1200
wezterm.on('update-status', function(window) window:set_right_status '' end)

-- The actionable "Claude is waiting · Show" notification is posted by the Claude
-- Notification hook (terminal-notifier, focuses this exact tab on click). Keep the
-- terminal bell quiet so we don't double-notify.
config.audible_bell = 'Disabled'

-- ── Project picker (⌘P) — WezTerm's child PATH is limited, so find fd/exes
local function first_existing(paths)
  for _, p in ipairs(paths) do
    local f = io.open(p, 'r'); if f then f:close(); return p end
  end
  return paths[#paths]
end
local FD = first_existing { '/opt/homebrew/bin/fd', '/usr/local/bin/fd', '/usr/bin/fd', 'fd' }

local function dir_exists(p)
  local ok, success = pcall(function() return (wezterm.run_child_process { '/bin/test', '-d', p }) end)
  return ok and success
end

local function project_choices()
  local roots = {}
  for _, r in ipairs {
    HOME .. '/PycharmProjects', HOME .. '/dev', HOME .. '/code', HOME .. '/src',
    HOME .. '/Projects', HOME .. '/projects', HOME .. '/repos', HOME .. '/work', HOME .. '/Developer',
  } do
    if dir_exists(r) then table.insert(roots, r) end
  end
  if #roots == 0 then return {} end
  local args = { FD, '-H', '-t', 'd', '-d', '3', '^\\.git$' }
  for _, r in ipairs(roots) do table.insert(args, r) end

  local choices, seen = {}, {}
  local ok, out = pcall(function() local _, o = wezterm.run_child_process(args); return o end)
  if ok and out then
    for line in out:gmatch '[^\n]+' do
      local dir = line:gsub('/%.git/?$', '')
      if dir ~= '' and not seen[dir] then
        seen[dir] = true
        table.insert(choices, { id = dir, label = '▸ ' .. dir:gsub('.*/', '') })
      end
    end
  end
  table.sort(choices, function(a, b) return a.label < b.label end)
  return choices
end

local function pick_project(window, pane, with_agent)
  local choices = project_choices()
  if #choices == 0 then
    window:toast_notification('Project picker', 'No git repos found under your project folders', nil, 4000)
    return
  end
  window:perform_action(act.InputSelector {
    title = with_agent and 'Launch agent (claude) in new tab' or 'Open project in new tab',
    fuzzy = true,
    choices = choices,
    action = wezterm.action_callback(function(win, p, id)
      if not id then return end
      -- Launch claude via a LOGIN shell so the user's real PATH is loaded
      -- (SpawnCommandInNewTab otherwise uses the bare launchd PATH → "claude not found").
      local shell = os.getenv 'SHELL' or '/bin/zsh'
      local args = with_agent and { shell, '-l', '-c', 'claude' } or nil
      win:perform_action(act.SpawnCommandInNewTab { cwd = id, args = args }, p)
    end),
  }, pane)
end

config.keys = {
  { key = 'p', mods = 'CMD',       action = wezterm.action_callback(function(w, p) pick_project(w, p, false) end) },
  { key = 'P', mods = 'CMD|SHIFT', action = wezterm.action_callback(function(w, p) pick_project(w, p, true) end) },
  { key = 't', mods = 'CMD',       action = act.SpawnTab 'CurrentPaneDomain' },
  { key = 'w', mods = 'CMD',       action = act.CloseCurrentTab { confirm = true } },
  { key = 'LeftArrow',  mods = 'CMD', action = act.ActivateTabRelative(-1) },
  { key = 'RightArrow', mods = 'CMD', action = act.ActivateTabRelative(1) },
}
for i = 1, 9 do
  table.insert(config.keys, { key = tostring(i), mods = 'CMD', action = act.ActivateTab(i - 1) })
end

-- ── Links open nicely in the browser ──────────────────────────────────────
-- Detect URLs (plus bare localhost:port and www.) and open the default browser.
config.hyperlink_rules = wezterm.default_hyperlink_rules()
table.insert(config.hyperlink_rules, {
  regex = [[\b(?:localhost|127\.0\.0\.1)(?::\d+)?(?:/\S*)?\b]], format = 'http://$0',
})
table.insert(config.hyperlink_rules, { regex = [[\bwww\.\S+\b]], format = 'https://$0' })
-- Bare absolute / ~ file paths (…/x.ext) → clickable file:// so the file menu fires.
table.insert(config.hyperlink_rules, {
  regex = [[(?:^|[\s"'`(<])((?:/|~/)[\w.~@%+\-/]+\.\w+)]], format = 'file://$1', highlight = 1,
})
-- Explicit relative paths (./x.ext, ../x.ext) → kept raw; resolved against the
-- tab's cwd in the open-uri handler below.
table.insert(config.hyperlink_rules, {
  regex = [[(?:^|[\s"'`(<])(\.{1,2}/[\w.~@%+\-/]+\.\w+)]], format = '$1', highlight = 1,
})

config.mouse_bindings = {
  -- Plain left-click opens a link when you're NOT selecting text (browser-like).
  { event = { Up = { streak = 1, button = 'Left' } }, mods = 'NONE',
    action = act.CompleteSelectionOrOpenLinkAtMouseCursor 'ClipboardAndPrimarySelection' },
  -- ⌘-click also opens links explicitly.
  { event = { Up = { streak = 1, button = 'Left' } }, mods = 'CMD',
    action = act.OpenLinkAtMouseCursor },
}

-- Web links (http/https) open in the browser (WezTerm default). But FILE links
-- shouldn't launch an editor — render Markdown in an in-terminal reader (glow)
-- and preview anything else with Quick Look.
-- File links (file://, bare absolute, or ~/ paths) → a NATIVE popup menu
-- (osascript, floats over the desktop; doesn't take over the terminal).
-- http/https/mailto fall through to WezTerm's default (browser/mail).
local FILE_OPEN = HOME .. '/.config/wezterm/file-open.sh'
local function pane_cwd(pane)
  local cwd = pane:get_current_working_dir()
  if not cwd then return nil end
  if type(cwd) == 'string' then return (cwd:gsub('^file://[^/]*', '')) end
  return cwd.file_path
end

wezterm.on('open-uri', function(window, pane, uri)
  local path
  if uri:find '^file://' then
    path = uri:gsub('^file://[^/]*', '')
  elseif uri:find '^%a[%w+.%-]*:' then
    return -- another scheme (http/https/mailto/…) → let WezTerm open it normally
  elseif uri:find '^/' or uri:find '^~/' then
    path = uri
  else
    -- relative path → resolve against the tab's working directory
    local base = pane_cwd(pane)
    if not base then return end
    path = base:gsub('/+$', '') .. '/' .. (uri:gsub('^%./', ''))
  end
  path = path:gsub('%%(%x%x)', function(h) return string.char(tonumber(h, 16)) end)
  wezterm.background_child_process { '/bin/bash', FILE_OPEN, path }
  return false
end)

return config
