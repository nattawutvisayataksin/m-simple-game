extends SceneTree
# เทสเมนูสร้างป้อม: จำลองคลิกลานทอง (420,615) -> ต้องมีแผงเมนูเด้งขึ้น
# (เรียก handler ใน _process หลังเข้า tree แล้ว - ไม่ใช่ _initialize)
var _f := 0
var _main: Node2D

func _initialize() -> void:
	var main_scene: Node2D = load("res://scenes/main.tscn").instantiate()
	root.add_child(main_scene)
	_main = main_scene

func _process(_delta: float) -> bool:
	_f += 1
	if _f == 1:
		# Phase E: เลือกแผนที่ 0 เข้าสู่เกมจริง — รอ _ready ของ main จบก่อน
		_main._start_map(0)
		_main._prep_t = 1e9
	if _f == 2:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.pressed = true
		ev.position = Vector2(420, 615)
		_main._unhandled_input(ev)   # เรียกสายประมวลคลิกตรง ๆ
	if _f >= 4:
		if _main._menu == null:
			print("TEST_MENU FAIL no menu; window=", root.size)
			quit(1)
		else:
			var kids := 0
			for c in _main._menu.get_children():
				kids += 1
			print("TEST_MENU PASS menu_n=", kids)
			quit(0)
	return false
