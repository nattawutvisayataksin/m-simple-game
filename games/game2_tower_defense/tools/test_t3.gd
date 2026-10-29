extends SceneTree
# เทส T3 อัตโนมัติ 2 รอบ:
# รอบ 1 ธนู: ป้อมที่ (700,470) + กบเดินเข้ารัศมี -> ยิงโดน ตาย ได้ทอง +25
# รอบ 2 ปืนใหญ่: ระเบิดกระจุก -> มอนกลุ่มเพื่อนบ้านในรัศมีโหมดด้วย
# ผ่านครบรอบ = exit 0 (ผูก CI/บังกองก่อน commit)
# รัน: godot --headless --path tower-defend --script tools/test_t3.gd  (แนบ --path เต็มถ้าอยู่นอก res://)

var _main: Node2D
var _base_gold := 0
var _sim_t := 0.0
var _phase := 0            # 0 = ธนู, 1 = ปืนใหญ่
var _archer_done := false
var _pair_total := 0
var _pair_dead := 0

func _initialize() -> void:
	var main_scene: Node2D = load("res://scenes/main.tscn").instantiate()
	root.add_child(main_scene)
	_main = main_scene
	_base_gold = _main._gold

# ---- รอบ 1: ธนู ----
	var TowerScript: GDScript = load("res://scripts/tower.gd")
	var EnemyScript: GDScript = load("res://scripts/enemy.gd")
	var tower: Node2D = TowerScript.new()
	tower.setup(TowerScript.ARCHER, load("res://assets/art/gen/tower_archer.png"), 9.0, 0.5, 170.0, 400.0, 0.0)
	tower.position = Vector2(700, 470)
	_main.add_child(tower)
	var enemy: Node2D = EnemyScript.new()
	enemy.texture = load("res://assets/art/gen/frog.png")
	enemy.sheet = load("res://assets/art/gen/frog_sheet.png")
	enemy.waypoints = PackedVector2Array([Vector2(530, 545), Vector2(640, 545)])
	enemy.speed = 20.0
	enemy.max_hp = 27.0
	enemy.reward = 25
	enemy.died.connect(func(_r, _at): _archer_done = true)
	enemy.died.connect(_main._on_enemy_died)
	_main.add_child(enemy)

# ---- รอบ 2: ปืนใหญ่ + มอนคู่เพื่อน (เช็ค splash ไปวัดกันมอนถูกโหมดเพื่อนบ้าน) ----
	var cannon: Node2D = TowerScript.new()
	cannon.setup(TowerScript.CANNON, load("res://assets/art/gen/tower_cannon.png"), 30.0, 1.2, 200.0, 300.0, 70.0)
	cannon.position = Vector2(400, 470)
	_main.add_child(cannon)
	for x in [380.0, 430.0]:
		var e2: Node2D = EnemyScript.new()
		e2.texture = load("res://assets/art/gen/frog.png")
		e2.sheet = load("res://assets/art/gen/frog_sheet.png")
		e2.waypoints = PackedVector2Array([Vector2(x, 545), Vector2(x + 150.0, 545)])
		e2.speed = 12.0   # เดินช้าพอให้โดนลูกระเบิดก่อนไถลออก (150px = ~12.5 วิ)
		e2.max_hp = 24.0
		e2.reward = 10
		e2.died.connect(func(_r, _at): _pair_dead += 1)
		_pair_total += 1
		_main.add_child(e2)

func _process(delta: float) -> bool:
	_sim_t += delta
	if _archer_done and _main._gold >= _base_gold + 25:
		if _phase == 0:
			print("TEST_T3 archer PASS gold=%d (base %d) sim=%.1fs" % [_main._gold, _base_gold, _sim_t])
			_phase = 1
	if _phase >= 1 and _pair_dead >= _pair_total:
		print("TEST_T3 cannon-splash PASS pair_dead %d/%d gold=%d sim=%.1fs" % [_pair_dead, _pair_total, _main._gold, _sim_t])
		print("TEST_T3 ALL PASS")
		quit(0)
		return true
	if _sim_t > 15.0:
		print("TEST_T3 FAIL phase=%d archer=%s pair=%d/%d gold=%d (base %d) sim=%.1fs" % [_phase, _archer_done, _pair_dead, _pair_total, _main._gold, _base_gold, _sim_t])
		quit(1)
		return true
	return false
