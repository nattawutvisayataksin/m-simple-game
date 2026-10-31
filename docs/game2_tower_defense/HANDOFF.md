# Game 2 — Handoff to OpenCode

Updated: 2026-10-31

## Current state

The 12-hour autonomous session finished Phases A–E on this game (see [GDD.md](GDD.md) Section 9 and [ROADMAP_12H.md](ROADMAP_12H.md)). All suites pass 12/12 (exit 0), and real-screen checks were done with `tools/shot_debug.gd` after every phase.

The current build includes:

- Game boots into a title/map-select screen ("หอคอยคู่ฟ้า") with two maps: Map A "ป่า Kubi" and Map B "สุสานหลวง" (graveyard gate at top-left, road skirts the ponds to the castle door at right). Each map button shows the best wave reached (and a ★ when cleared) from an atomic save at `user://td_best.json`.
- Five game states: `title → prep ⇄ wave → won/lost`. Map switching swaps background (auto-scaled), road, tower spots, portal/castle markers, and the hero's home/respawn point.
- Four tower lines (archer, cannon, mage, barracks with blocking soldiers + rally point), free placement with **B**, per-tower targeting modes (Close-to-castle / First-entered / Strongest / Weakest) via button or key 4, wave-preview icon row, juice (screen shake, explosion particles, red hurt vignette).
- 13 hard-counter waves: flying bats (cannon/soldiers can't hit), splitting slimes, healing shamans, armored golems, final boss KUBIT with red HP bar and on-screen warning.
- Full audio: two-crossfade music moods + 14 synthesized SFX.
- Game-over summary (kills, total gold, wave reached, "สถิติใหม่!" when the best is beaten) — tests (test_t4/test_t11) back up and restore the player save file so runs stay clean.

## Resume checklist

1. Run all twelve headless tests listed in [ARCHITECTURE.md](ARCHITECTURE.md).
2. Play both maps; tune `PATH_B` / `TOWER_SPOTS_B` in `scripts/main.gd` if the Director wants different routing against the generated background art.
3. Phase F (docs) is done for GDD/ARCHITECTURE/ASSETS/HANDOFF/ROADMAP; no further doc debt known.
4. PixelLab Key C has 31/40 generations left — spend only on key visuals.

## Run the game

Open `games/game2_tower_defense/project.godot` with Godot 4.7.2, then press **F6** to run the project or **F5** to run the configured main scene.

For a fresh checkout, import assets once before running headless tests (find Godot with `shared/find_godot.ps1` on this machine):

```powershell
$godot = (Get-Command godot -ErrorAction Stop).Source # or set the installed Godot 4.7.2 executable path
$project = "games/game2_tower_defense"
& $godot --headless --path $project --import
```

The test loop and individual test coverage are in [ARCHITECTURE.md](ARCHITECTURE.md). Asset provenance and tools are in [ASSETS.md](ASSETS.md).
