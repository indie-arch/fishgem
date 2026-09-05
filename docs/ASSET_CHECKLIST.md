# Asset checklist

Target direction: **cutesy digital art**. The user will find replacement assets. No custom artwork or sound has been generated.

## Current assets and placeholders

| Item | Current implementation | Later replacement |
| --- | --- | --- |
| Environment | Supplied Kenney RPG tiles; original painted map retained | Optional matching cutesy terrain and scenery |
| Fish | Six supplied Kenney fish PNGs, assigned to prototype archetypes | Optional species art with a consistent visual style |
| Player | Plain cream rectangle labelled YOU | Character idle, walk and fishing animations; character design still open |
| Shop | Plain tan rectangle labelled SHOP | Stall/shop art; shopkeeper if desired |
| Casting | Simple drawn rod/line, animated splash rings/droplets, bobber and wait timer | Optional final rod/bobber art and splash animation |
| Fishing interface | Plain shapes, target ring and catch bar | UI artwork if desired; mechanics remain separate |
| Journal / HUD | Engine font, plain panels and supplied fish icons | Readable font and inventory/currency/equipment icons |
| Audio | Silent | Cast, bite, hit, miss, catch, escape, sale and upgrade cues; ambience/music optional |

## Where replacements go

- Character art: replace the marker in `scripts/prototype_player.gd` with a Sprite2D or AnimatedSprite2D. Feet are centred on the player's position; keep collisions independent of artwork.
- Shop: replace `_add_shop_marker()` in `scripts/prototype_world.gd`; interaction distance stays separate.
- Fish: update `texture_path` per species in `scripts/prototype_progress.gd`. Current PNGs face left; rendering mirrors them to match movement. The target ring defines the hit area.
- Interface: `scripts/prototype_ui.gd` and the draw methods in `scripts/fishing_minigame.gd` contain temporary presentation.

Keep source licenses with new assets and include frame sizes/animation names for sprite sheets. Supplied packs are CC0; retain `assets/kenney_rpg-base/license.txt` and `assets/kenney_fish-pack_2/License.txt`.
