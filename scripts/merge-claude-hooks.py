#!/usr/bin/env python3
"""Merge claude-hebrew-terminal's agent-state hooks into ~/.claude/settings.json.

Idempotent and non-destructive: backs up the file, preserves every existing hook,
and only adds the three hooks that drive the WezTerm tab badges:
    UserPromptSubmit -> working      Notification -> needs-input      Stop -> idle

Usage: merge-claude-hooks.py [/path/to/agent-state.sh]
"""
import json, shutil, sys, time, pathlib

state_script = sys.argv[1] if len(sys.argv) > 1 else str(
    pathlib.Path.home() / '.config' / 'wezterm' / 'agent-state.sh')
CMD = f'bash {state_script}'
WANTED = {'UserPromptSubmit': 'working', 'Notification': 'needs-input', 'Stop': 'idle'}

p = pathlib.Path.home() / '.claude' / 'settings.json'
if not p.exists():
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text('{}\n')

shutil.copy(p, f'{p}.bak.{int(time.time())}')
d = json.loads(p.read_text() or '{}')
hooks = d.setdefault('hooks', {})


def already(event):
    return any(h.get('command', '').startswith(CMD)
               for grp in hooks.get(event, []) for h in grp.get('hooks', []))


changed = False
for event, state in WANTED.items():
    if already(event):
        print(f'{event}: already present, skip')
        continue
    hooks.setdefault(event, []).append(
        {'hooks': [{'type': 'command', 'command': f'{CMD} {state}'}]})
    print(f'{event}: added -> {state}')
    changed = True

if changed:
    p.write_text(json.dumps(d, indent=2) + '\n')
json.loads(p.read_text())  # sanity: still valid JSON
print('ok: settings.json valid' + ('' if changed else ' (no changes needed)'))
