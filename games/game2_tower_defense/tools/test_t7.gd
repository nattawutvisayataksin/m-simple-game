extends SceneTree
# T7: verify each tower weapon smoothly turns toward its target.

var _main: Node2D
var _towers: Array[Node2D] = []
var _timer := 0.0

func _initialize() -> void:
	_main = load("res://scenes/main.tscn").instantiate()
	root.add_child(_main)

	var tower_script: GDScript = load("res://scripts/tower.gd")
	var tower_data: Array[Dictionary] = [
		{"kind": 0, "texture": "tower_archer.png", "position": Vector2(350, 300), "angle": PI * 0.5},
		{"kind": 1, "texture": "tower_cannon.png", "position": Vector2(500, 450), "angle": 0.0},
		{"kind": 2, "texture": "tower_mage.png", "position": Vector2(650, 300), "angle": -PI * 0.5},
	]
	for data in tower_data:
		var tower: Node2D = tower_script.new()
		tower.setup(
			int(data["kind"]),
			load("res://assets/art/gen/" + str(data["texture"])),
			1.0, 10.0, 180.0, 400.0, 0.0,
		)
		tower.position = data["position"]
		_main.add_child(tower)
		_towers.append(tower)

	var enemy_script: GDScript = load("res://scripts/enemy.gd")
	var enemy: Node2D = enemy_script.new()
	enemy.texture = load("res://assets/art/gen/frog.png")
	enemy.max_hp = 100000.0
	enemy.speed = 0.0
	enemy._progress = 1.0
	enemy.waypoints = PackedVector2Array([Vector2(500, 300), Vector2(501, 300)])
	_main.add_child(enemy)

func _process(delta: float) -> bool:
	_timer += delta
	if _timer < 0.5:
		return false

	var expected_angles: Array[float] = [PI * 0.5, 0.0, -PI * 0.5]
	for index in range(_towers.size()):
		var tower: Node2D = _towers[index]
		var angle_error := absf(wrapf(expected_angles[index] - tower._weapon_pivot.rotation, -PI, PI))
		if angle_error > 0.12:
			print("TEST_T7 FAIL tower=", index, " angle_error=", angle_error)
			quit(1)
			return true
		if tower._weapon_visual == null:
			print("TEST_T7 FAIL weapon visual missing for tower=", index)
			quit(1)
			return true

	print("TEST_T7 ALL PASS archer+cannon+mage aim toward targets")
	quit(0)
	return true
