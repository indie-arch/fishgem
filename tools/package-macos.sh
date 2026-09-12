#!/usr/bin/env bash
# Run on macOS: retain the exported universal app and its ad-hoc signature.
set -euo pipefail
cd "$(dirname "$0")/.."
version="${1:?Usage: package-macos.sh VERSION}"
[[ "$version" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]] || exit 1
package_dir="$(mktemp -d)"
trap 'rm -rf "$package_dir"' EXIT
mkdir "$package_dir/volume"
ditto -x -k "dist/FishGem-$version-macos-universal.zip" "$package_dir/volume"
ln -s /Applications "$package_dir/volume/Applications"
codesign --verify --deep --strict "$package_dir/volume/fishgem.app"
lipo "$package_dir/volume/fishgem.app/Contents/MacOS/fishgem" -verify_arch x86_64 arm64
hdiutil create -volname FishGem -srcfolder "$package_dir/volume" -ov -format UDZO "dist/FishGem-$version-macos-universal.dmg"
hdiutil verify "dist/FishGem-$version-macos-universal.dmg"
