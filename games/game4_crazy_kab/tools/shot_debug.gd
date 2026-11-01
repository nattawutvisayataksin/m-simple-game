extends SceneTree
# shot_debug: render main scene into SubViewport; capture title/story/howto/guide screens + gameplay
# run WITHOUT --headless so rendering is real

var _t := 0.0
var _stage := 0
var _main: Node2D
var _sub: SubViewport

func _initialize() -> void:
	_sub = SubViewport.new()
	_sub.size = Vector2i(1152, 648)
	_sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_sub)
	_main = load("res://scenes/main.tscn").instantiate()
	_sub.add_child(_main)

func _snap(path: String) -> void:
	var img := _sub.get_texture().get_image()
	img.save_png(path)
	print("SHOT-SAVED ", path, " ", img.get_width(), "x", img.get_height())

func _hold_wa() -> void:
	var up := InputEventKey.new()
	up.keycode = KEY_W
	up.pressed = true
	Input.parse_input_event(up)
	var left := InputEventKey.new()
	left.keycode = KEY_A
	left.pressed = true
	Input.parse_input_event(left)

func _process(delta: float) -> bool:
	_t += delta
	match _stage:
		0:
			if _t > 0.8:
				_snap("C:/Users/Administrator/AppData/Local/Temp/opencode/game3_title.png")
				_main._click(1)   # story
				_stage = 1
		1:
			if _t > 1.4:
				_snap("C:/Users/Administrator/AppData/Local/Temp/opencode/game3_story.png")
				_main._click(2)   # howto
				_stage = 2
		2:
			if _t > 2.0:
				_snap("C:/Users/Administrator/AppData/Local/Temp/opencode/game3_howto.png")
				_main._click(3)   # guide
				_stage = 3
		3:
			if _t > 2.6:
				_snap("C:/Users/Administrator/AppData/Local/Temp/opencode/game3_guide.png")
				# จออู่ (SCR.OVER): จำลอง best ให้เห็นล็อกครบ + Lv + ซื้อไหว
				_main.best = {"best_cash": 1560, "best_rides": 11, "total_cash": 3400, "unlocked": ["kubi", "liz", "golem"], "upgrades": {"kubi": 2, "liz": 1, "golem": 0}, "car_pick": "liz"}
				_main._click(5)
				_stage = 4
		4:
			if _t > 3.2:
				_snap("C:/Users/Administrator/AppData/Local/Temp/opencode/game3_over.png")
				_main._click(0)   # back to title
				_stage = 5
		5:
			if _t > 3.6:
				_main._click(4)   # start play
				_stage = 6
		6:
			if _t > 4.0:
				_hold_wa()
				_stage = 7
		7:
			if _t > 6.0:
				var play: Node2D = _main.play_node
				print("SNAP6 time=%.2f pos=%s rot=%.2f" % [play.time_left, str(play.car.position), play.car.rotation])
				_snap("C:/Users/Administrator/AppData/Local/Temp/opencode/game3_play.png")
				play.night = true   # แคปโหมดกลางคืนต่อทันที
				_stage = 8
		8:
			if _t > 6.8:
				_snap("C:/Users/Administrator/AppData/Local/Temp/opencode/game3_night.png")
				_main._start_play(false, true)   # กะฝึกขับ: แถบบทสอนล่างจอ + ป้ายขั้น 1/3
				_stage = 9
		9:
			if _t > 7.6:
				_snap("C:/Users/Administrator/AppData/Local/Temp/opencode/game4_tutor.png")
				quit(0)
				return true
	return false
