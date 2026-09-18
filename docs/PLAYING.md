# Playing FishGem v0.1

You do not need Godot installed. Choose the AppImage, Windows setup installer, or macOS DMG for the simplest installation. Portable archives are also available; extract those completely before launching.

- **Linux AppImage:** mark the `.AppImage` as executable in your file manager, then double-click it. Alternatively run `chmod +x FishGem-*.AppImage` followed by `./FishGem-v0.1.0-linux-x86_64.AppImage`. If mounting is unavailable, run it with `--appimage-extract-and-run`.
- **Windows installer:** run the `-setup.exe` download. It installs into your user account and adds FishGem to the Start menu. Uninstall through Windows Settings → Apps; saves are preserved.
- **macOS DMG:** open the `.dmg`, drag `fishgem.app` onto Applications, then eject the disk image and open the app from Applications.
- **Linux portable archive:** run `./FishGem.x86_64`. If your extractor drops permissions, run `chmod +x FishGem.x86_64` first.
- **Windows x64:** double-click `FishGem.exe`. This prototype is not code-signed; Windows may show a publisher warning.
- **macOS (Intel and Apple Silicon):** drag `fishgem.app` to Applications and open it. This prototype is ad-hoc signed, not notarized. If macOS blocks it, use System Settings → Privacy & Security → Open Anyway after attempting to open it, only if you trust this download. See https://docs.godotengine.org/en/4.7/tutorials/export/running_on_macos.html.

The game uses Godot's Forward+ renderer and needs a compatible modern graphics driver (Vulkan on Linux, Direct3D 12 on Windows, Metal on macOS). macOS 12 or newer is required. Native Windows/macOS playtesting is still needed before declaring platform support verified.

## Controls

- WASD / arrows: walk
- E: cast near water / interact with shop
- Left click: hit the moving fish target
- Tab: fish journal
- Enter / Space: start first-time fishing guidance
- Enter after a catch or escape: cast again
- Escape: cancel / close / pause

Catch fish, sell them at the SHOP marker, and purchase upgrades. Progress saves automatically. Use the pause menu to reset your save.

Save location:
- Linux: `~/.local/share/godot/app_userdata/fishgem/fishgem_prototype.json`
- Windows: `%APPDATA%\Godot\app_userdata\fishgem\fishgem_prototype.json`
- macOS: `~/Library/Application Support/Godot/app_userdata/fishgem/fishgem_prototype.json`

Kenney artwork is CC0. Godot is MIT licensed. Notices are in `licenses/`; Godot third-party notices: https://godotengine.org/license/.

Report issues at https://github.com/indie-arch/fishgem/issues with your OS, GPU, and reproduction steps.

### Holographic fish

Every species has a holographic variant with an animated rainbow shimmer. Each bite has a 1 in 200 chance to be holographic at any bank, after the species is chosen. These fish swim 30% faster, advance danger 30% faster, and require three extra hits. Their usual movement style and rod upgrade benefits still apply.

Holographic catches are named in the bag and tracked separately in the journal, including lifetime counts and personal best weights. They also discover their base species, so completing the ordinary journal does not require finding all holographic variants. Their sale prices follow the usual species and weight calculation.
