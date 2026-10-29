# Game 2 — Handoff to OpenCode

Updated: 2026-10-29

## Current state

Game 2 is paused at the user's request after the latest build was opened for playtesting. Wait for the user's observations before changing gameplay or generating more assets.

The current build includes:

- Three tower types: archer, cannon, and mage; the mage's magic bypasses enemy armor.
- The stone golem, which has high physical resistance.
- A separate, smoothly rotating weapon layer on each tower. It tracks the selected enemy, waits until aimed, and spawns the projectile at the weapon muzzle; the tower base stays in place.
- The earlier fixes for the hidden third build site, build pads, purchase menu, and hero attack feedback.

The automated aiming test checks the rotation of all three weapon types. It does not replace a visual playtest of the artwork, turning feel, muzzle alignment, and combat balance.

## Resume checklist

1. Ask what the user noticed while playing, especially weapon turning, shot origin, tower visibility, and purchase flow.
2. Reproduce the reported issue in the running game or with a focused Godot test.
3. Make only the requested, relevant changes; update this folder's docs and tests.
4. Run all eight headless tests listed in [ARCHITECTURE.md](ARCHITECTURE.md).

## Run the game

Open `games/game2_tower_defense/project.godot` with Godot 4.7.2, then press **F6** to run the project or **F5** to run the configured main scene.

For a fresh checkout, import assets once before running headless tests:

```powershell
$godot = (Get-Command godot -ErrorAction Stop).Source # or set the installed Godot 4.7.2 executable path
$project = "games/game2_tower_defense"
& $godot --headless --path $project --import
```

The test loop and individual test coverage are in [ARCHITECTURE.md](ARCHITECTURE.md). Asset provenance and tools are in [ASSETS.md](ASSETS.md).
