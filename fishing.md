## Catching minigame

The catch minigame is inspired by an aim-training style interaction rather than WEBFISHING's fishing minigame.

### Core loop

- When a fish bites, the fish becomes a moving target on screen.
- The mouse represents the rod/aim point. The player must aim at the fish and click it.
- Each successful click pulls the fish farther along a horizontal catch bar toward the **caught** end.
- A red **danger zone** advances from the end of the bar where the fish started.
- If the red zone reaches the fish before the player reels it in, the fish escapes / the line snaps.
- Missing a click should have a small penalty so spam-clicking is worse than aiming carefully.

### Bite and first-time guidance

- A bobber dip and 0.65-second visual warning precede the aiming encounter.
- The first encounter explains the ring, danger bar, miss penalty and dash lockout. Fish movement and danger are paused until the player presses Enter/Space or clicks Start fishing.
- Acknowledgement is saved; Escape cancels without marking the guidance complete.
- Catch and escape results offer Enter to cast again with the normal wait, or Escape to return to the bank.

### Fish movement

The fish should **swim around continuously**, not simply teleport to a random point after every click. When hit, it can react by changing direction, speeding up, or dashing away. This keeps the mechanic feeling like fighting a fish rather than directly copying an aim trainer.

### Difficulty and fish variety

Difficulty should come from more than just shrinking the target.

- **Common fish:** slower movement and slower danger-zone advance.
- **Fast fish:** quick movement and sudden direction changes.
- **Strong fish:** easy to hit, but the danger zone advances quickly.
- **Tiny fish:** small target, but a relatively forgiving danger zone.
- **Large fish:** large/easy target, but require many successful hits to land.
- **Rare fish:** unusual behaviours such as bursts of speed, fake-outs, sharp turns, or temporary danger-zone surges.

Better / rarer fish can generally make the red danger zone move faster, giving the player less time between successful hits.

### Tuning idea

As a starting point only:

- Successful hit: move the fish about **10–15%** toward the caught end.
- Miss: advance the danger zone about **3–5%**.
- Fish species can modify target size, swim speed, required hits, danger-zone speed, and movement behaviour independently.

### Design goal

The mechanic should reward actual mouse accuracy while still feeling like a fishing struggle. The player is trying to keep landing precise hits quickly enough to stay ahead of the advancing danger zone.
