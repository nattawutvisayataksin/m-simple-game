extends SceneTree
# ถ่ายภาพหน้าจอ QA ของฟีเจอร์ล่าสุด — รันแบบมีหน้าต่าง (ไม่ --headless):
#   godot --path games/game1_coin_rush --script res://tools/shot_new_features.gd
# ออกที่ screenshots/ ของโปรเจกต์: title_test_panel.png (แผงเลือกด่าน) / hud_hearts.png (HUD โอกาส 2)
var frames := 0
var title_ui: Control
var game: Node2D

func _initialize() -> void:
	title_ui = (load("res://scenes/title.tscn") as PackedScene).instantiate()
	root.add_child(title_ui)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://screenshots"))

func _process(_delta: float) -> bool:
	frames += 1
	if frames == 20:
		# เปิดแผงโหมดทดสอบ (เลือกด่าน 1-8) เหมือนกดเมนูตัวที่ 4
		title_ui._sel = 3
		title_ui._confirm()
	if frames == 70:
		_save("screenshots/title_test_panel.png")
		# ต่อ: เข้าเกมเหมือนเลือกด่าน 1 แล้วบังคับจอแพ้สั้นเหลือโอกาส 2 (ดูหัวใจ pink HUD)
		game = (load("res://scenes/main.tscn") as PackedScene).instantiate()
		root.add_child(game)
	if frames == 130:
		game._lose("โดนศัตรู!")
	if frames == 190:
		_save("screenshots/hud_hearts.png")
		quit()
		return true
	return false

func _save(rel: String) -> void:
	var img: Image = root.get_viewport().get_texture().get_image()
	var path := ProjectSettings.globalize_path("res://" + rel)
	img.save_png(path)
	print("SAVED: ", path)
