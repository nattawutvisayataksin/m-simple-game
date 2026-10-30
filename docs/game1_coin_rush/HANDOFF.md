# Handoff — Game 1 (Kubi Coin Dash)

Updated: 2026-10-30

## Current status

The project is a playable eight-level 2D platformer. The title menu starts the game and offers a
hero-skin chooser (Left/Right, saved into the save file); levels include coins, walkers, a jumping
Hopper enemy, a flying Bat (sine hover), and a sight-locked Charger that dashes when it sees the
player on the same row and is stunned after hitting a wall. There are hazards, moving platforms,
per-theme backdrops with weather particles, and fall detection in the ravine/castle stages. The
player can stomp enemies, collect coins, restart a level, and return to the title menu.

Godot 4.7.2 headless editor/parse check and a 120-frame smoke run of `scenes/main.tscn` both passed. This does not replace a GUI playtest. Full-lap/level completion, visual readability, and controller feel still need human verification.

## Run and controls

From the repository root:

```powershell
godot --path games/game1_coin_rush
```

The project starts at `scenes/title.tscn`. Controls:

- A/D or Left/Right: move (on the title screen: change hero skin)
- Space/W/Up: jump; release early for a shorter jump
- Shift: sprint
- R: restart the current level
- Esc: return to the title menu

## Gameplay and implementation

- `scripts/main.gd` defines eight level layouts (levels 6-8 use the sewer/sky/castle themes) and builds platforms, pickups, enemies, hazards, moving platforms, HUD, level transitions, per-theme backgrounds/weather, win/loss, and save data.
- `scripts/player.gd` implements acceleration-based movement, sprint, variable jump height, coyote time, jump buffering, the run/air/idle sprite animation, and `set_skin(idx)` for hero skins.
- `scripts/enemy.gd` is the walking Glitch Bug; `scripts/enemy_hopper.gd` and `scenes/hopper.tscn` add the jumping, edge-aware Hopper; `scripts/bat.gd` + `scenes/bat.tscn` add the flying บัตบิต (sine hover, stompable); `scripts/charger.gd` + `scenes/charger.tscn` add the charging ชาร์เจอร์ (sight-locked dash, wall-stun, stompable). All can be stomped.
- Levels 4, 5, and 8 have broken ground sections; falling below the level bounds causes a loss.
- `scripts/title.gd` and `scenes/title.tscn` provide the title screen, saved-stat display, and the skin chooser (Left/Right or A/D, persisted as `skin` in the save file).
- Saves live under `user://`; preserve the existing save behavior when changing the schema.

See [ARCHITECTURE.md](ARCHITECTURE.md) for node responsibilities, [GDD.md](GDD.md) for level and design details, [PLAY.md](PLAY.md) for player-facing instructions, [ART_DIRECTION.md](ART_DIRECTION.md) for visual constraints, and [ASSETS.md](ASSETS.md) for asset provenance.

## Validation

The most recent local checks used Godot 4.7.2:

```powershell
godot --headless --path games/game1_coin_rush --editor --quit-after 5
godot --headless --path games/game1_coin_rush --scene res://scenes/main.tscn --quit-after 120
```

Both exited successfully. A dedicated headless test suite now exists:

```powershell
godot --headless --path games/game1_coin_rush --script res://tools/test_game1.gd
```

It runs 94 assertions over level data, all scene loads, coin/gold values, save-file round-trip
(including the `skin` field), and state reset on level reload — last run: 94 PASS / 0 FAIL.
Run it after any change to `scripts/` or level data; it does not yet replace visual playtesting.

## Before calling it playtested

1. Play through all eight levels from the title screen; verify the ordered transitions and the final win on level 8 (ปราสาทบิตคู).
2. Verify Walker/Hopper/Bat/Charger stomps, side hits, Charger wall-stun behavior, spikes, timer loss, and ravine fall behavior (levels 4, 5, 8).
3. Check moving-platform jumps, sprint gaps, HUD, save/stat display, restart, and return-to-title behavior.
4. Try all three hero skins in the title chooser; confirm the choice persists after restarting the game.
5. Levels 6-8, the Bat, the Charger, and the skin system are new content generated without a human playtest — prioritize playing them first.

Preserve vendor license notices and asset attributions. Keep the active project at `games/game1_coin_rush`; do not confuse it with other game projects in the repository.
