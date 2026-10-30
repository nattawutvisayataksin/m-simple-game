extends SceneTree
# เทสทางลัดคีย์บอร์ด: กด 4 เปิดเมนูลานที่ 4 -> กด 2 สร้างปืนใหญ่ (เงินพอ 180>=150)
var _f := 0
var _main: Node2D

func _initialize() -> void:
	var main_scene: Node2D = load("res://scenes/main.tscn").instantiate()
	root.add_child(main_scene)
	_main = main_scene
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

func _process(_delta: float) -> bool:
	_f += 1
	if _f == 2:
		_press(KEY_4)
	if _f == 4:
		if _main._menu == null or _main._menu_spot != 3:
			print("TEST_KEYS FAIL menu_open_after_4 menu=", _main._menu, " spot=", _main._menu_spot)
			quit(1)
			return true
		_press(KEY_2)
	if _f >= 6:
		var ok: bool = _main._towers[3] != null and _main._menu == null and _main._gold == 30
		if ok:
			print("TEST_KEYS PASS tower_built_gold=", _main._gold)
			quit(0)
		else:
			print("TEST_KEYS FAIL built=", _main._towers[3], " menu=", _main._menu, " gold=", _main._gold)
			quit(1)
	return false
