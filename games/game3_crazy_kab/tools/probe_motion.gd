extends SceneTree
# probe motion + lifecycle: print state every 0.5s

var main: Node2D
var play: Node2D
var _t := 0.0
var _last_beat := -1

func _initialize() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)

func _report(tag: String) -> void:
	var pl: Node2D = main.play_node if main.play_node != null else null
	var pinfo: String = "none"
	if pl != null and not pl.is_queued_for_deletion():
		pinfo = "screen=%s playing=%s time=%.2f traffic0=%s rot=%.2f" % [pl.screen if false else "", pl.playing, pl.time_left, str(pl.traffic[0]["pos"]) if pl.traffic.size() > 0 else "-", pl.car.rotation]
	print("PROBE[%s] t=%.1f screen=%s play:%s" % [tag, _t, main.screen, pinfo])

func _process(dt: float) -> bool:
	_t += dt
	if main.screen == 0 and _t > 0.2:
		main._click(4)
		play = main.play_node
	if play != null and play.car != null and _t > 0.3:
		force_hold()
	var beat := int(_t / 0.5)
	if beat != _last_beat:
		_last_beat = beat
		_report("beat")
	if _t > 2.5:
		# final verdict: car must have moved & rotated via held input
		if play == null:
			print("PROBE VERDICT: FAIL (play gone)")
			quit((1))
			return true
		force_hold()
		var pos: Vector2 = play.car.position
		var rot: float = play.car.rotation
		var moved: bool = pos.distance_to(Vector2(170, 110)) > 40.0
		print("PROBE final car_pos=%s rot=%.2f time=%.2f" % [str(pos), rot, play.time_left])
		var ok: bool = moved and play.time_left < 119.5
		print("PROBE VERDICT: %s" % ("PASS" if ok else "FAIL"))
		quit((0 if ok else 1))
		return true
	return false

func force_hold() -> void:
	# hold inputs via Input singleton emulation (parse events) so play._serve_input sees them
	var up := InputEventKey.new()
	up.keycode = KEY_W
	up.physical_keycode = KEY_W
	up.pressed = true
	Input.parse_input_event(up)
	var left := InputEventKey.new()
	left.keycode = KEY_A
	left.pressed = true
	Input.parse_input_event(left)
