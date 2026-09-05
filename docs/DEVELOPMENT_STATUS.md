# Second functional prototype

## Direction

The user confirmed a functional prototype, with eventual cutesy digital art. Use supplied assets and plain placeholders; the user will source replacement assets. The fishing design is documented locally in `fishing.md` and was also read from the connected FishGem Notion page.

## Playable loop

- Existing painted world, WASD/arrow movement, camera follow and water boundaries.
- Shore casting with placeholder rod, animated splash and bobber, a semi-random bite wait, and cancellation.
- Continuous aim-and-click fishing with six configurable archetypes, random destination dashes after hits, misses and chasing danger. Hits are disabled during the 0.18-second dash to prevent repeat-click spam.
- Individual fish weights in the bag and persistent discovery counts. Selling does not erase the journal.
- Placeholder shop, weight × species-rate sales, and three independent upgrade tracks.
- Prominent catch/escape result panels, journal, pause, controls and save-and-quit.
- JSON autosave after catches, sales and upgrades. Saves validate before loading and use a temporary file before replacing the previous save.

## Files

- `scenes/prototype.tscn`: F5 entry point.
- `scripts/prototype_game.gd`: connects world, fishing, UI and progress.
- `scripts/prototype_world.gd`, `prototype_player.gd`: map interactions and plain markers.
- `scripts/fishing_minigame.gd`: reusable encounter.
- `scripts/prototype_progress.gd`: fish catalog, economy, collection and persistence.
- `scripts/prototype_ui.gd`: temporary interface.
- `scenes/fishing_demo.tscn`: selectable encounter test, using the same catalog as the game.

## Provisional tuning

All fish can appear at any shoreline. Common fish have weight 4, fast fish weight 2, others weight 1. Species rates are 8–35 coins per kg. Sale value is rounded to the nearest coin, minimum one coin.

Each upgrade track costs 30, 65 and 110 coins for its three levels:

- Steady grip (`ease`): +2 design pixels of target radius per level.
- Heavy lure (`weight`): expected mass × (1 + 0.2 × level).
- Quick bite (`speed`): wait × 0.8^level.

Waits average two random 6–11 second rolls, averaging 8.5 seconds at level zero and 4.35 seconds at level three. Weight averages two random 0.6–1.4 size factors, multiplies by species base mass and the Heavy lure modifier, and rounds to 0.01 kg. The mass is rolled once per encounter and retained through catching, saving and selling. These are provisional test values.

Version 2 saves retain coins, all upgrade levels, each catch's species and mass, and discoveries. Version 1 saves migrate previous rod levels to Steady grip; old catches receive 1 kg, preserving old sale proceeds. World position and unfinished encounters are not saved.

## Verification

Headless checks cover minigame behaviour, weight averages, wait bounds, independent upgrades, save migration and malformed saves, and the integrated catch → sell → upgrade → save/reload loop. Input routing checks cover shortcuts and modal cancellation. The world, shop and encounter have also been rendered and visually inspected with Forward+.

The previous atlas repair retained all 2,754 painted cells byte-for-byte and removed only unused out-of-bounds atlas definitions.

## Tools

Godot MCP is not exposed to this session. Local Godot 4.7.2 supports running, testing and capturing the prototype, so it is not a blocker. Notion is connected; searches found no additional relevant collection, upgrade, exploration, selling, saving or NPC requirements.
