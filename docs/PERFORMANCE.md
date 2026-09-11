# Performance pass

The shop keeps its individual catches, original scrolling, wrapped text, spacing and keyboard focus. It allocates labels for the visible rows, reuses them when scrolling, and measures repeated rows once per width/theme. Buying an upgrade updates the existing buttons and descriptions instead of rebuilding the inventory. Opening the shop calculates row prices and the total in one pass.

Internal species validation and pricing use an ID index without copying dictionaries. Public catalog/encounter lookups still return independent copies. Save serialization skips JSON key sorting, while retaining synchronous writes, temporary-file replacement and the existing error/recovery behavior.

The fishing minigame caches its static background separately from animated drawing commands. Resize and encounter start invalidate the background. First-time guidance processes input without running a frame callback. Player movement skips collision probes when stationary and on the stationary axis. World hints retain live shoreline checks but only format text when the interaction changes. The shop sign skips settled transform updates while preserving its animation phase.

Forward+ and all gameplay tuning remain unchanged. No background save worker, inventory limits or pagination were introduced.

## Measurements

Indicative local Godot 4.7.2 headless timings, in milliseconds, using the same deterministic mix of rolled species and weights before and after the changes:

| Operation | 1,000 fish before | After | 10,000 fish before | After |
| --- | ---: | ---: | ---: | ---: |
| Bag valuation | 3.03 | 0.84 | 31.09 | 8.32 |
| Shop opening including layout | 149.98 | 24.46 | 1354.71 | 59.23 |
| Upgrade UI refresh call | 109.21 | 0.06 | 1024.05 | 0.06 |
| Save | 1.56 | 1.51 | 12.52 | 11.16 |
| Load | 3.56 | 2.35 | 35.02 | 23.18 |

Shop opening includes three process-frame waits to allow deferred layout; refresh measures only the UI call, excluding autosave. These are individual observations, not timing assertions or FPS claims. Initial list construction still scales with bag size; scrolling allocates only enough labels for the viewport. Save serialization still scales with inventory size.

Run the informational benchmark:

```sh
godot --headless --path . --script res://tests/performance_benchmark.gd
```

An optional script directory after `--` selects earlier copies of `prototype_progress.gd` and `prototype_ui.gd` for comparison. The benchmark uses and removes `user://fishgem_benchmark_only.json`, never the player's save.

## Regression coverage

```sh
bash tools/check.sh
godot --path . --script res://tests/fishing_render_test.gd
```

The optimization test checks catalog-copy isolation, invalid catches, mixed-bag prices, save/load and sale results, inventory reuse across upgrades, focus, wheel input, the last inventory row, and bounded label allocation. It compares virtual rows against the original VBox/Label layout at multiple widths, with multiline text and theme/font changes. Movement and world tests cover idle collision probes, movement speed, resting poses, modal hints, edited shoreline cells and shop-sign settling.

The drawing test runs headless for lifecycle checks and with a display for actual drawing-cache, resize and recast checks. Existing tests retain coverage of fishing rules, input routing, economy, migration, resets and failed-save recovery.

Sixteen before/after Forward+ screenshots were compared for the shop, scrolled shop, upgraded shop, journal, and six minigame states at 1152×720 and 960×640. Eleven were pixel-identical; five differed only by one 8-bit channel level in 9–13 pixels. No layout or visible appearance differences were observed.
