extends SceneTree
# ใน headless ไม่มีหน้าต่างรับ OS input; ตรวจ handler ด้วยอีเวนต์ที่มีทั้ง position และ global_position
var _f := 0
var _main: Node2D

func _initialize() -> void:
	var main_scene: Node2D = load("res://scenes/main.tscn").instantiate()
	root.add_child(main_scene)
	_main = main_scene

func _dispatch_click() -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	ev.position = Vector2(420, 615)
	ev.global_position = ev.position
	_main._unhandled_input(ev)

func _process(delta: float) -> bool:
	_f += 1
	if _f == 2:
		_dispatch_click()
	if _f >= 5:
		if _main._menu == null:
			print("TEST_MENU2 FAIL menu not opened after direct handler dispatch")
			quit(1)
		else:
			print("TEST_MENU2 PASS menu opened via handler")
			quit(0)
	return false
