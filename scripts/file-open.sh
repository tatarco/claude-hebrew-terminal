#!/usr/bin/env bash
# Native popup menu of actions for a file the user clicked in WezTerm.
# Floats over the desktop (no terminal takeover). Called from the open-uri hook.
set -uo pipefail
f="${1:-}"; [ -z "$f" ] && exit 0
f="${f#file://}"
case "$f" in "~/"*) f="$HOME/${f#\~/}";; esac
name=$(basename "$f")

wez=wezterm
for w in /opt/homebrew/bin/wezterm /usr/local/bin/wezterm /usr/bin/wezterm; do
  [ -x "$w" ] && { wez="$w"; break; }
done
glow=glow
for g in /opt/homebrew/bin/glow /usr/local/bin/glow; do
  [ -x "$g" ] && { glow="$g"; break; }
done

opts='"Quick Look (preview)", "Reveal in Finder", "Open in default app", "Copy path"'
case "$f" in
  *.md|*.markdown|*.mdx) opts='"Render Markdown (glow)", '"$opts" ;;
esac

choice=$(/usr/bin/osascript \
  -e "choose from list {$opts} with title \"WezTerm — open file\" with prompt \"$name\" default items {\"Quick Look (preview)\"}" \
  2>/dev/null || true)

case "$choice" in
  *Quick*)         /usr/bin/qlmanage -p "$f" >/dev/null 2>&1 & ;;
  *Reveal*)        /usr/bin/open -R "$f" ;;
  *"default app"*) /usr/bin/open "$f" ;;
  *Markdown*)      "$wez" cli spawn -- "$glow" -p "$f" >/dev/null 2>&1 \
                     || "$wez" cli spawn -- "$glow" "$f" >/dev/null 2>&1 ;;
  *Copy*)          printf '%s' "$f" | /usr/bin/pbcopy ;;
  *)               : ;; # cancelled
esac
exit 0
