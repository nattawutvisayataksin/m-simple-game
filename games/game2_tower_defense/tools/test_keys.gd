extends SceneTree
# เทสคีย์ลัด: กด B แล้วคลิกพื้นที่สนาม -> กด 2 สร้างปืนใหญ่
var _f := 0
var _main: Node2D

func _initialize() -> void:
	var main_scene: Node2D = load("res://scenes/main.tscn").instantiate()
	root.add_child(main_scene)
	_main = main_scene

func _seed_map() -> void:
	# Phase E: เกมเริ่มที่หน้าเลือกแผนที่ -> เลือกแผนที่ 0 เข้าสู่เกมจริง + ระงับนับถอยหลังคลื่น
	_main._start_map(0)
	_main._prep_t = 1e9
	if _main._gold != 0:
		print("TEST_KEYS FAIL game should start with zero gold")
		quit(1)
		return
	_main._gold = 180
	_main._update_gold()

func _press(code: int) -> void:
	var ev := InputEventKey.new()
	ev.keycode = code
	ev.pressed = true
	_main._unhandled_input(ev)

func _click(at: Vector2) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	ev.position = at
	_main._unhandled_input(ev)

func _process(_delta: float) -> bool:
	_f += 1
	if _f == 1:
		_seed_map()   # ต้องรอ _ready ของ main จบก่อน (_initialize ยังไม่มี layers)
	if _f == 2:
		_press(KEY_B)
		_click(Vector2(100, 100))
	if _f == 4:
		if _main._menu == null or _main._menu_mode != "build":
			print("TEST_KEYS FAIL free-placement menu missing")
			quit(1)
			return true
		_press(KEY_2)
	if _f >= 6:
		var ok: bool = _main._towers.size() == 1 and _main._towers[0].kind == _main.TowerScript.CANNON and _main._menu == null and _main._gold == 30
		if ok:
			print("TEST_KEYS PASS tower_built_gold=", _main._gold)
			quit(0)
		else:
			print("TEST_KEYS FAIL towers=", _main._towers.size(), " menu=", _main._menu, " gold=", _main._gold)
			quit(1)
	return false
