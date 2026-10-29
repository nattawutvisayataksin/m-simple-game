extends SceneTree
## Test runner: Kubi Grand Prix (Game 3) - รัน headless:
## godot --headless --path . --script res://tests/test_game3.gd
## ครอบคลุม: โครงสนาม, เก็บเหรียญ, นับรอบ, respawn, ขับได้จริง

var frames := 0
var game: Node3D
var failures: Array = []
var passed: Array = []
var stage := 0
var drive_start := Vector3.ZERO


func _initialize() -> void:
	print("=== KubiGP test: boot")
	var packed: PackedScene = load("res://scenes/main.tscn")
	if packed == null:
		_check("main.tscn โหลดได้", false, "load fail")
		quit(1)
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	game = root.get_node("Main")
	if game == null:
		_check("หาโหนด Main ได้", false, "null")
		quit(1)


func _check(name: String, condition: bool, detail: String = "") -> void:
	if condition:
		passed.append(name)
		print("  PASS: ", name)
	else:
		failures.append(name)
		print("  FAIL: ", name, " ", detail)


func _process(_delta: float) -> bool:
	frames += 1
	if stage == 0 and frames >= 5:
		stage = 1
		_stage_structure()
	elif stage == 1:
		stage = 2
		_stage_coins()
	elif stage == 2:
		stage = 3
		_stage_laps()
	elif stage == 3:
		stage = 4
		_stage_respawn_setup()
	elif stage == 4 and frames > 300:
		stage = 5
		_stage_respawn_check()
	elif stage == 5:
		stage = 6
		_stage_drive_setup()
	elif stage == 6 and frames > 520:
		stage = 7
		_stage_drive_check()
		_finish()
	return false


# 1) โครงสร้างที่สร้างโดย game.gd

func _stage_structure() -> void:
	print("[1] โครงสร้างระบบเกม")
	var town := game.get_node_or_null("Town")
	var coins := game.get_node_or_null("Coins")
	var gates := game.get_node_or_null("Gates")
	var props := game.get_node_or_null("Props")
	var track_points: Array = town.call("get_track_points") if town != null else []
	_check("เมืองสร้างวงถนนครบ 42 จุด", track_points.size() == 42,
		"points=%d" % track_points.size())
	var decorations_clear := true
	var decoration_count := 0
	if town != null:
		for child in town.get_children():
			if not child.name.begins_with("TownDecor_"):
				continue
			decoration_count += 1
			for point in track_points:
				if Vector2(child.position.x, child.position.z).distance_to(Vector2(point.x, point.z)) < 5.0:
					decorations_clear = false
	_check("ของตกแต่ง 24 ชิ้นอยู่นอกเลนแข่ง", decoration_count == 24 and decorations_clear,
		"count=%d clear=%s" % [decoration_count, decorations_clear])
	var road: Node3D = town.get_node_or_null("Road_1_0") if town != null else null
	_check("โมเดลถนนขยายตามขนาดช่อง 7 ม.", road != null and road.scale.is_equal_approx(Vector3.ONE * 7.0))
	var road_surface: MeshInstance3D = town.get_node_or_null("RoadSurface_1_0") if town != null else null
	var road_mesh := road_surface.mesh as PlaneMesh if road_surface != null else null
	_check("ถนนมีผิวแอสฟัลต์และเส้นประ", road_mesh != null
		and road_mesh.size.is_equal_approx(Vector2(7.0, 7.0))
		and road_surface.get_node_or_null("LaneDash") != null)
	var road_collision: StaticBody3D = town.get_node_or_null("RoadCollision_1_0") if town != null else null
	var road_shape: CollisionShape3D
	if road_collision != null and road_collision.get_child_count() > 0:
		road_shape = road_collision.get_child(0) as CollisionShape3D
	var box_shape := road_shape.shape as BoxShape3D if road_shape != null else null
	_check("ถนนมี collider ครอบคลุมช่อง", box_shape != null
		and road_collision.position.y == 0.0
		and is_equal_approx(box_shape.size.x, 7.0)
		and is_equal_approx(box_shape.size.z, 7.0))
	var skyline_count := 0
	if town != null:
		for child in town.get_children():
			if child.name.begins_with("CitySkyline_"):
				skyline_count += 1
	_check("มีอาคารเมืองล้อมรอบสนาม", skyline_count == 10, "buildings=%d" % skyline_count)
	_check("Coins ถูกสร้าง", coins != null and coins.get_child_count() > 0,
		"children=%s" % (coins.get_child_count() if coins else -1))
	_check("Gates ครบ 3 ประตู", gates != null and gates.get_child_count() == 3,
		"children=%s" % (gates.get_child_count() if gates else -1))
	_check("Props ของประดับถูกวาง", props != null and props.get_child_count() > 0,
		"children=%s" % (props.get_child_count() if props else -1))
	if coins != null and coins.get_child_count() > 0:
		var coin: Area3D = coins.get_child(0)
		_check("เหรียญ set collision_mask=8", coin.collision_mask == 8)

	var next_gate: int = game.get("next_gate")
	_check("รอบเริ่ม 0/3", (game.get("laps") as int) == 0 and next_gate <= 1,
		"laps=%s next_gate=%s (spawn เส้นชัยขยับได้)" % [game.get("laps"), next_gate])
	# รถต้องถูกวางจุดสตาร์ตพอดีเส้นชัย (path[0])
	var sphere: RigidBody3D = game.get_node("Vehicle/Sphere")
	_check("รถถูกวางจุดเริ่ม", sphere.global_position.distance_to(game.get("_path_points")[0]) < 8.0,
		"sphere=%s" % sphere.global_position)


