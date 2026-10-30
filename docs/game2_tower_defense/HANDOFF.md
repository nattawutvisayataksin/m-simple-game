# Game 2 — Handoff to OpenCode

Updated: 2026-10-30

## Current state

The latest Game Director request is implemented in the existing Godot 4.7.2 project. No new art generation was needed.

The current build includes:

- Three tower types: archer, cannon, and mage; the mage's magic bypasses enemy armor.
- The stone golem, which has high physical resistance.
- A separate, smoothly rotating weapon layer on each tower. It tracks the selected enemy, waits until aimed, and spawns the projectile at the weapon muzzle; the tower base stays in place.
- The earlier fixes for the hidden third build site, build pads, purchase menu, and hero attack feedback.
- Kubi starts at 0 gold; kills award bounty. Right-click ground to move smoothly and right-click an enemy to pursue it.
- The road now runs from the upper-left portal through a longer serpentine route to the castle entrance at the upper-right side of the map.
- Press **B**, then click valid grass to place a tower away from roads, gates, fixed pads, and other towers. Click any placed tower to upgrade or sell it.

The automated tests cover zero starting gold, hero kill income, free placement and overlap rejection, tower upgrade/sale, and respawn. A visual playtest is still useful for confirming the route overlay and hero movement feel.

## Resume checklist

1. Run all eight headless tests listed in [ARCHITECTURE.md](ARCHITECTURE.md).
2. Play the game and tune the new path/placement bounds if the Director reports visual or balance issues.

## Run the game

Open `games/game2_tower_defense/project.godot` with Godot 4.7.2, then press **F6** to run the project or **F5** to run the configured main scene.

For a fresh checkout, import assets once before running headless tests:

```powershell
$godot = (Get-Command godot -ErrorAction Stop).Source # or set the installed Godot 4.7.2 executable path
$project = "games/game2_tower_defense"
& $godot --headless --path $project --import
```

The test loop and individual test coverage are in [ARCHITECTURE.md](ARCHITECTURE.md). Asset provenance and tools are in [ASSETS.md](ASSETS.md).
