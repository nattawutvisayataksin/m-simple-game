extends SceneTree
# เทส Phase C: มอนใหม่ 3 + บอส (hard-counter การแก้)
# รอบ 1: ค้างคาวบิน — ปืนใหญ่ยิงไม่โดน (เลือดคงเต็มตลอดช่วงในวง) + นักธนูยิงตาย
# รอบ 2: สไลม์ — ตายแล้วแตก 2 ไอจิ๋วตามเส้นทางที่เหลือ
# รอบ 3: แชแมน — ฮีลเพื่อนรอบตัวเป็นจังหวะ
# รอบ 4: บอส Kubit — spawn จริง, ตายได้, ทอง 250
# ผ่านครบ = exit 0

const CANNON_FREE_AT := Vector2(150, 415)   # ลาน 0 (ใกล้เส้นทาง)
const TEST_PATH := Vector2(258, 510)        # เส้นทางหลักแนวนอนขวาจากค่าย

var _main: Node2D
var _t := 0.0
var _phase := 0
var _bat: Node2D
var _bat_spawned := false
var _archer_swapped := false
var _slime: Node2D
var _slime_spawned := false
var _slime_kill_t := 0.0
var _mini_ok := false
var _frog: Node2D
var _shaman: Node2D
var _pair_spawned := false
var _boss: Node2D
var _fails := 0

func _initialize() -> void:
	_main = load("res://scenes/main.tscn").instantiate()
	root.add_child(_main)
	_main._state = "prep"
	_main._prep_t = 1e9       # กันคลื่นจริงแทรก
	_main._gold = 800
	_main._update_gold()

func _live_enemies() -> Array:
	var out: Array = []
	for e in _main.get_tree().get_nodes_in_group("enemies"):
		if not e.dead:
			out.append(e)
	return out

func _alive(obj) -> bool:
	return obj != null and is_instance_valid(obj) and not obj.dead

