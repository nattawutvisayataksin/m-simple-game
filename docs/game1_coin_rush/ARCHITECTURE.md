# Architecture — Kubi Coin Dash (Game 1 Redesign)

## Structure
- `scenes/main.tscn` — level shell (player, goal, containers, HUD, audio)
- `scenes/player.tscn` — CharacterBody2D platformer controller
- `scenes/coin.tscn` / `coin_gold.tscn` — Area2D collectibles
- `scenes/enemy.tscn` — CharacterBody2D walker (Glitch Walker)
- `scenes/hopper.tscn` — CharacterBody2D jumping enemy (Glitch Hopper)
- `scenes/bat.tscn` — CharacterBody2D flying enemy (บัตบิต, sine hover)
- `scenes/charger.tscn` — CharacterBody2D dash enemy (ชาร์เจอร์, sight-locked dash)
- `scenes/boss_kubit.tscn` — mini-boss of level 8 (มินิบอสบิตคูผู้คุม, HP 3, dive attacks)
- `scenes/moving_platform.tscn` — AnimatableBody2D patrol platform
- `scenes/goal.tscn` — Area2D goal; `scripts/goal.gd` assembles a golden victory monument from
  Polygon2D/Sprite pieces at `_ready()` (pedestal + emblem + pole + orb + swaying banners + sparkles)
- `scenes/hazard.tscn` — Area2D spikes, **retired 2026-10-31** (kept on disk only; no longer spawned,
  no `$Hazards` in main.tscn, spikes removed from all levels per playtest feedback)
- `scripts/*.gd` — gameplay logic

## Systems
- 8 levels defined in LEVELS array (main.gd), loaded sequentially; levels 6-8 rename themes
  (ท่อระบายบิต / ท้องฟ้าเมฆเด้ง / ปราสาทบิตคู) via `bg`/`near` keys
- StaticBody2D platforms + AnimatableBody2D moving platforms
- Player controller: coyote time + jump buffer + variable height + asymmetric gravity +
  2-air-tier double jump (`MAX_AIR_JUMPS`/`AIR_JUMP_SCALE` in player.gd, resets on landing,
  `_air_ring` dust + SFX on air jumps)
- Camera2D smooth follow + bounds clamp + screen shake (trauma-based)
- Per-theme look: `_apply_level_look()` swaps far/near bg strips + sky Gradient + tile self_modulate
  tints (`_tile_tints_for`: sewer teal-moss / castle purple-dusk) + CanvasModulate tint +
  `_setup_weather()/_apply_weather()` CPUParticles2D (sewer drips / sky sparkles / castle embers)
- Per-theme music: `_apply_theme_music()` swaps Music stream (music.wav / music_sewer / music_sky / music_castle)
- Hero skins: `player.gd set_skin(idx)` + SKIN_SHEETS; chosen on title screen, persisted as `skin` in the save file
- Title menus: `title.gd` builds a 3-item keyboard menu + two bbcode panels (วิธีเล่น bestiary /
  Story) and a single-frame `AtlasTexture` skin preview
- Save schema v1 (hi_score, best_win_time, wins, plays, level, skin) atomic write

## Testing
- `godot --headless --path games/game1_coin_rush --import` must pass
- `godot --headless --path games/game1_coin_rush --script res://tools/test_game1.gd` — 124-assertion
  headless suite (level data, scenes, coins, goal monument, double jump, title menus, save round-trip,
  state reset); exit 0 = pass
- Headless smoke: `godot --headless --path games/game1_coin_rush res://scenes/main.tscn --quit-after 180`