extends SceneTree
# เทส T5 อัตโนมัติ 4 ช่วง:
# 1) ป้อม: สร้าง archer (ทอง 180-90=90, dmg 9, lv1) -> อัปเกรด (ทอง 20, dmg 15, lv2)
#    -> อัปเกรดซ้ำ = no-op (ทอง 20 คงเดิม) -> ขายคืน 60% ของ 160 = +96 -> ทอง 116
# 2) ฮีโร่ฟาด: กบ max_hp 10 ยืนใกล้ตายใน ~จังหวะเดียว
# 3) ฮีโร่โดนรุม: กิ้งก่าเลือดนิรันดร์แนมตัวเลือดลด < 100
# 4) ฮีโร่ตาย/เกิดใหม่: take_damage จัดเต็ม -> respawn ตั้งสั้น 0.2 วิ -> ฟื้นเลือดเต็มหน้าปราสาท
# ผ่านครบ = "TEST_T5 ALL PASS" exit 0
# รัน: godot --headless --path tower-defend --script tools/test_t5.gd

var _main: Node2D
var _sim_t := 0.0
var _phase := 0
var _frog_done := false
var _lizard: Node2D

func _initialize() -> void:
	var main_scene: Node2D = load("res://scenes/main.tscn").instantiate()
	root.add_child(main_scene)
	_main = main_scene

	# ---- ช่วง 0: คลิกจำลองทั้ง 4 ลานต้องเปิดเมนูครบ (ฟีดแบ็ค T5.1: หาจุดซื้อไม่ได้) ----
	for i in range(4):
		var me := InputEventMouseButton.new()
		me.button_index = MOUSE_BUTTON_LEFT
		me.pressed = true
		me.position = _main.TOWER_SPOTS[i]
		_main._unhandled_input(me)
		if _main._menu_spot != i or _main._menu_mode != "build":
			print("TEST_T5 FAIL click spot=%d menu_spot=%s mode=%s" % [i, _main._menu_spot, _main._menu_mode])
			quit(1)
			return
		_main._close_menu()
	print("TEST_T5 click-4-spots PASS")

	# ---- ช่วง 1: ป้อม สร้าง -> อัปเกรด -> อัปเกรดซ้ำ -> ขาย ----
	_main._open_menu(0)                      # ลาน 0 = build mode
	if _main._menu_mode != "build":
		print("TEST_T5 FAIL build-mode menu_mode=", _main._menu_mode)
		quit(1)
		return
	_main._build_tower(0, "archer")
	var t: Node2D = _main._towers[0]
	var ok1: bool = _main._gold == 90 and t != null and t.damage == 9.0 and t.level == 1
	if not ok1:
		print("TEST_T5 FAIL build gold=", _main._gold, " dmg=", t.damage, " lvl=", t.level)
		quit(1)
		return
	_main._upgrade_tower(0)
	var ok2: bool = _main._gold == 20 and t.damage == 15.0 and t.level == 2 and t.fire_interval == 0.6
	if not ok2:
		print("TEST_T5 FAIL upgrade gold=", _main._gold, " dmg=", t.damage, " lvl=", t.level, " iv=", t.fire_interval)
		quit(1)
		return
	var gold_before: int = _main._gold
	_main._upgrade_tower(0)                  # lv แล้ว = no-op ไม่กระตุกทอง
	if _main._gold != gold_before or t.level != 2:
		print("TEST_T5 FAIL upgrade-again gold=", _main._gold, " (ควร ", gold_before, ")")
		quit(1)
		return
	_main._sell_tower(0)
	var ok3: bool = _main._gold == 116 and _main._towers[0] == null and _main._lvl[0] == 0 and _main._inv[0] == 0
	if not ok3:
		print("TEST_T5 FAIL sell gold=", _main._gold, " (ควร 116) towers0=", _main._towers[0])
		quit(1)
		return
	print("TEST_T5 tower PASS build+upgrade+sell gold=", _main._gold)
	_main._build_tower(2, "archer")
	var spot3_tower: Node2D = _main._towers[2]
	var background: Sprite2D = _main.get_node("Background")
	if spot3_tower == null or spot3_tower.position != _main.TOWER_SPOTS[2] or background.z_index >= spot3_tower.z_index:
		print("TEST_T5 FAIL spot-3 tower render order background_z=", background.z_index,
			" tower_z=", spot3_tower.z_index if spot3_tower != null else "missing")
		quit(1)
		return
	print("TEST_T5 spot-3 visibility PASS background_z=", background.z_index, " tower_z=", spot3_tower.z_index)
	_phase = 1

	# ---- ช่วง 2: ฮีโร่ฟาดกบ (max_hp 10 ตายในจังหวะเดียว) ----
	# NB: ปล่อยกบตัวเดียวก่อน - ฮีโร่ฟาดเป้า "ใกล้สุด" ถ้ามีกิ้งก่าใกล้กว่ากบจะไม่ถูกแตะ
	var EnemyScript: GDScript = load("res://scripts/enemy.gd")
	var frog: Node2D = EnemyScript.new()
	frog.texture = load("res://assets/art/gen/frog.png")
	frog.sheet = load("res://assets/art/gen/frog_sheet.png")
	frog.waypoints = PackedVector2Array([Vector2(830, 470), Vector2(880, 470)])
	frog.speed = 5.0
	frog.max_hp = 10.0
	frog.reward = 0
	frog.body_bottom_row = 59
	frog.died.connect(func(_r, _at): _frog_done = true)
	_main.add_child(frog)

