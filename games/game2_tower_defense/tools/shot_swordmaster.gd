extends SceneTree
## Visual preview for the alternate hero. Captures one live sword slash in Map C.

var _elapsed := 0.0
var _main: Node2D
var _started := false
var _stage := 0
var _walk_start := Vector2.ZERO
var _target: Variant

func _initialize() -> void:
	_main = load("res://scenes/main.tscn").instantiate()
	root.add_child(_main)

func _process(delta: float) -> bool:
	_elapsed += delta
	if not _started and _elapsed > 0.2 and _main._state == "title":
		var title_image := root.get_texture().get_image()
		if title_image != null:
			title_image.save_png("res://screenshots/hero_select_preview.png")
		_main._choose_hero("swordmaster")
		_main._start_map(2)
		_main._hero.position = Vector2(470.0, 350.0)
		_main._hero.move_to(Vector2(548.0, 350.0))
		_walk_start = _main._hero.position
		_main._spawn_kind("frog")
		for enemy in get_nodes_in_group("enemies"):
			if enemy is Node2D:
				_target = enemy
				enemy.position = Vector2(820.0, 350.0)
				enemy.speed = 0.0
				enemy.max_hp = 1000.0
				enemy._hp = 1000.0
		_stage = 1
		_started = true
	if _stage == 1 and _elapsed > 0.48:
		var walk_distance: float = _main._hero.position.distance_to(_walk_start)
		if walk_distance < 8.0:
			push_error("Swordmaster did not move: %.1f px" % walk_distance)
			quit(1)
			return true
		var walk_image := root.get_texture().get_image()
		walk_image.save_png("res://screenshots/swordmaster_walk_preview.png")
		print("SWORDMASTER_WALK PASS ", snappedf(walk_distance, 0.1), "px")
		_main._hero.move_to(_main._hero.position)
		_main._hero._command_marker_t = 0.0
		_target.position = _main._hero.position + Vector2(72.0, 0.0)
		_main._hero._attack_cd = 0.08
		_stage = 2
	if _stage == 2 and _elapsed > 0.82:
		if _main._hero._swing_t <= 0.0 or _target._hp >= 1000.0:
			push_error("Swordmaster attack did not register: swing=%.2f hp=%.1f" % [_main._hero._swing_t, _target._hp])
			quit(1)
			return true
		var image := root.get_texture().get_image()
		if image == null:
			push_error("Could not capture the swordmaster preview")
			quit(1)
			return true
		image.save_png("res://screenshots/swordmaster_preview.png")
		print("SWORDMASTER_ATTACK PASS hp=", snappedf(_target._hp, 0.1), " swing=", snappedf(_main._hero._swing_t, 0.01), "s; preview=", image.get_width(), "x", image.get_height())
		quit(0)
		return true
	return false
