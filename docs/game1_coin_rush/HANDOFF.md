# Handoff — Game 1 (Kubi Coin Dash)

Updated: 2026-10-30

## Current status

The project is a playable five-level 2D platformer. The title menu starts the game; levels include coins, walkers, a jumping Hopper enemy, hazards, moving platforms, and fall detection in the ravine stages. The player can stomp enemies, collect coins, restart a level, and return to the title menu.

Godot 4.7.2 headless editor/parse check and a 120-frame smoke run of `scenes/main.tscn` both passed. This does not replace a GUI playtest. Full-lap/level completion, visual readability, and controller feel still need human verification.

## Run and controls

From the repository root:

```powershell
godot --path games/game1_coin_rush
```

The project starts at `scenes/title.tscn`. Controls:

- A/D or Left/Right: move
- Space/W/Up: jump; release early for a shorter jump
- Shift: sprint
- R: restart the current level
- Esc: return to the title menu

## Gameplay and implementation

- `scripts/main.gd` defines five level layouts and builds platforms, pickups, enemies, hazards, moving platforms, HUD, level transitions, win/loss, and save data.
- `scripts/player.gd` implements acceleration-based movement, sprint, variable jump height, coyote time, jump buffering, and the run/air/idle sprite animation.
- `scripts/enemy.gd` is the walking Glitch Bug; `scripts/enemy_hopper.gd` and `scenes/hopper.tscn` add the jumping, edge-aware Hopper. Both can be stomped.
- Levels 4 and 5 have broken ground sections; falling below the level bounds causes a loss.
- `scripts/title.gd` and `scenes/title.tscn` provide the title screen and saved-stat display.
- Saves live under `user://`; preserve the existing save behavior when changing the schema.

See [ARCHITECTURE.md](ARCHITECTURE.md) for node responsibilities, [GDD.md](GDD.md) for level and design details, [PLAY.md](PLAY.md) for player-facing instructions, [ART_DIRECTION.md](ART_DIRECTION.md) for visual constraints, and [ASSETS.md](ASSETS.md) for asset provenance.

## Validation

The most recent local checks used Godot 4.7.2:

```powershell
godot --headless --path games/game1_coin_rush --editor --quit-after 5
godot --headless --path games/game1_coin_rush --scene res://scenes/main.tscn --quit-after 120
```

Both exited successfully. No dedicated automated gameplay test runner was found in the project tools; do not report the smoke run as a full regression suite.

## Before calling it playtested

1. Play through all five levels from the title screen; verify the ordered transitions and final win.
2. Verify Hopper and Walker stomps, side hits, spikes, timer loss, and ravine fall behavior.
3. Check moving-platform jumps, sprint gaps, HUD, save/stat display, restart, and return-to-title behavior.
4. Proofread the Thai level names, subtitles, and hints in `scripts/main.gd` and `PLAY.md`; some current copy appears mistyped and should not be treated as final.

Preserve vendor license notices and asset attributions. Keep the active project at `games/game1_coin_rush`; do not confuse it with other game projects in the repository.
