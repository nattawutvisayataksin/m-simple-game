# Handoff — Game 1 (Kubi Coin Dash)

Updated: 2026-10-31

## Current status

The project is a playable eight-level 2D platformer. The title menu has three items (เริ่มเล่น /
วิธีเล่น with controls + hero & monster bestiary / Story) driven by ↑↓ + Space/Enter + Esc, and also
offers a hero-skin chooser (Left/Right, saved into the save file, with a correct single-frame preview);
levels include coins, walkers, a jumping
Hopper enemy, a flying Bat (sine hover), a sight-locked Charger that dashes when it sees the
player on the same row and is stunned after hitting a wall, and a level-8 mini-boss (มินิบอส
บิตคูผู้คุม: hover, periodic dive attacks, 3 stomps to defeat, coin burst reward). There are
moving platforms, per-theme backdrops with tile tints/weather/music, and fall detection
in the ravine/castle stages. The player has a 2-air-tier double jump, can stomp enemies,
collect coins, restart a level, and
return to the title menu. Red ground spikes were removed from every level on 2026-10-31
per playtest feedback; each level ends at a golden victory-flag monument instead of the old flag sprite.

Godot 4.7.2 script parse checks and a 180-frame headless smoke run of `scenes/main.tscn` both passed. This does not replace a GUI playtest. Full-lap/level completion, visual readability, and controller feel still need human verification.

## Run and controls

```powershell
$godot = (& .\shared\find_godot.ps1)   # หา Godot อัตโนมัติ — ไม่ hardcode path (docs/MACHINE_PATHS.md)
& $godot --path games/game1_coin_rush
```

The project starts at `scenes/title.tscn`. Controls:

- A/D or Left/Right: move — on the title screen they change the hero skin
- Up/Down (or W/S): choose a title-menu item (เริ่มเล่น / วิธีเล่น / Story); Space/Enter confirms; Esc closes an open info panel
- Space/W/Up: jump — press again in midair for up to 2 extra air jumps (double jump); hold longer to jump higher
- Shift: sprint
- R: restart the current level
- Esc: return to the title menu

## Gameplay and implementation

