# Architecture — Kubi Coin Dash (Game 1 Redesign)

## Structure
- `scenes/main.tscn` — level shell (player, goal, containers, HUD, audio)
- `scenes/player.tscn` — CharacterBody2D platformer controller
- `scenes/coin.tscn` / `coin_gold.tscn` — Area2D collectibles
- `scenes/enemy.tscn` — CharacterBody2D walker
- `scenes/goal.tscn` — Area2D goal
- `scenes/hazard.tscn` — Area2D spikes
- `scripts/*.gd` — gameplay logic

## Systems
- 3 levels defined in LEVELS array (main.gd), loaded sequentially
- StaticBody2D platforms + AnimatableBody2D moving platforms
- Camera2D smooth follow + bounds clamp + screen shake
- Save schema v1 (hi_score, best_win_time, wins, plays, level) atomic write

## Testing
- `godot --headless --path games/game1_coin_rush --import` must pass
- Headless run 8s no errors