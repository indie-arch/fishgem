#!/usr/bin/env bash
# Repackage exported archives, so existing releases can gain installers unchanged.
set -euo pipefail
cd "$(dirname "$0")/.."
version="${1:?Usage: package-installers.sh VERSION}"
[[ "$version" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]] || exit 1
package_dir="$(mktemp -d)"
trap 'rm -rf "$package_dir"' EXIT
mkdir -p "$package_dir/AppDir/usr/bin" "$package_dir/windows"
tar -xzf "dist/FishGem-$version-linux-x86_64.tar.gz" -C "$package_dir/AppDir/usr/bin"
# Use the player-facing name in the desktop entry.
mv "$package_dir/AppDir/usr/bin/FishGem.x86_64" "$package_dir/AppDir/usr/bin/FishGem"
cp packaging/AppRun "$package_dir/AppDir/AppRun"
cp packaging/fishgem.desktop "$package_dir/AppDir/"
cp icon.svg "$package_dir/AppDir/fishgem.svg"
chmod +x "$package_dir/AppDir/AppRun" "$package_dir/AppDir/usr/bin/FishGem"
curl -fL --retry 3 https://github.com/AppImage/appimagetool/releases/download/1.9.1/appimagetool-x86_64.AppImage -o "$package_dir/appimagetool"
echo "ed4ce84f0d9caff66f50bcca6ff6f35aae54ce8135408b3fa33abfc3cb384eb0  $package_dir/appimagetool" | sha256sum -c -
chmod +x "$package_dir/appimagetool"
ARCH=x86_64 "$package_dir/appimagetool" --appimage-extract-and-run "$package_dir/AppDir" "dist/FishGem-$version-linux-x86_64.AppImage"
chmod +x "dist/FishGem-$version-linux-x86_64.AppImage"
# Launch the actual package with extraction mode, which also works on CI without FUSE.
appimage="$PWD/dist/FishGem-$version-linux-x86_64.AppImage"
(cd "$package_dir" && XDG_DATA_HOME="$package_dir/data" timeout 60 "$appimage" --appimage-extract-and-run --headless --quit-after 10) 2>&1 | tee "$package_dir/smoke.log"
! grep -Eq 'SCRIPT ERROR:|^ERROR:' "$package_dir/smoke.log"
unzip -q "dist/FishGem-$version-windows-x86_64.zip" -d "$package_dir/windows"
makensis -DSOURCE="$package_dir/windows" -DOUTPUT="$PWD/dist/FishGem-$version-windows-x86_64-setup.exe" -DVERSION="$version" packaging/windows.nsi