# 2) เก็บเหรียญ

func _stage_coins() -> void:
	print("[2] ระบบเหรียญทอง")
	var coins := game.get_node("Coins")
	var before: int = game.get("coins_collected")
	var count_before := coins.get_child_count()
	var coin: Area3D = coins.get_child(0)
	game.call("_collect_coin", coin)
	_check("เก็บเหรียญ +1", game.get("coins_collected") == before + 1)
	_check("เหรียญถูกลบออกเฉลียม", coins.get_child_count() == count_before - 1 or coin.is_queued_for_deletion())


# 3) นับรอบ

func _stage_laps() -> void:
	print("[3] ระบบนับรอบ")
	game.set("next_gate", 0)
	game.set("laps", 0)
	game.set("_passed_full_lap", false)
	game.call("_advance_gate", 1)   # กดผิดลำดับ - ต้องไม่นับ
	_check("ข้ามลำดับไม่นับ", (game.get("next_gate") as int) == 0)
	game.call("_advance_gate", 0)
	game.call("_advance_gate", 1)
	_check("ผ่าน 0->1 ยังไม่ครบรอบ", game.get("laps") == 0 and game.get("next_gate") == 2)
	game.call("_advance_gate", 2)
	_check("ครบ 0->1->2 รอบกลับ 0 แต่ยังไม่ +1", game.get("laps") == 0 and game.get("next_gate") == 0)
	# กลับมาแตะ 0 = +1 รอบ (3 รอบพอดี)
	for lap in 3:
		game.call("_advance_gate", 0)
		game.call("_advance_gate", 1)
		game.call("_advance_gate", 2)
		game.call("_advance_gate", 0)
	_check("ครบ 3 รอบ = ชนะ", game.get("laps") == 3 and game.get("race_finished") == true)


# 4) respawn เมื่อร่วง

func _stage_respawn_setup() -> void:
	print("[4] ระบบ respawn (ตั้ง: โยนรถลงเหว)")
	paused = false                   # เทสรอบก่อนหน้าชนะแล้ว pause เพื่อเล่นต่อต้องปลด
	game.set("race_finished", false)
	var sphere := game.get_node("Vehicle/Sphere")
	sphere.global_transform = Transform3D(Basis(), sphere.global_position + Vector3(0, -30, 0))
	drive_start = sphere.global_position


func _stage_respawn_check() -> void:
	var sphere := game.get_node("Vehicle/Sphere")
	var at_spawn: bool = sphere.global_position.distance_to(game.get("_spawn_point")) < 6.0
	print("    debug: elapsed=%s y=%s race_finished=%s" % [game.get("elapsed"), sphere.global_position.y, game.get("race_finished")])
	_check("รถกลับจุดเริ่มหลังร่วง", at_spawn, "pos=%s" % sphere.global_position)


# 5) ขับได้จริง (กดปุ่ม W)

func _stage_drive_setup() -> void:
	print("[5] ขับได้จริง (กด W 60 เฟรม)")
	Input.action_press("forward")
	drive_start = game.get_node("Vehicle/Sphere").global_position


func _stage_drive_check() -> void:
	Input.action_release("forward")
	var now: Vector3 = game.get_node("Vehicle/Sphere").global_position
	var moved: float = (now - drive_start).length()
	_check("รถวิ่งไปได้ > 2 ม.", moved > 2.0, "moved=%.2f" % moved)


func _finish() -> void:
	print("=== ผลรวม: %d PASS / %d FAIL" % [passed.size(), failures.size()])
	if failures.size() > 0:
		for f in failures:
			print("  FAILED: ", f)
		quit(1)
	else:
		print("ALL PASS - KubiGP core systems")
		quit(0)
