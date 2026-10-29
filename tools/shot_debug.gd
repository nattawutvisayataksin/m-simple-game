extends SceneTree
# เครื่องมือวินิจฉัย (T5.1): เปิดฉากจริง -> สั่งสร้างป้อม + เปิดเมนูอัปเกรดค้าง -> แคปภาพจอ -> ออก
# รันแบบไม่ --headless เพื่อให้เรนเดอร์จริง: godot --path tower-defend --script tools/shot_debug.gd
var _t := 0.0
var _shot := false

func _initialize() -> void:
	var main: Node2D = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	# ลาน 0 = มีป้อม + เมนูอัปเกรดเปิดค้าง (ดูว่าตัวหนังสือ/ไอคอนถูกป้อมบดบังไหม)
	main._open_menu(0)
	main._build_tower(0, "archer")
	main._open_menu(0)   # คราวนี้ = built mode (อัปเกรด/ขาย)

func _process(delta: float) -> bool:
	_t += delta
	if _t > 1.5 and not _shot:
		_shot = true
		var img := root.get_texture().get_image()
		img.save_png("C:/Users/Administrator/AppData/Local/Temp/opencode/game_live.png")
		print("SHOT-SAVED ", img.get_width(), "x", img.get_height())
		quit(0)
		return true
	return false
