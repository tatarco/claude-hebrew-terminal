#!/usr/bin/env bash
# Convert a screen recording (.mov/.mp4) into an optimized GIF for the README.
# Record WezTerm with ⌘⇧5 (macOS), then:
#   ./scripts/make-gif.sh ~/Desktop/recording.mov assets/demo.gif
# Optional: fps and width → ./make-gif.sh in.mov out.gif 12 900
set -euo pipefail
in="${1:?usage: make-gif.sh input.mov [out.gif] [fps] [width]}"
out="${2:-${in%.*}.gif}"
fps="${3:-12}"
width="${4:-900}"
pal="$(mktemp -t palette).png"
ffmpeg -y -i "$in" -vf "fps=$fps,scale=$width:-1:flags=lanczos,palettegen=stats_mode=diff" "$pal"
ffmpeg -y -i "$in" -i "$pal" \
  -lavfi "fps=$fps,scale=$width:-1:flags=lanczos[x];[x][1:v]paletteuse=dither=bayer:bayer_scale=3" "$out"
echo "wrote $out ($(du -h "$out" | cut -f1))"
