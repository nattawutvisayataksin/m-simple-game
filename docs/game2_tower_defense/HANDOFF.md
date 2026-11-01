# Game 2 — Handoff to OpenCode

Updated: 2026-11-01

## Current state

Playable tower defense; automatic suites pass **11/11** (test_t3–t11 + keys + menu/menu2 — all exit 0). The game boots into a title/map-select screen ("หอคอยคู่ฟ้า") with two maps (Map A "ป่า Kubi", Map B "สุสานหลวง"), a hero choice (Kubi เดิม / อัศวินดาบแสง — `scripts/hero_blade.gd`), and shows each map's best wave reached (★ when cleared) from the atomic save at `user://td_best.json` (stale saves recorded up to 8 waves are clamped on display).

- **Wave table = 2 waves** (player request, 2026-11-01): Wave 1 = rushing horde of 100 (frog 40 + 5 other kinds ×12, **0.42 s spawn gap**); Wave 2 = all kinds (77) + **3 KUBIT bosses**. Per-wave spawn gap via `WAVE_GAPS` in `scripts/main.gd`.
- States `title → prep ⇄ wave → won/lost`; free tower placement with **B**; 4 targeting modes per tower; wave preview icon row; juice (shake/particles/red border); victory/defeat stats screen.

## Run

```powershell
$godot = (& .\shared\find_godot.ps1)
& $godot --path games/game2_tower_defense
```

## Notes

- Open work items from the human playtest: [PLAYTEST_NOTES.md](PLAYTEST_NOTES.md) — procedural road blends badly with map art; monster/boss movement feels stiff.
- PixelLab Key C has **21/40** generations left (verified `get_balance` 2026-11-01) — spend only on key visuals; quota policy and proven lessons: [../ASSET_MANIFEST.md](../ASSET_MANIFEST.md).
- Test suite + visual check commands: `docs/COMMANDS.md` §4; real-screen verification via `tools/shot_debug.gd`.
