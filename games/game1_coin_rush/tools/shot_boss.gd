extends SceneTree
# ถ่ายมินิบอสด่าน 8 — รัน: godot --path games/game1_coin_rush --script res://tools/shot_boss.gd
var frames := 0
var game: Node2D

func _initialize() -> void:
	game = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(game)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://screenshots"))

func _process(_delta: float) -> bool:
	frames += 1
	if frames == 25:
		game._load_level(7)
	if frames == 60:
		# ลากผู้เล่นไปยืนบนแท่นใกล้บอส (ห่างศัตรูพื้น) เพื่อในช็อตเห็นทั้งคู่
		game.player.position = Vector2(3260, 420)
	if frames == 110:
		var img: Image = root.get_viewport().get_texture().get_image()
		img.save_png(ProjectSettings.globalize_path("res://screenshots/boss.png"))
		print("SAVED: boss.png")
		quit()
		return true
	return false
