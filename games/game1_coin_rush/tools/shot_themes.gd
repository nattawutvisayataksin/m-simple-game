extends SceneTree
# ถ่ายภาพหน้าจอธีมใหม่ (ด่าน 6/7/8) เพื่อตรวจสายตา — รันแบบมีหน้าต่าง (ไม่ --headless):
#   godot --path games/game1_coin_rush --script res://tools/shot_themes.gd
# ออกที่ screenshots/level6.png .. level8.png ของโปรเจกต์
var frames := 0
var game: Node2D
var shots := [5, 6, 7]  # zero-based index ใน LEVELS: 5=ท่อระบาย 6=ท้องฟ้า 7=ปราสาท
var shot_i := 0

func _initialize() -> void:
	game = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(game)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://screenshots"))

func _process(_delta: float) -> bool:
	frames += 1
	if shot_i >= shots.size():
		quit()
		return true
	if frames == 10:
		game._load_level(shots[shot_i])
	if frames == 100:
		var img: Image = root.get_viewport().get_texture().get_image()
		var path := ProjectSettings.globalize_path("res://screenshots/level%d.png" % (shots[shot_i] + 1))
		img.save_png(path)
		print("SAVED: ", path)
		shot_i += 1
		frames = 0
	return false
