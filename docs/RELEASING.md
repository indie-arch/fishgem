# Desktop release

Builds use **Godot 4.7.2 stable** and its matching official export templates. All three targets export on a Linux host: Linux x86_64, Windows x86_64, and macOS universal (Intel + Apple Silicon).

## Local build

Install Godot 4.7.2 and its templates via Editor → Manage Export Templates. On Linux, install `zip`, `unzip`, and GNU coreutils, then run:

```sh
tools/check.sh
tools/build.sh v0.1
```

Set `GODOT=/path/to/godot` if needed. Packages and `SHA256SUMS.txt` appear in `dist/`. The build script replaces generated `build/{linux,windows,macos}` and `dist/` contents. Export presets can also be used from Godot's export dialog on other hosts.

Exports include game resources (including fish textures loaded dynamically), excluding tests, docs, and build tools, with player instructions and license notices alongside the executable. Linux uses tar.gz to retain executable permissions; macOS retains Godot's app ZIP and signature.

## GitHub release

1. Push this setup. Enable GitHub Actions if disabled. Branch pushes and pull requests run regression tests, export all platforms, smoke-test the Linux binary, and upload downloadable workflow artifacts. **Actions → Desktop builds → Run workflow** also builds without creating a release.
2. Download the artifacts and playtest on Linux, Windows, and both Mac architectures where available. Check movement, fishing, shop, journal, save/reload, and quitting. A headless Linux test cannot validate graphics or native Windows/macOS behavior.
3. Review public source/assets for anything private and decide a source-code license: none is currently specified; the Kenney and Godot licenses do not license FishGem's own code.
4. Review `docs/RELEASE_NOTES.md`. Commit all release changes, then tag that commit:

   ```sh
   git tag -a v0.1 -m "FishGem v0.1"
   git push origin v0.1
   ```

5. The workflow creates a **draft** GitHub release containing all three archives and checksums. Inspect the downloads and notes, make the repository public when ready, then publish the draft from GitHub Releases.

No signing secrets are required. The release job alone receives `contents: write`; PR builds cannot create releases. Reruns can replace draft assets but refuse to modify a published release. Keep tags immutable after publication.

For future releases, update `config/version` in `project.godot`, macOS application versions in `export_presets.cfg`, and the player/release notes before tagging. Tags accept `vMAJOR.MINOR` or `vMAJOR.MINOR.PATCH`. To upgrade Godot, update both download/version references in the workflow and the build script version check together.

## Signing

The macOS preset uses Godot's built-in ad-hoc signing, with no notarization; users may need an explicit Gatekeeper exception. Windows exports are unsigned. Trusted publisher signing and Apple notarization require certificates/accounts and are not configured. Never commit signing credentials; use GitHub Actions secrets if signing is added later.

Reference: [Godot macOS export and signing documentation](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_macos.html).
