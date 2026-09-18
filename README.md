# FishGem

A small single-player fishing prototype in Godot 4, inspired by [WEBFISHING](https://store.steampowered.com/app/3146520/WEBFISHING). Wander along the shore, catch fish, sell them, and upgrade your rod. There are six species to find, three fishing spots, and a journal for your catches and personal bests.

Still a work in progress, with placeholder art and fish balance that may change. Human-directed, AI-assisted.

## Play

Open `project.godot` in Godot 4.7.2 and press F5. For packaged builds, see [Releases](https://github.com/indie-arch/fishgem/releases) and the [installation guide](docs/PLAYING.md).

Walk to the water and cast. When a fish bites, click the moving target to stay ahead of the red danger zone. Sell your catch at the SHOP marker to buy easier aiming, heavier fish, or shorter waits.

| Key | Action |
| --- | --- |
| WASD or arrows | Walk |
| E | Cast or use the shop |
| Left click | Hit the fish target |
| Tab | Open the journal |
| Enter or Space | Start fishing after the first-time guidance |
| Enter after a catch or escape | Cast again |
| Escape | Cancel, close, or pause |

Progress saves automatically. You can reset it from the pause menu.

## Development

Run the checks from the project folder:

```sh
bash tools/check.sh
```

For the fishing demo, open `scenes/fishing_demo.tscn` and press F6.

- [Fishing rules](fishing.md)
- [Development status](docs/DEVELOPMENT_STATUS.md)
- [Build and release instructions](docs/RELEASING.md)
- [Performance notes](docs/PERFORMANCE.md)
- [Asset checklist](docs/ASSET_CHECKLIST.md)

Environment and fish art by [Kenney](https://kenney.nl), licensed under CC0. Licenses are in the asset folders.
