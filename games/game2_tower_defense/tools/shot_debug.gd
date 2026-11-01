extends SceneTree
# เครื่องมือวินิจฉัย (T5.1): เปิดฉากจริง -> สั่งสร้างป้อม + เปิดเมนูอัปเกรดค้าง -> แคปภาพจอ -> ออก
# รันแบบไม่ --headless เพื่อให้เรนเดอร์จริง: godot --path tower-defend --script tools/shot_debug.gd
var _t := 0.0
var _shot := false
var _main: Node2D

func _initialize() -> void:
	_main = load("res://scenes/main.tscn").instantiate()
	root.add_child(_main)

func _process(delta: float) -> bool:
	_t += delta
	if _t > 0.2 and _main._state == "title":
		_main._start_map(0)
		_main._gold = 300
		_main._build_free_tower(Vector2(100, 100), "archer")
		_main._open_tower_menu(_main._towers[0])
	if _t > 1.5 and not _shot:
		_shot = true
		var img := root.get_texture().get_image()
		img.save_png("C:/Users/Administrator/AppData/Local/Temp/opencode/game_live.png")
		print("SHOT-SAVED ", img.get_width(), "x", img.get_height())
		quit(0)
		return true
	return false
