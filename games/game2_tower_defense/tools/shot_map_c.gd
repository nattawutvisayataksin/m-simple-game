extends SceneTree

var _elapsed := 0.0
var _main: Node2D
var _started := false

func _initialize() -> void:
	_main = load("res://scenes/main.tscn").instantiate()
	root.add_child(_main)

func _process(delta: float) -> bool:
	_elapsed += delta
	if _elapsed > 0.2 and _main._state == "title":
		_main._start_map(2)
		# Showcase three legal free-build positions across the map's clearings.
		_main._gold = 600
		_main._update_gold()
		_main._build_free_tower(Vector2(110, 370), "archer")
		_main._build_free_tower(Vector2(560, 585), "cannon")
		_main._build_free_tower(Vector2(940, 330), "mage")
		_main._start_wave()
		_started = true
	if _started and _elapsed > 3.0:
		var image := root.get_texture().get_image()
		if image == null:
			push_error("Could not capture the rendered viewport")
			quit(1)
			return true
		image.save_png("res://screenshots/map_c_prototype.png")
		print("MAP_C_SCREENSHOT ", image.get_width(), "x", image.get_height())
		quit(0)
		return true
	return false