func _process(delta: float) -> bool:
	_t += delta
	_main._prep_t = 1e9       # กันนับถอยคลื่นจริงตลอด
	match _phase:
		0:
			# ---- รอบ 1a: ค้างคาว + ปืนใหญ่ (ยิงไม่โดน) ----
			if not _bat_spawned and _t > 0.2:
				_bat_spawned = true
				_main._build_tower(0, "cannon")
				if _main._towers[0] == null:
					return _fail("cannon build at spot 0")
				# บินช้าหน่อยให้ช่วง "อยู่ในวง" ยาว: เข้าวง t≈8.5 · จุดสุดท้าย x=140 → รั่ว t≈12.2
				var path2: Array[Vector2] = [TEST_PATH + Vector2(360, 0), TEST_PATH - Vector2(118, 0)]
				_main._spawn_enemy(load("res://assets/art/gen/bat_flyer.png"), null, path2, 40.0, true, false, 52, null, 52, 30.0, 20, 0.0, 1.35, 6.0, true)
				for e in _live_enemies():
					if e.flying:
						_bat = e
				if _bat == null:
					return _fail("bat not flying-flagged")
			# ยืนยังอยู่ในวงปืนใหญ่จาก ~t=5.9 (x<291) ถึง ~t=11 (วงครอบ [9,291]) — ตัดสินที่ t=9
			if _t > 9.0:
				if _alive(_bat):
					if _bat._hp < 30.0:
						return _fail("cannon damaged flying bat hp=%.1f" % _bat._hp)
					print("TEST_T9 flying-cannon-immune PASS hp=%.1f (ยังบินและครบช่วงในวง)" % _bat._hp)
					_phase = 1
				else:
					return _fail("bat leaked/died under cannon")
		1:
			# ---- รอบ 1b: นักธนูยิงค้างคาวตาย ----
			if not _archer_swapped:
				_archer_swapped = true
				_main._sell_tower(0)
				_main._build_tower(0, "archer")
				if _main._towers[0] == null or _main._towers[0].kind != 0:
					return _fail("archer rebuild at spot 0")
			if not _alive(_bat):
				# การยืนยันถูกฆ่าโดยนักธนู (ไม่ใช่รั่ว): lives ต้องยังคงเดิม
				if _main._lives != 20:
					return _fail("bat leaked (lives=%d)" % _main._lives)
				print("TEST_T9 archer-hits-flier PASS")
				_phase = 2
			elif _t > 14.0:
				return _fail("archer never killed flying bat")
		2:
			# ---- รอบ 2: สไลม์แตกลูก ----
			if not _slime_spawned and _t > 0.2:
				_slime_spawned = true
				# เดินเร็วพิเศษ 55 ให้เข้าวงธนูเร็ว + จุดจบอยู่ในวง (ไม่รั่วระหว่างรอ)
				var path: Array[Vector2] = [TEST_PATH + Vector2(300, 0), TEST_PATH - Vector2(60, 0)]
				_main._spawn_enemy(load("res://assets/art/gen/slime_splitter.png"), null, path, 55.0, true, false, 59, null, 43, 34.0, 22, 0.0, 1.5, 9.0, false, "mini_slime", 2)
				for e in _live_enemies():
					if e.split_kind == "mini_slime":
						_slime = e
				if _slime == null:
					return _fail("slime never spawned")
				_slime_kill_t = _t + 4.0
			elif _slime_spawned:
				if _alive(_slime):
					# ทดสอบกลไก "แตก" โดยตรง: ห่างจากป้อมทิ้งช่วง 4 วิ แล้วสังหารเอง
					# (ไม่พึ่ง DPS นักธนู กันสไลม์รั่วก่อนตาย - จุสถานการณ์ที่แตกทดสอบ)
					if _t > _slime_kill_t:
						_slime.take_damage(9999.0, true)
				elif not _mini_ok:
					# ใหญ่ตายแล้ว — หาไอจิ๋ว (ไม่แตกต่อ, hp<20, สปีด>40)
					var minis := 0
					for e in _live_enemies():
						if e.split_kind == "" and e.max_hp < 20.0 and e.speed > 40.0:
							minis += 1
					if minis == 2:
						_mini_ok = true
						print("TEST_T9 slime-split PASS minis=%d" % minis)
						for e in _live_enemies():
							e.take_damage(9999.0, true)
						_phase = 3
					elif _t > _slime_kill_t + 6.0:
						return _fail("minis never appeared")
		3:
			# ---- รอบ 3: แชแมนฮีลกบ ----
			if not _pair_spawned and _t > 0.2:
				_pair_spawned = true
				var frog_path: Array[Vector2] = [TEST_PATH + Vector2(300, 0), TEST_PATH + Vector2(295, 0)]
				_main._spawn_enemy(load("res://assets/art/gen/frog.png"), load("res://assets/art/gen/frog_sheet.png"), frog_path, 2.0, true, false, 59, null, 43, 26.0, 15, 0.0, 1.5, 2.0)
				var sham_path: Array[Vector2] = [TEST_PATH + Vector2(240, 0), TEST_PATH + Vector2(239, 0)]
				_main._spawn_enemy(load("res://assets/art/gen/shaman_healer.png"), null, sham_path, 2.0, true, false, 59, null, 43, 55.0, 30, 0.0, 1.5, 2.0, false, "", 2, 0.045)
				for e in _live_enemies():
					if e.max_hp <= 30.0:
						_frog = e
					elif e.max_hp >= 50.0 and e.heal_power > 0.0:
						_shaman = e
				if _frog == null or _shaman == null:
					return _fail("heal pair not found")
				_frog.take_damage(10.0)   # เลือด 26 → 16
			elif _pair_spawned:
				if _frog != null and is_instance_valid(_frog) and _frog.dead:
					return _fail("frog died during heal test")
				if _alive(_frog) and _frog._hp > 16.5:
					print("TEST_T9 shaman-heal PASS hp=%.1f (จาก 16)" % _frog._hp)
					for e in _live_enemies():
						e.take_damage(9999.0, true)
					_phase = 4
				elif _t > 26.0:
					return _fail("shaman never healed frog hp=%.1f" % (_frog._hp if _alive(_frog) else -1.0))
		4:
			# ---- รอบ 4: บอส Kubit ----
			if _boss == null and _t > 0.2:
				_main._wave_idx = 12      # คลื่นบอสจริง (สุดท้าย)
				_main._spawn_kind("kubit_boss")
				for e in _live_enemies():
					if e.is_boss:
						_boss = e
				if _boss == null:
					return _fail("boss never spawned")
				if not _boss.is_boss or _boss.flying or _boss.split_kind != "" or _boss.max_hp < 3000.0:
					return _fail("boss stats wrong hp=%.0f" % _boss.max_hp)
				print("TEST_T9 boss-spawn PASS hp=%.0f scale=%.1f" % [_boss.max_hp, _boss.base_scale])
			elif _boss != null:
				if not _alive(_boss):
					return _fail("boss leaked before lethal test")
				_boss.take_damage(50.0)   # โดนยิงเฉย ๆ (ไม่มีเกราะ)
				if _boss._hp < _boss.max_hp:
					var before: int = _main._gold
					_boss.take_damage(99999.0)   # โจมตี 99999 = ตาย
					if not _boss.dead:
						return _fail("boss survived lethal (resist should be 0)")
					if _main._gold - before != 250:
						return _fail("boss reward not 250 got %d" % (_main._gold - before))
					print("TEST_T9 boss-kill+gold PASS +250")
					print("TEST_T9 ALL PASS")
					quit(0)
					return true
	if _t > 40.0:
		return _fail("global timeout phase=%d" % _phase)
	return false

func _fail(msg: String) -> bool:
	_fails += 1
	print("TEST_T9 FAIL (%s) phase=%d" % [msg, _phase])
	quit(1)
	return true