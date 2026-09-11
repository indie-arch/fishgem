# FishGem

Semi AI slop: a human-directed, AI-assisted fishing prototype.

A small single-player Godot 4 fishing prototype inspired by WEBFISHING. Walk around the supplied map, catch fish through an aim-and-click minigame, sell them, and upgrade your rod.

## Play

1. Open `project.godot` in Godot 4.7.
2. Press **F5** to run the prototype.
3. Walk toward the water and press **E** when the casting prompt appears.
4. Watch for the bobber dip and **Bite!** warning. On your first encounter, read the guidance and press **Enter / Space** or click **Start fishing**; danger stays paused until you start.
5. Click the moving target to pull it ahead of the red danger zone. After a catch or escape, press **Enter** to cast again or **Escape** to return to the bank.
6. Return to the **SHOP** marker to sell fish and buy rod upgrades.

| Control | Action |
| --- | --- |
| WASD / arrows | Walk |
| E | Cast at the shore / interact with shop |
| Left click | Hit the fish target |
| Tab | Fish journal |
| Enter / Space | Start first-time fishing guidance |
| Enter on result | Cast again at the current shore |
| Escape | Cancel encounter / close panel / pause |

Progress saves after catches, sales, upgrades and acknowledging the first-time guidance, and when quitting. Coins, individual fish weights, discoveries, per-species personal bests, guidance acknowledgement and all three upgrade tracks persist; player position resets to the starting bank. Save file: `user://fishgem_prototype.json` (Godot **Project → Open User Data Folder**).

If a save cannot be loaded, a recovery screen blocks gameplay and autosaving. Retry loading, quit without saving, or explicitly start fresh while preserving the original beside the save as `.unreadable` (numbered when needed). If preservation or the new save fails, recovery stays open.

Old prototype saves migrate automatically. Previous rod upgrades become Steady grip levels, and version 1 bag entries receive 1 kg weights to preserve their sale values, not to invent measured records. Version 2 bag weights establish starting personal bests; already-sold fish have no recoverable weight history and show an unknown record until caught again. Older saves also receive the new first-time guidance.

To start over, open the Escape menu and choose **Reset save…**. Confirming clears coins, upgrades, caught fish, journal discoveries and personal bests, and restores first-time guidance; Cancel or Escape keeps your save.

For an isolated fishing test with selectable species, open `scenes/fishing_demo.tscn` and press **F6**.

## Prototype scope

Six fish archetypes exercise the rules in `fishing.md`: common, fast, strong, tiny, large, and rare. Three separate upgrade tracks each have five levels:

- **Steady grip:** enlarges the target ring by two design pixels per level.
- **Heavy lure:** raises average fish weight by 20% of the base weight per level.
- **Quick bite:** reduces waiting time by 20% per level.


The shop shows each upgrade's current → next numerical effect and any coin shortfall. Long shop and journal content scrolls, with navigation buttons kept visible.

Three named shoreline areas give exploration a purpose:

| Spot | Favoured catches |
| --- | --- |
| West shallows | Pond pals and Tiny rascals |
| Home bank | The original balanced mix, weighted toward Pond pals and Zoomy friends |
| East reach | Zoomy friends, Stubborn chums, Big softies and Pink pranksters |

The HUD tracks “Collect every fish” progress and points to journal hints, then celebrates completion. Selling fish never reduces this count.

Every species remains available at every bank. The journal hints at the best spot for each species and retains personal-best weights after selling. New species and heavier records receive catch-result celebrations.
Unupgraded bites take 6–11 seconds, with waits near the middle more common, followed by a 0.65-second visual bite warning before aiming starts. Fish weight also favours the middle of a species-specific range. Sale value is the species rate multiplied by kilograms, rounded to whole coins. Catch and escape panels show the fish name; catches also show weight and value. Casts have a placeholder rod, splash and bobber, with player casting/bite reactions. The player bobs while walking and the shop sign reacts to proximity.

After a successful hit, the fish dashes to a random destination over 0.18 seconds. Track it and reacquire the target; clicks during that brief dash are ignored. Local hit bursts, miss markers and a close-danger warning clarify feedback without screen shake. Catch-result fish pop into view. Discovering every species triggers a journal-complete celebration and leaves a completion banner in the journal.

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
godot --headless --path . --script res://tests/prototype_recovery_test.gd
```

## Credits

- Inspired by [WEBFISHING](https://store.steampowered.com/app/3146520/WEBFISHING).
- Supplied environment and fish assets by [Kenney](https://kenney.nl), CC0. Licenses are retained in their asset folders.
