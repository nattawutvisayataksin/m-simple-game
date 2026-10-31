extends SceneTree
# เทส Phase B: ค่ายทหาร + ทหารบล็อกทาง
# รอบ 1: ค่ายเกิดทหาร → กบถูกบล็อก (progress หยุดนิ่ง) → ทหารฟากบตาย → ได้ทอง
# รอบ 2: โกเลมฟาดหนักฆ่าทหาร → respawn ภายใน 8 วิ
# รอบ 3: อัปเกรดค่าย Lv2 → มีทหาร 2 ตน
# ผ่านครบ = exit 0

var _main: Node2D
var _t := 0.0
var _phase := 0
var _frog: Node2D
var _bruiser: Node2D
var _blocked_progress := -1.0
var _frog_died := false
var _gold_after_frog := 0
var _soldier_death_t := -1.0
var _respawn_wait := 0.0

func _initialize() -> void:
	_main = load("res://scenes/main.tscn").instantiate()
	root.add_child(_main)
	_main._state = "prep"          # กัน wave จริงแทรกสายเทส
	_main._prep_t = 1e9
	_main._gold = 500
	_main._update_gold()
	_main._build_tower(0, "barracks")
	if _main._towers[0] == null or _main._towers[0].kind != 3:
		print("TEST_T8 FAIL barracks build")
		quit(1)

func _live(idx: int) -> Node2D:
	var s = _main._towers[0]._soldiers[idx]
	if s != null and is_instance_valid(s) and not s.dead:
		return s
	return null

func _live_count() -> int:
	var cnt := 0
	for i in range(2):
		if _live(i) != null:
			cnt += 1
	return cnt

func _process(delta: float) -> bool:
	_t += delta
	var tower: Node2D = _main._towers[0]
	match _phase:
		0:
			if _live(0) != null:
				print("TEST_T8 spawn PASS soldier_at=%.0f,%.0f rally=%.0f,%.0f" % [
					_live(0).position.x, _live(0).position.y,
					tower.rally_point.x, tower.rally_point.y])
				_spawn_frog()
				_phase = 1
			elif _t > 6.0:
				print("TEST_T8 FAIL soldier never spawned")
				quit(1)
		1:
			if _frog == null or not is_instance_valid(_frog) or _frog_died:
				print("TEST_T8 block+kill PASS gold=%d (เริ่ม %d)" % [_main._gold, 500])
				_gold_after_frog = _main._gold
				_setup_bruiser()
			else:
				if _frog.blocker != null:
					if _blocked_progress < 0.0:
						_blocked_progress = _frog._progress
					if _frog._progress > _blocked_progress + 20.0:
						print("TEST_T8 FAIL blocker present but frog advanced")
						quit(1)
						return true
			if _phase == 1 and _t > 20.0:
				print("TEST_T8 FAIL frog not blocked/killed in time prog=%.0f" % (_blocked_progress if _blocked_progress > 0.0 else _frog._progress))
				quit(1)
		2:
			# สถานการณ์: โกเลมฟาดหนัก (melee 300) — ทหารต้องตายแล้วฟื้น
			if _soldier_death_t < 0.0 and _live_count() == 0:
				_soldier_death_t = _t
			if _soldier_death_t > 0.0 and _t > 20.0:
				print("TEST_T8 FAIL soldier never respawned")
				quit(1)
				return true
			if _soldier_death_t > 0.0 and _live_count() >= 1:
				var dt: float = _t - _soldier_death_t
				# respawn ตั้ง 6 วิ เผื่อ sim สั้นขอนาง
				if _bruiser != null and is_instance_valid(_bruiser):
					_bruiser.queue_free()
				if dt <= 8.0:
					print("TEST_T8 respawn PASS after %.1fs" % dt)
					_phase = 3
				else:
					print("TEST_T8 FAIL respawn slow %.1fs" % dt)
					quit(1)
					return true
		3:
			_main._open_tower_menu(tower)
			_main._upgrade_selected_tower()
			if tower.level != 2:
				print("TEST_T8 FAIL upgrade barracks")
				quit(1)
				return true
			_phase = 4
			_wait_t = _t
		4:
			if _live_count() >= 2:
				print("TEST_T8 upgrade-2-soldiers PASS count=%d" % _live_count())
				print("TEST_T8 ALL PASS")
				quit(0)
				return true
			if _t - _wait_t > 5.0:
				print("TEST_T8 FAIL lvl2 soldier count=%d (ต้อง 2)" % _live_count())
				quit(1)
				return true
	if _t > 50.0:
		print("TEST_T8 FAIL global timeout phase=%d" % _phase)
		quit(1)
	return false

var _wait_t := 0.0

func _spawn_frog() -> void:
	var rally: Vector2 = _main._towers[0].rally_point
	var EnemyScript: GDScript = load("res://scripts/enemy.gd")
	_frog = EnemyScript.new()
	_frog.texture = load("res://assets/art/gen/frog.png")
	_frog.sheet = load("res://assets/art/gen/frog_sheet.png")
	_frog.waypoints = PackedVector2Array([rally + Vector2(140.0, 0.0), rally - Vector2(170.0, 0.0)])
	_frog.speed = 26.0
	_frog.max_hp = 16.0
	_frog.reward = 15
	_frog.body_bottom_row = 59
	_frog.melee_dmg = 3.0
	_frog.died.connect(func(_r, _at): _frog_died = true)
	_main.add_child(_frog)

func _setup_bruiser() -> void:
	var rally: Vector2 = _main._towers[0].rally_point
	var EnemyScript: GDScript = load("res://scripts/enemy.gd")
	_bruiser = EnemyScript.new()
	_bruiser.texture = load("res://assets/art/gen/stone_golem.png")
	_bruiser.waypoints = PackedVector2Array([rally + Vector2(50.0, 30.0), rally - Vector2(60.0, -30.0)])
	_bruiser.speed = 9.0
	_bruiser.max_hp = 200000.0
	_bruiser.reward = 0
	_bruiser.melee_dmg = 400.0   # ฟาดทหารตายเร็ว
	_bruiser.damage_resist = 0.85
	_bruiser.body_bottom_row = 59
	_main.add_child(_bruiser)
	_phase = 2