func _spawn_lizard() -> void:
	# ---- ช่วง 3: กิ้งก่าเลือดนิรันดร์แนมตัวฮีโร่ (เรียกหลังกบตาย) ----
	var EnemyScript: GDScript = load("res://scripts/enemy.gd")
	_lizard = EnemyScript.new()
	_lizard.texture = load("res://assets/art/gen/lizard_front.png")
	_lizard.sheet = load("res://assets/art/gen/lizard_sheet.png")
	_lizard.waypoints = PackedVector2Array([Vector2(800, 470), Vector2(770, 470)])
	_lizard.speed = 3.0      # เกาะใกล้ตัวไม่ไลหนี
	_lizard.max_hp = 9999.0
	_lizard.reward = 0
	_lizard.body_bottom_row = 56
	_main.add_child(_lizard)

func _process(_delta: float) -> bool:
	_sim_t += _delta
	var hero: Node2D = _main._hero

	if _phase == 1:
		if _frog_done:
			print("TEST_T5 hero-attack PASS (กบตาย sim=%.1fs)" % _sim_t)
			_spawn_lizard()
			_phase = 2
	elif _phase == 2:
		if not hero._dead and hero._hp < hero.max_hp:
			print("TEST_T5 hero-contact PASS hp=%.1f (< %.0f)" % [hero._hp, hero.max_hp])
			# เคลียร์กิ้งก่าก่อนการทดสอบตาย/ฟื้น (กันโดนบีบเลือดช่วง respawn)
			if _lizard != null and is_instance_valid(_lizard):
				_lizard.queue_free()
			_phase = 3
	elif _phase == 3:
		if hero._dead:
			print("TEST_T5 hero-death PASS respawn_t=%.2f" % hero._respawn_t)
			_phase = 4
		else:
			# ยิงให้ตายเลย จบเห่ (ตั้ง respawn สั้นเพื่อไม่รอ 8 วิ)
			hero.respawn_time = 0.2
			hero.take_damage(9999.0)
			if not hero._dead:
				print("TEST_T5 FAIL hero alive after lethal")
				quit(1)
				return true
	elif _phase == 4:
		if not hero._dead and hero._hp == hero.max_hp and hero.position == Vector2(816, 470):
			print("TEST_T5 hero-respawn PASS hp=%.0f pos=%s sim=%.1fs" % [hero._hp, hero.position, _sim_t])
			print("TEST_T5 ALL PASS")
			quit(0)
			return true

	if _sim_t > 20.0:
		print("TEST_T5 FAIL phase=%d frog=%s hp=%.1f dead=%s sim=%.1fs" % [_phase, _frog_done, hero._hp, hero._dead, _sim_t])
		quit(1)
		return true
	return false
