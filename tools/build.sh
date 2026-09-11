#!/usr/bin/env bash
# Linux build host; requires Godot 4.7.2 and matching export templates.
set -euo pipefail
cd "$(dirname "$0")/.."
godot_bin="${GODOT:-godot}"
version="${1:-v0.1}"
[[ "$version" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]] || { echo 'Expected a filename-safe release tag (letters, numbers, dots, underscores, hyphens)' >&2; exit 1; }
[[ "$("$godot_bin" --version)" == 4.7.2.stable.* ]] || { echo 'Godot 4.7.2 stable is required' >&2; exit 1; }
# Only generated output is removed.
rm -rf build/linux build/windows build/macos dist
mkdir -p build/{linux,windows,macos} dist
"$godot_bin" --headless --path . --editor --import
"$godot_bin" --headless --path . --export-release Linux
"$godot_bin" --headless --path . --export-release Windows
"$godot_bin" --headless --path . --export-release macOS
for platform in linux windows macos; do
  cp docs/PLAYING.md "build/$platform/README.md"
  mkdir -p "build/$platform/licenses"
  cp assets/kenney_rpg-base/license.txt "build/$platform/licenses/kenney-rpg-base.txt"
  cp assets/kenney_fish-pack_2/License.txt "build/$platform/licenses/kenney-fish-pack.txt"
  cp docs/GODOT-LICENSE.txt "build/$platform/licenses/godot.txt"
done
chmod +x build/linux/FishGem.x86_64
tar -czf "dist/FishGem-$version-linux-x86_64.tar.gz" -C build/linux .
(cd build/windows && zip -qr "../../dist/FishGem-$version-windows-x86_64.zip" .)
# Keep Godot's ZIP metadata and executable permissions for the app bundle.
cp build/macos/FishGem.zip "dist/FishGem-$version-macos-universal.zip"
(cd build/macos && zip -qr "../../dist/FishGem-$version-macos-universal.zip" README.md licenses)
(cd dist && sha256sum *.tar.gz *.zip > SHA256SUMS.txt)
