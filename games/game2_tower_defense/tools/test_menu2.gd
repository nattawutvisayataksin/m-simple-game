extends SceneTree
# เทสเส้นส่งเหตุการลิปจริง: ส่งอีเวนต์คลิกผ่าน Input.parse_input_event
# (ทางที่เปิดเกมใช้) ไหลเข้า viewport -> main._unhandled_input -> เมนูเด้ง
var _f := 0
var _main: Node2D

func _initialize() -> void:
	var main_scene: Node2D = load("res://scenes/main.tscn").instantiate()
	root.add_child(main_scene)
	_main = main_scene
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	ev.position = Vector2(420, 615)
	ev.global_position = ev.position
	Input.parse_input_event(ev)

func _process(delta: float) -> bool:
	_f += 1
	if _f >= 5:
		if _main._menu == null:
			print("TEST_MENU2 FAIL menu not opened after real event dispatch")
			quit(1)
		else:
			print("TEST_MENU2 PASS menu opened via real event")
			quit(0)
	return false
