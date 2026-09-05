# FishGem

Semi AI slop: a human-directed, AI-assisted fishing prototype.

A small single-player Godot 4 fishing prototype inspired by WEBFISHING. Walk around the supplied map, catch fish through an aim-and-click minigame, sell them, and upgrade your rod.

## Play

1. Open `project.godot` in Godot 4.7.
2. Press **F5** to run the prototype.
3. Walk toward the water and press **E** when the casting prompt appears.
4. When a fish bites, click the moving target to pull it ahead of the red danger zone.
5. Return to the **SHOP** marker to sell fish and buy rod upgrades.

| Control | Action |
| --- | --- |
| WASD / arrows | Walk |
| E | Cast at the shore / interact with shop |
| Left click | Hit the fish target |
| Tab | Fish journal |
| Escape | Cancel encounter / close panel / pause |

Progress saves after catches, sales, and upgrades, and when quitting. Coins, individual fish weights, discoveries, and all three upgrade tracks persist; player position resets to the starting bank. Save file: `user://fishgem_prototype.json` (Godot **Project → Open User Data Folder**).

Old prototype saves migrate automatically: previous rod upgrades become Steady grip levels, and old bag entries receive 1 kg weights to preserve their sale values.

To start over, open the Escape menu and choose **Reset save…**. Confirming clears coins, upgrades, caught fish and journal discoveries; Cancel or Escape keeps your save.

For an isolated fishing test with selectable species, open `scenes/fishing_demo.tscn` and press **F6**.

## Prototype scope

Six fish archetypes exercise the rules in `fishing.md`: common, fast, strong, tiny, large, and rare. Three separate upgrade tracks each have five levels:

- **Steady grip:** enlarges the target ring by two design pixels per level.
- **Heavy lure:** raises average fish weight by 20% of the base weight per level.
- **Quick bite:** reduces waiting time by 20% per level.

Unupgraded bites take 6–11 seconds, with waits near the middle more common. Fish weight also favours the middle of a species-specific range. Sale value is the species rate multiplied by kilograms, rounded to whole coins. Catch and escape panels show the fish name; catches also show weight and value. Casts have a placeholder rod, splash and bobber.

After a successful hit, the fish dashes to a random destination over 0.18 seconds. Track it and reacquire the target; clicks during that brief dash are ignored. Discovering every species triggers a journal-complete celebration and leaves a completion banner in the journal.

Fish names, prices, encounter frequency and difficulty are provisional values for playtesting.

The eventual direction is cutesy digital art. The player and shop are plain placeholders; the environment and fish use provided Kenney assets. No custom art or audio has been generated. See [asset checklist](docs/ASSET_CHECKLIST.md) for replacements and [development status](docs/DEVELOPMENT_STATUS.md) for implementation details.

## Checks

Run each command from the project folder:

```sh
godot --headless --path . --script res://tests/fishing_minigame_test.gd
godot --headless --path . --script res://tests/prototype_progress_test.gd
godot --headless --path . --script res://tests/prototype_loop_test.gd
godot --headless --path . --script res://tests/prototype_input_test.gd
godot --headless --path . --script res://tests/prototype_reset_test.gd
```

## Credits

- Inspired by [WEBFISHING](https://store.steampowered.com/app/3146520/WEBFISHING).
- Supplied environment and fish assets by [Kenney](https://kenney.nl), CC0. Licenses are retained in their asset folders.
