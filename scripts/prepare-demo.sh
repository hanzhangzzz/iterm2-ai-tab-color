#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "Usage: scripts/prepare-demo.sh <input.gif> <output.gif>" >&2
  exit 2
fi

command -v magick >/dev/null 2>&1 || {
  echo "ImageMagick is required: brew install imagemagick" >&2
  exit 1
}

input="$1"
output="$2"
temp_output="$(mktemp "${TMPDIR:-/tmp}/iterm2-ai-tab-color-demo.XXXXXX.gif")"
trap 'rm -f "$temp_output"' EXIT

# Keep only iTerm2 window chrome and tab rows. This removes unrelated menu-bar
# and terminal content while preserving the real recorded tab-color animation.
magick "$input" \
  -coalesce \
  -crop 1600x52+0+27 \
  +repage \
  -layers Optimize \
  "$temp_output"

mv "$temp_output" "$output"
chmod 644 "$output"
