# Asset checklist

Target direction: **cutesy digital art**. The user will find replacement assets. No custom artwork or sound has been generated.

## Current assets and placeholders

| Item | Current implementation | Later replacement |
| --- | --- | --- |
| Environment | Supplied Kenney RPG tiles; original painted map retained | Optional matching cutesy terrain and scenery |
| Fish | Six supplied Kenney fish PNGs, assigned to prototype archetypes | Optional species art with a consistent visual style |
| Player | Plain cream rectangle labelled YOU, with walking bob/squash, cast lean and bite reaction | Character idle, walk and fishing animations; character design still open |
| Shop | Plain tan rectangle with a proximity-reactive SHOP sign | Stall/shop art; shopkeeper if desired |
| Casting | Simple drawn rod/line, animated splash rings/droplets, bobber, bite dip/ripples and warning | Optional final rod/bobber art and splash animation |
| Fishing interface | Plain shapes, target ring, catch bar, localized hit/miss effects and first-time guidance | UI artwork if desired; mechanics remain separate |
| Journal / HUD | Engine font, scrollable plain panels, supplied fish icons, personal records and location hints; result icon pop | Readable font and inventory/currency/equipment icons |
| Audio | Silent | Cast, bite, hit, miss, catch, escape, sale and upgrade cues; ambience/music optional |

## Where replacements go

- Character art: replace the marker in `scripts/prototype_player.gd` with a Sprite2D or AnimatedSprite2D. Feet are centred on the player's position; keep collisions independent of artwork.
- Shop: replace `_add_shop_marker()` in `scripts/prototype_world.gd`; interaction distance stays separate.
- Fish: update `texture_path` per species in `scripts/prototype_progress.gd`. Current PNGs face left; rendering mirrors them to match movement. The target ring defines the hit area.
- Interface: `scripts/prototype_ui.gd` and the draw methods in `scripts/fishing_minigame.gd` contain temporary presentation.

Keep source licenses with new assets and include frame sizes/animation names for sprite sheets. Supplied packs are CC0; retain `assets/kenney_rpg-base/license.txt` and `assets/kenney_fish-pack_2/License.txt`.
