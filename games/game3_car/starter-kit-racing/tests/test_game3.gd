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
	var coins := game.get_node_or_null("Coins")
	var gates := game.get_node_or_null("Gates")
	var props := game.get_node_or_null("Props")
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
