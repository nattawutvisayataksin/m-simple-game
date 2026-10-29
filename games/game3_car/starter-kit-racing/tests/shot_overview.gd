extends SceneTree
var frames := 0
var game: Node3D

func _initialize() -> void:
	game = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(game)

func _process(_delta: float) -> bool:
	frames += 1
	if frames == 45:
		var cam: Camera3D = _find_camera(game)
		if cam != null:
			cam.global_transform = Transform3D(Basis(), Vector3(49, 100, 10))
			cam.look_at(Vector3(49, 0, 32))
		if game.get("vehicle_model") == null:
			pass
	if frames == 80:
		var img: Image = root.get_viewport() .get_texture().get_image()
		img.save_png("C:/m-simple-game/games/game3_car/starter-kit-racing/screenshots/overview.png")
		quit()
	return false

func _find_camera(node: Node) -> Camera3D:
	if node is Camera3D:
		return node
	for ch in node.get_children():
		var r := _find_camera(ch)
		if r != null:
			return r
	return null
