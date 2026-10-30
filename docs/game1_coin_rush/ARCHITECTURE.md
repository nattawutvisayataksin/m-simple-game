# Architecture — Kubi Coin Dash (Game 1 Redesign)

## Structure
- `scenes/main.tscn` — level shell (player, goal, containers, HUD, audio)
- `scenes/player.tscn` — CharacterBody2D platformer controller
- `scenes/coin.tscn` / `coin_gold.tscn` — Area2D collectibles
- `scenes/enemy.tscn` — CharacterBody2D walker (Glitch Walker)
- `scenes/hopper.tscn` — CharacterBody2D jumping enemy (Glitch Hopper)
- `scenes/bat.tscn` — CharacterBody2D flying enemy (บัตบิต, sine hover)
- `scenes/charger.tscn` — CharacterBody2D dash enemy (ชาร์เจอร์, sight-locked dash)
- `scenes/moving_platform.tscn` — AnimatableBody2D patrol platform
- `scenes/goal.tscn` — Area2D goal
- `scenes/hazard.tscn` — Area2D spikes
- `scripts/*.gd` — gameplay logic

## Systems
- 8 levels defined in LEVELS array (main.gd), loaded sequentially; levels 6-8 rename themes
  (ท่อระบายบิต / ท้องฟ้าเมฆเด้ง / ปราสาทบิตคู) via `bg`/`near` keys
- StaticBody2D platforms + AnimatableBody2D moving platforms
- Camera2D smooth follow + bounds clamp + screen shake (trauma-based)
- Per-theme look: `_apply_level_look()` swaps far/near bg strips + sky Gradient
  (SKY_DEFAULT/SEWER/SKY/CASTLE) + CanvasModulate tint + `_setup_weather()/_apply_weather()`
  CPUParticles2D (sewer drips / sky sparkles / castle embers)
- Hero skins: `player.gd set_skin(idx)` + SKIN_SHEETS; chosen on title screen, persisted as `skin` in the save file
- Save schema v1 (hi_score, best_win_time, wins, plays, level, skin) atomic write

## Testing
- `godot --headless --path games/game1_coin_rush --import` must pass
- `godot --headless --path games/game1_coin_rush --script res://tools/test_game1.gd` — 94-assertion
  headless suite (level data, scenes, coins, save round-trip, state reset); exit 0 = pass
- Headless smoke: `godot --headless --path games/game1_coin_rush res://scenes/main.tscn --quit-after 180`