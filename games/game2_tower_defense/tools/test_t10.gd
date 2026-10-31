extends SceneTree
# เทส Phase D: โหมดเล็ง 4 แบบ + พรีวิวคลื่นไอคอน
# รอบ 0: first(last-progress)/last(first-progress)/strong(max_hp)/weak(เลือดปัจจุบันน้อย) + วนกลับ 0
# รอบ 1: ปืนใหญ่ข้ามค้างคาวแม้โหมด "นำหน้า" (flying filter ทำงานทุกโหมด)
# รอบ 2: แถวพรีวิวคลื่นถัดไปสร้างและเติมไอคอน
# ผ่านครบ = exit 0

var _main
var _t := 0.0
var _phase := 0
var _fails := 0
var _tower: Node2D
var _eA: Node2D
var _eB: Node2D
var _golem: Node2D
var _cannon: Node2D
var _frog: Node2D
var _bat: Node2D

func _initialize() -> void:
	_main = load("res://scenes/main.tscn").instantiate()
	root.add_child(_main)
	_main._state = "prep"
	_main._prep_t = 1e9
	_main._gold = 900
	_main._update_gold()

func _live_enemies() -> Array:
	var out: Array = []
	for e in _main.get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e) and not e.dead:
			out.append(e)
	return out

func _alive(obj) -> bool:
	return obj != null and is_instance_valid(obj) and not obj.dead

func _spawn_at(tex: String, sheet_path: String, pos: Vector2, hp: float, speed: float, flying := false) -> Node2D:
	# เกิดตรงจุด: ปี๊นตัวเป้าหมายทางขวาให้เดินออก (ไม่รั่วช่วงวัด)
	var before := {}
	for e in _live_enemies():
		before[e] = true
	var path: Array[Vector2] = [pos + Vector2(28.0, 0.0), pos + Vector2(430.0, 0.0)]
	_main._spawn_enemy(load(tex) if tex != "" else null, load(sheet_path) if sheet_path != "" else null, path, speed, true, false, 59, null, 43, hp, 15, 0.0, 1.5, 8.0, flying)
	for e in _live_enemies():
		if not before.has(e):
			e.position = pos
			e._progress = 0.0
			return e
	return null

func _fail(msg: String) -> bool:
	_fails += 1
	print("TEST_T10 FAIL (%s) phase=%d" % [msg, _phase])
	quit(1)
	return true

func _process(delta: float) -> bool:
	_t += delta
	_main._prep_t = 1e9
	match _phase:
		0:
			if _t > 0.2:
				_main._build_tower(0, "archer")
				_tower = _main._towers[0]
				if _tower == null:
					return _fail("archer build at spot 0")
				if _tower.targeting != 0:
					return _fail("default targeting must be 0")
				var base: Vector2 = _tower.position
				_eA = _spawn_at("res://assets/art/gen/frog.png", "res://assets/art/gen/frog_sheet.png", base + Vector2(80, 60), 26.0, 30.0)
				_eB = _spawn_at("res://assets/art/gen/frog.png", "res://assets/art/gen/frog_sheet.png", base + Vector2(150, 60), 26.0, 30.0)
				_golem = _spawn_at("res://assets/art/gen/stone_golem.png", "", base + Vector2(100, 105), 95.0, 27.0)
				if _eA == null or _eB == null or _golem == null:
					return _fail("spawn crew")
				# ทุกตัวอยู่ในวงวัดรัศมีจริง (พิสูจน์ก่อนวัดโหมด)
				for e in [_eA, _eB, _golem]:
					if e.position.distance_to(_tower.position) > _tower.range_r:
						return _fail("crew %s out of range %.0f" % [e.position, e.position.distance_to(_tower.position)])
				# โหมด first: เดินถึงก่อน (progress สูงสุด) = eB ; โกเลมถือว่าเดินถึงระดับ 200
				_eA._progress = 100.0
				_eB._progress = 300.0
				_golem._progress = 200.0
				if _tower._pick_target() != _eB:
					return _fail("first mode picked wrong")
				# โหมด นำหน้า = eA (progress ต่ำสุด)
				_tower.cycle_targeting()
				if _tower.targeting != 1 or _tower.targeting_name() != "นำหน้า":
					return _fail("cycle to 'last' failed")
				if _tower._pick_target() != _eA:
					return _fail("last mode picked wrong")
				# โหมด ชี้เป้าหนัก = โกเลม (max_hp 95)
				_tower.cycle_targeting()
				if _tower._pick_target() != _golem:
					return _fail("strong mode picked wrong")
				# โหมด เก็บเศษ = ตัวเลือดปัจจุบันน้อยสุด (แผล 10 ให้กบ A)
				_tower.cycle_targeting()
				_eA.take_damage(10.0)   # hp 26 → 16
				var wk: Node2D = _tower._pick_target()
				if wk != _eA:
					return _fail("weak mode picked wrong (got %s)" % [wk])
				# วนกลับ first
				_tower.cycle_targeting()
				if _tower.targeting != 0:
					return _fail("cycle wrap must return to 0")
				print("TEST_T10 targeting-modes PASS (first/last/strong/weak/wrap)")
				# เก็บกวาด
				for e in _live_enemies():
					e.take_damage(9999.0, true)
				_phase = 1
		1:
			# ปืนใหญ่: flying filter ทุกโหมด (โหมดนำหน้าเลือกค้างคาวชิง แต่ถูกกรองทิ้ง)
			if _t > 0.2 and _cannon == null:
				_main._build_tower(1, "cannon")
				_cannon = _main._towers[1]
				if _cannon == null:
					return _fail("cannon build at spot 1")
				_cannon.targeting = 1   # นำหน้า
				var base: Vector2 = _cannon.position
				_frog = _spawn_at("res://assets/art/gen/frog.png", "res://assets/art/gen/frog_sheet.png", base + Vector2(90, 90), 26.0, 30.0)
				_bat = _spawn_at("res://assets/art/gen/bat_flyer.png", "", base + Vector2(120, 80), 30.0, 40.0, true)
				if _frog == null or _bat == null:
					return _fail("cannon crew spawn")
				_frog._progress = 100.0
				_bat._progress = 500.0   # ค้างคาว "นำหน้า" อย่างเห็นได้ชัด
				var pick = _cannon._pick_target()
				if pick != _frog:
					return _fail("cannon must skip flying in 'last' mode")
				print("TEST_T10 cannon-flying-filter PASS (โหมดนำหน้าแต่เลือกกบพื้น)")
				for e in _live_enemies():
					e.take_damage(9999.0, true)
				_phase = 2
			elif _t > 6.0:
				return _fail("cannon phase timeout")
		2:
			# แถวพรีวิวคลื่นถัดไป: มี node + มีลูก (ไอคอน+จำนวน) + visible ตอน prep
			if _main._preview_box != null and _main._preview_box.visible and _main._preview_box.get_child_count() >= 2:
				# ขอบของ preview index: เมื่อจบคลื่นสุดท้าย _preview_shown = -999 และซ่อน
				_main._wave_idx = _main.WAVES.size() - 1
				_main._refresh_preview()
				if _main._preview_box.visible:
					return _fail("preview must hide when next wave out of range")
				print("TEST_T10 wave-preview-icons PASS children=%d" % _main._preview_box.get_child_count())
				print("TEST_T10 ALL PASS")
				quit(0)
				return true
			elif _t > 8.0:
				return _fail("preview box never filled")
	if _t > 30.0:
		return _fail("global timeout phase=%d" % _phase)
	return false