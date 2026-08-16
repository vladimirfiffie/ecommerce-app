#!/usr/bin/env bash
# Renders the launcher icon from the two SVGs beside this script.
#
# Run it after editing either SVG; the PNGs it writes are committed, so a
# checkout builds without needing rsvg-convert installed.
#
#   tool/icon/generate.sh
#
# Needs: rsvg-convert (librsvg), magick (ImageMagick 7).
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
res=$(cd "$here/../../android/app/src/main/res" && pwd)

# Legacy square icon, and the adaptive foreground at 108dp. Densities are
# mdpi ×1, hdpi ×1.5, xhdpi ×2, xxhdpi ×3, xxxhdpi ×4.
declare -A legacy=([mdpi]=48 [hdpi]=72 [xhdpi]=96 [xxhdpi]=144 [xxxhdpi]=192)
declare -A adaptive=([mdpi]=108 [hdpi]=162 [xhdpi]=216 [xxhdpi]=324 [xxxhdpi]=432)

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

for density in "${!legacy[@]}"; do
  dir="$res/mipmap-$density"
  mkdir -p "$dir"

  # Adaptive foreground: transparent, the launcher supplies the plate.
  rsvg-convert -w "${adaptive[$density]}" -h "${adaptive[$density]}" \
    "$here/foreground.svg" -o "$dir/ic_launcher_foreground.png"

  # Legacy icon: the same mark baked onto the plate, for pre-Android-8.
  #
  # Drawn 25% larger than the adaptive layer before being centred and clipped.
  # The mark is sized for a canvas a launcher crops into; on the legacy square,
  # which nothing crops, that same size reads as lost in the middle.
  size=${legacy[$density]}
  grown=$(( size * 5 / 4 ))
  rsvg-convert -w "$size" -h "$size" "$here/background.svg" -o "$tmp/bg.png"
  rsvg-convert -w "$grown" -h "$grown" "$here/foreground.svg" -o "$tmp/fg.png"
  magick "$tmp/bg.png" "$tmp/fg.png" -gravity center -composite \
    "$dir/ic_launcher.png"
done

echo "wrote icons into $res/mipmap-*"
