extends SceneTree
# test_1_boot: load main scene, click into play, verify car + HUD alive (exit 0 = pass)

var _main: Node2D
var _sim_t := 0.0
var _sid := 0

func _initialize() -> void:
	var scene: PackedScene = load("res://scenes/main.tscn")
	_main = scene.instantiate()
	root.add_child(_main)

func _process(dt: float) -> bool:
	_sim_t += dt
	match _sid:
		0:
			if _main.screen != 0:   # title
				print("TEST_BOOT FAIL title screen=%s" % String(_main.screen))
				quit(1); return true
			_sid = 1
		1:
			if _sim_t > 0.2:
				_main._click(4)   # SCR.PLAY
				_sid = 2
		2:
			if _main.play_node != null and _main.play_node.car != null:
				if _main.play_node.time_left > 100.0 and _main.play_node.traffic.size() > 0:
					print("TEST_BOOT PASS play=%s car_at=%s time=%.1f" % [_main.play_node, _main.play_node.car.position, _main.play_node.time_left])
					print("TEST_BOOT ALL PASS")
					quit(0); return true
	if _sim_t > 10.0:
		print("TEST_BOOT FAIL timeout sid=%d play=%s screens=%s" % [_sid, _main.play_node, _main.screen])
		quit(1); return true
	return false