- `scripts/main.gd` defines eight level layouts (levels 6-8 use the sewer/sky/castle themes) and builds platforms, pickups, enemies, moving platforms, HUD, level transitions, per-theme backgrounds/weather, win/loss, and save data. The red ground spikes (hazards) were removed from every level on 2026-10-31 per playtest feedback; `scenes/hazard.tscn` is kept idle on disk only.
- `scripts/player.gd` implements acceleration-based movement, sprint, variable jump height, coyote time, jump buffering, a 2-air-tier double jump (MAX_AIR_JUMPS + ring dust + SFX on air jumps), the run/air/idle sprite animation, and `set_skin(idx)` for hero skins.
- `scripts/enemy.gd` is the walking Glitch Bug; `scripts/enemy_hopper.gd` and `scenes/hopper.tscn` add the jumping, edge-aware Hopper; `scripts/bat.gd` + `scenes/bat.tscn` add the flying บัตบิต (sine hover, stompable); `scripts/charger.gd` + `scenes/charger.tscn` add the charging ชาร์เจอร์; `scripts/boss_kubit.gd` + `scenes/boss_kubit.tscn` add the level-8 mini-boss (HP 3, dive, coin burst via main's `_on_boss_defeated`). All can be stomped.
- Levels 4, 5, and 8 have broken ground sections; falling below the level bounds causes a loss.
- The old 32×64 flag sprite goal was retired; `scripts/goal.gd` now assembles a golden monument (stone pedestal + city-coin emblem + dark pole + gold sphere + two swallowtail banners with red stripes that sway + gold sparkles).
- `scripts/title.gd` and `scenes/title.tscn` provide the title screen with a 3-item menu (เริ่มเล่น / วิธีเล่น with controls + hero & monster bestiary / Story), keyboard-driven (↑↓ + Space/Enter confirm, Esc closes panels), correct single-frame skin previews via AtlasTexture, saved-stat display, and the skin chooser (Left/Right or A/D, persisted as `skin` in the save file).
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

It runs 124 assertions over level data, all scene loads, coin/gold values, the goal-flag monument
structure, the double-jump air-jump budget, the title menu/panels/skin preview, save-file round-trip
(including the `skin` field), and state reset on level reload — last run: 124 PASS / 0 FAIL.
Run it after any change to `scripts/` or level data; it does not yet replace visual playtesting.

## Before calling it playtested

1. Play through all eight levels from the title screen; verify the ordered transitions and the final win on level 8 (ปราสาทบิตคู).
2. Verify Walker/Hopper/Bat/Charger stomps, side hits, Charger wall-stun behavior, the mini-boss (3 stomps + dive telegraphs + coin burst), timer loss, and ravine fall behavior (levels 4, 5, 8).
3. Check the double jump in real falls (jump again twice midair to climb back), moving-platform jumps, sprint gaps, HUD, save/stat display, restart, and return-to-title behavior.
4. Try all five hero skins in the title chooser (preview shows a standing frame, not a stretched sheet) and both info panels (วิธีเล่น / Story); confirm the choice persists after restarting the game.
5. Levels 6-8, the Bat, the Charger, the double jump, the new goal monument, and the title menus are new content generated without a human playtest — prioritize playing them first.

Preserve vendor license notices and asset attributions. Keep the active project at `games/game1_coin_rush`; do not confuse it with other game projects in the repository.

## Session log 2026-10-30 (all commits pushed to origin/main)

- `e7b8307` monsters Bat (บัตบิต) + Charger (ชาร์เจอร์), levels 6-8 (ท่อระบาย/ท้องฟ้า/ปราสาท), theme art generator, headless suite
- `66fd2a6` hero skins (title chooser, saved in save) + per-theme weather/tint ambience
- `848c969` PLAY.md full rewrite (story/controls/monsters/levels/skins)
- `19d2b63` docs sync: ARCHITECTURE/HANDOFF/GDD/README/ASSET_MANIFEST
- `1299f62` per-theme music (sewer 90bpm / sky 126bpm / castle 105bpm), `_apply_theme_music`
- `9ab9521` skins 3→5 (ม่วงราตรี/ใบไม้ระยิบ), test watchdog hardening
- `e20aec3` theme tile tints (`_tile_tints_for`) + visual QA screenshots (`tools/shot_themes.gd`)
- `c1b807a` level-8 mini-boss บิตคูผู้คุม (HP 3, dive, coin burst) + `tools/shot_boss.gd`
- `77ec8f7` finale win screen (stats + coin rain)
- Last verified state: `test_game1.gd` 104 PASS / 0 FAIL; all headless smokes clean. New content NOT yet played by a human — see the checklist above.

## Session log 2026-10-31 (playtest feedback fix, all commits pushed to origin/main)

First human playtest feedback (5 items) — all implemented and covered by the test suite:

1. Red ground spikes removed from every level (LEVELS key `hazards` deleted, `$Hazards` node removed,
   spawn/cleanup/handler code deleted; `scenes/hazard.tscn` kept idle on disk only).
2. Goal rebuilt as a golden victory-flag monument in `scripts/goal.gd` (stone pedestal + city-coin
   emblem + dark pole with gold bands + gold orb + crossbar + two swallowtail cloth banners with a
   red stripe that sway via a `Sway` node + floating `GoldSparkles`); `goal.tscn` is now script +
   32×64 collision only; `goal_flag.png` kept but unused.
3. Title skin preview fixed — `AtlasTexture` cropping the standing frame `Rect2(512,0,64,64)`
   (frame 9 of the 576×64 sheets) instead of stretching the whole sheet.
4. Title screen now has a 3-item keyboard menu (เริ่มเล่น / วิธีเล่น with controls + hero &
   monster bestiary with sprite icons / Story) — panels are bbcode RichTextLabels, ↑↓+Space to
   navigate, Esc/Space to close.
5. Double jump: 2 midair air jumps (`MAX_AIR_JUMPS = 2`, `AIR_JUMP_SCALE = 0.9`), resets on landing,
   with an air-ring dust puff + SFX per air jump; ground/coyote jumps never consume the air budget.

- Test suite extended: `test_game1.gd` now prints **124 assertions**, covered new goal probe
  (deferred to first `_process` frame because `_initialize` runs before `_ready`), double-jump sim
  (air state forced with a pre-step so `is_on_floor()` is not stale), and title menu/preview checks —
  **124 PASS / 0 FAIL**, headless parse + 180-frame smoke clean.
- Docs synced: GDD/PLAY/ARCHITECTURE/HANDOFF.
- Still awaiting a human playtest of the new mechanics (see checklist above).
