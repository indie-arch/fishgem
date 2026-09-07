# Fishing feel and collection update

## Direction

The user confirmed a functional prototype, with eventual cutesy digital art. Use supplied assets and plain placeholders; the user will source replacement assets. The fishing design is documented locally in `fishing.md` and was also read from the connected FishGem Notion page.

## Playable loop

- Existing painted world, WASD/arrow movement, camera follow and water boundaries.
- Shore casting with placeholder rod, animated splash and bobber, a semi-random bite wait, a 0.65-second bobber-dip warning, and cancellation during either waiting phase.
- Continuous aim-and-click fishing with six configurable archetypes, random destination dashes after hits, localized hit/miss effects and chasing danger. Hits are disabled during the 0.18-second dash to prevent repeat-click spam. First-time guidance pauses swimming and danger until explicitly acknowledged; cancelling leaves guidance available next cast.
- Individual fish weights in the bag, persistent discovery counts and per-species personal-best weights that survive selling. New species and new records are celebrated.
- Placeholder shop, weight × species-rate sales, and three independent upgrade tracks with exact current/next benefits and coin shortfalls.
- Catch/escape panels with a fish pop animation, one-button full-wait recasting or return to bank; scrollable journal/shop with fixed navigation, pause, controls and save-and-quit.
- JSON autosave after catches, sales, upgrades and guidance acknowledgement. Saves validate before loading and use a temporary file before replacing the previous save.
- Spawn-connected shoreline is split into three west-to-east regions with named markers, distinct species odds and journal location hints. Every species remains available at every spot.
- Player walking bob/squash, casting lean and bite reaction affect only visual children; ending a cast restores the pose. The shop sign gently bobs/tilts when approached.

## Files

- `scenes/prototype.tscn`: F5 entry point.
- `scripts/prototype_game.gd`: connects world, fishing, UI and progress.
- `scripts/prototype_world.gd`, `prototype_player.gd`: map interactions and plain markers.
- `scripts/fishing_minigame.gd`: reusable encounter.
- `scripts/prototype_progress.gd`: fish catalog, economy, collection and persistence.
- `scripts/prototype_ui.gd`: temporary interface.
- `scenes/fishing_demo.tscn`: selectable encounter test, using the same catalog as the game.

## Provisional tuning

All fish can appear at any shoreline, but encounter weights depend on the spot. In common / fast / strong / tiny / large / rare order:

| Spot | Weights |
| --- | --- |
| West shallows | 7 / 1 / 1 / 4 / 1 / 1 |
| Home bank | 4 / 2 / 1 / 1 / 1 / 1 |
| East reach | 1 / 4 / 3 / 1 / 4 / 3 |

The world derives equal-width x regions from the spawn-connected shoreline, with representative signs at cells (-2, 3), (1, 5) and (5, 5). Journal suggestions compare normalized probabilities, not raw weights. Species rates remain 8–35 coins per kg. Sale value is rounded to the nearest coin, minimum one coin.

Each upgrade track costs 30, 65, 110, 170 and 250 coins for its five levels:

- Steady grip (`ease`): +2 design pixels of target radius per level.
- Heavy lure (`weight`): expected mass × (1 + 0.2 × level).
- Quick bite (`speed`): wait × 0.8^level.

Waits average two random 6–11 second rolls, averaging 8.5 seconds at level zero and 2.79 seconds at level five; the visual warning adds 0.65 seconds after the wait. Recasting does not bypass either stage. Weight averages two random 0.6–1.4 size factors, multiplies by species base mass and the Heavy lure modifier, and rounds to 0.01 kg. The mass is rolled once per encounter and retained through catching, saving and selling. Shared `upgrade_effect` formulas supply gameplay and shop previews. These are provisional test values.

Version 3 saves retain coins, all upgrade levels, each catch's species and mass, discoveries, sparse personal-best weights and a boolean first-time-guidance acknowledgement. Version 2 saves establish records from surviving weighted bag entries only; sold-catch weights are unknown. Version 1 saves migrate previous rod levels to Steady grip; old catches receive 1 kg to preserve sale proceeds, not measured records. Both older versions start with guidance unacknowledged. World position and unfinished encounters are not saved.

## Verification

All five headless checks pass, including minigame behaviour, weight averages, wait bounds, independent upgrades, save migration/malformed data, the integrated catch → sell → upgrade → save/reload loop, and reset/input routing. Added coverage protects record maxima through sale/reload, unknown historical records, invalid version 3 fields, paused/single-fire guidance, bite-warning cancellation and result recasting.

A temporary rendered smoke exercised routed aiming and guidance input, hits/misses, catch/escape → recast, records, shop purchases, journal scrolling and reload. Forward+ surfaces were captured and inspected at 1152×720 on the AMD GPU and 960×640 under Xvfb/software Vulkan. It also exercised walking/pose restoration, confirmed all three spots reachable across 103 connected walkable cells and sampled 6,000 encounters per spot, observing every species and the intended distribution differences. No smoke script is retained.

The previous atlas repair retained all 2,754 painted cells byte-for-byte and removed only unused out-of-bounds atlas definitions.

## Tools

Godot MCP is not exposed to this session. Local Godot 4.7.2 supports running, testing and capturing the prototype, so it is not a blocker. Notion MCP was unavailable for this update; implementation follows the repository design and the user's approved seven-improvement table.

Completing the journal triggers a one-time catch celebration; the journal keeps a completion banner after reload. Resetting progress also clears personal bests and restores first-time guidance.
