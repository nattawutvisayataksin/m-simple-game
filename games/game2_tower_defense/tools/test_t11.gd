extends SceneTree
# เทส Phase E: title + เลือกแผนที่ + save สถิติคลื่นสูงสุด + สุขภาพจอเริ่มเกม
# รอบ 0: เกมเปิดมา = state "title" + หน้าเลือกแผนที่มีปุ่มครบ + คลิกลานป้อมถูกปิด (ไม่มีเมนู)
# รอบ 1: _start_map(0) = สถานะ prep + road/spots = แผนที่ A + ประตู/ปราสาท/ฮีโร่ตามแผนที่ + ใส่คลิกเปิดเมนูได้
# รอบ 2: _start_map(1) = พื้นหลัง/เส้นทาง/ลานสลับเป็นแผนที่ B + มอนเกิดเดินตาม PATH_B จริง
# รอบ 3: มอนวิ่งถึงปลาย PATH_B ปลายปราสาท = รั่ว (ชีวิตลด 1) — ประตู map B ทำงาน
# รอบ 4: _record_best + _save_best + _load_best (atomic file td_best.json)
# ผ่านครบ = "TEST_T11 ALL PASS" exit 0
# หมายเหตุ: สำรอง/คืนไฟล์ user://td_best.json เดิม — เทสไม่แตะเซฟของผู้เล่นจริง

var _main: Node2D
var _t := 0.0
var _phase := 0
var _fails := 0
var _backup_txt: String = ""
var _had_backup := false
var _frog: Node2D
var _life0 := 0
var _got_leak := false

func _initialize() -> void:
	_main = load("res://scenes/main.tscn").instantiate()
	root.add_child(_main)
	# สำรองไฟล์เซฟจริง (ถ้ามี) เพื่อคืนตอนจบ
	if FileAccess.file_exists(_main.BEST_PATH):
		var f := FileAccess.open(_main.BEST_PATH, FileAccess.READ)
		_backup_txt = f.get_as_text()
		f.close()
		_had_backup = true

func _fail(msg: String) -> bool:
	_fails += 1
	print("TEST_T11 FAIL (%s) phase=%d" % [msg, _phase])
	quit(1)
	return true

func _restore_save() -> void:
	# คืนไฟล์เซฟเดิมแบบ atomic เหมือนเกม (ถ้าไม่มีไฟล์เดิม = ลบทิ้ง)
	var fa := FileAccess.open(_main.BEST_PATH + ".tmp", FileAccess.WRITE)
	if _had_backup:
		fa.store_string(_backup_txt)
	fa.flush()
	fa.close()
	var needed := _had_backup
	DirAccess.remove_absolute(_main.BEST_PATH)
	if needed:
		DirAccess.rename_absolute(_main.BEST_PATH + ".tmp", _main.BEST_PATH)
	else:
		DirAccess.remove_absolute(_main.BEST_PATH + ".tmp")

func _live_enemies() -> Array:
	var out: Array = []
	for e in _main.get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e) and not e.dead:
			out.append(e)
	return out

func _click(pos: Vector2) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	ev.position = pos
	ev.global_position = pos
	_main._unhandled_input(ev)

func _deep_buttons(node: Node) -> int:
	# นับ Button ทุกระดับใต้ Layer
	var n := 0
	for c in node.get_children():
		if c is Button:
			n += 1
		n += _deep_buttons(c)
	return n

func _process(delta: float) -> bool:
	_t += delta
	match _phase:
		0:
			# หน้า title: state + เลย์เอาต์ปุ่ม + คลิกเกมถูกปิด
			if _t > 0.3:
				if _main._state != "title":
					return _fail("game must boot into title state")
				if _main._title_layer == null:
					return _fail("title layer missing")
				var btns := _deep_buttons(_main._title_layer)
				if btns < 2:
					return _fail("title must offer >=2 map buttons, got %d" % btns)
				_click(Vector2(420, 615))   # ลานป้ามปกติ
				if _main._menu != null:
					return _fail("game click must be blocked in title")
				if _main._state != "title":
					return _fail("title state must persist before start")
				print("TEST_T11 title+map-select PASS (buttons=%d, คลิกเกมถูกปิด)" % btns)
				_main._start_map(0)
				_main._prep_t = 1e9
				_phase = 1
		1:
			# เริ่มกีแผนที่ A: สถานะ + เส้นทาง/ลาน + ประตู-ปราสาท-ฮีโร่ + title หาย
			if _t >= 0.3:
				if _main._state != "prep":
					return _fail("after start_map(0) state must be prep")
				if _main._title_layer != null:
					return _fail("title layer must be freed after start")
				if _main._road.size() != 10:
					return _fail("map A road must have 10 waypoints")
				if _main._road[0] != Vector2(258, 190) or _main._road[_main._road.size() - 1] != Vector2(810, 450):
					return _fail("map A road endpoints mismatch")
				if _main._spots.size() != 4 or _main._spots[0] != Vector2(160, 445):
					return _fail("map A spots mismatch")
				if _main._spots_layer.spots != _main._spots:
					return _fail("spots overlay must follow current map")
				if _main._spots_layer.gate != _main._road[0] or _main._spots_layer.castle != _main._road[_main._road.size() - 1]:
					return _fail("portal/castle markers must follow road")
				if _main.get_node("Background").texture != _main.MAP_A_TEX:
					return _fail("background texture must be map A")
				if _main._hero.home != Vector2(810, 450) or _main._hero.position != Vector2(810, 450):
					return _fail("hero gate must be road end of map A")
				# อินพุตกลับมาปกติ: คลิกลานเดิมเปิดเมนูได้
				_click(Vector2(420, 615))
				if _main._menu == null:
					return _fail("click route after start_map(0) must open menu")
				_main._close_menu()
				print("TEST_T11 start_map(0)-apply PASS (road/spots/bg/hero/menu)")
				_main._state = "title"   # เทสเข้าเงื่อนไขเลือกแผนที่ใหม่เท่านั้น
				_main._start_map(1)
				_main._prep_t = 1e9
				_phase = 2
		2:
			# เริ่มเกมแผนที่ B แล้วให้มอนปากสุสานเดินตาม PATH_B
			if _t > 0.4:
				if _main._state != "prep":
					return _fail("after start_map(1) state must be prep")
				if _main.get_node("Background").texture != _main.MAP_B_TEX:
					return _fail("background texture must be map B")
				if _main._road[0] != Vector2(258, 140) or _main._road[_main._road.size() - 1] != Vector2(850, 380):
					return _fail("map B road endpoints mismatch")
				if _main._spots[0] != Vector2(340, 370):
					return _fail("map B spots mismatch")
				if _main._hero.home != Vector2(850, 380) or _main._hero.position != Vector2(850, 380):
					return _fail("hero gate must be road end of map B")
				if _main._spots_layer.gate != _main._road[0] or _main._spots_layer.castle != _main._road[_main._road.size() - 1]:
					return _fail("portal/castle markers must follow road (map B)")
				# มอนเกิดจากปากสุสานเดินเส้น PATH_B (สุ่มชนิดปกติ = ใช้ _road ของแผนที่ปัจจุบัน)
				var s0: Vector2 = _main._road[0]
				var before := {}
				for e in _live_enemies():
					before[e] = true
				_main._spawn_kind("frog")
				for e in _live_enemies():
					if not before.has(e) and e.get_script() == _main.EnemyScript:
						_frog = e
				if _frog == null:
					return _fail("frog spawn on map B")
				if _frog.position.distance_to(s0) > 50.0:
					return _fail("map B frog must spawn at graveyard gate %.0f" % [_frog.position.distance_to(s0)])
				if _frog.waypoints.size() < 6:
					return _fail("map B frog must follow full road (waypoints=%d)" % _frog.waypoints.size())
				var end_w: Vector2 = _frog.waypoints[_frog.waypoints.size() - 1]
				if end_w.distance_to(Vector2(850, 380)) > 60.0:
					return _fail("map B frog must route to castle end %.0f" % [end_w.distance_to(Vector2(850, 380))])
				print("TEST_T11 start_map(1)-apply PASS (bg/road/spots/hero + frog post PATH_B)")
				# เตรียม leak: ฆ่าฮีโร่ชั่วคราว (ไม่ให้ฟาดกบทดสอบ)
				_main._hero._dead = true
				_main._hero._respawn_t = 1e9
				_frog.take_damage(9999.0, true)
				var road_arr: Array[Vector2] = []
				for p in _main._road:
					road_arr.append(p)
				_main._spawn_enemy(_main.FROG_TEX, _main.FROG_SHEET, road_arr, 330.0, true, false,
					59, null, 43, 6.0, 15, 0.0, 1.5, 8.0)
				_phase = 3
		3:
			# มอนแหกประตูปราสาทแผนที่ B = ชีวิตลด 1
			if _t > 0.6:
				_life0 = _main._lives
				_got_leak = false
				_phase = 31
				_t = 0.0
		31:
			if _main._lives < _life0:
				if _got_leak or _main._lives != _life0 - 1:
					return _fail("exactly one frog should leak, lives=%d" % _main._lives)
				_got_leak = true
				# รอจังหวะเช็คว่าไม่รั่วซ้ำอีก (1 วิ)
				_phase = 32
				_t = 0.0
			elif _t > 25.0:
				return _fail("no leak in 25s — PATH_B walk broken")
		32:
			if _t > 1.0 and _main._lives == _life0 - 1:
				print("TEST_T11 map-B-leak PASS (ชีวิต %d -> %d หลังเดิน PATH_B ครบ)" % [_life0, _main._lives])
				_phase = 4
				_t = 0.0
			elif _t > 25.0:
				return _fail("no leak in 25s — PATH_B walk broken")
		4:
			# save สถิติ: record/won/atomic/load + label หน้า title
			if _t > 0.3:
				_main._map_idx = 0
				_main._wave_idx = 4      # ทำได้ถึงคลื่น 5
				_main._prev_best = 0
				_main._best = {}
				_main._record_best(false)
				if _main._best.get("m0", 0) != 5:
					return _fail("record_best must save reached=5, got %d" % int(_main._best.get("m0", 0)))
				_main._record_best(true)
				if not _main._best.get("m0_won", false):
					return _fail("won must set m0_won flag")
				_main._wave_idx = 2      # ครั้งถัดไปทำได้ถึงคลื่น 3 = ยังไม่มากว่าเดิม
				_main._record_best(false)
				if int(_main._best.get("m0", 0)) != 5:
					return _fail("best must keep max, got %d" % int(_main._best.get("m0", 0)))
				_main._save_best()
				if not FileAccess.file_exists(_main.BEST_PATH):
					return _fail("save must create td_best.json")
				var fa := FileAccess.open(_main.BEST_PATH, FileAccess.READ)
				var parsed = JSON.parse_string(fa.get_as_text())
				fa.close()   # NB: ไม่ปิด = Windows lock ทำ remove_absolute พังเงียบ ๆ
				if parsed == null or not (parsed is Dictionary):
					return _fail("save must be valid JSON dict")
				_main._best = {}
				_main._load_best()
				if int(_main._best.get("m0", 0)) != 5 or not _main._best.get("m0_won", false):
					return _fail("load_best must restore best after fresh dict")
				var txt: String = _main._map_best_text(0)
				if not txt.contains("5"):
					return _fail("title best text must mention 5, got '%s'" % txt)
				print("TEST_T11 best-save-load PASS (m0=5+won, atomic file, label '%s')" % txt)
				_restore_save()
				print("TEST_T11 ALL PASS")
				quit(0)
				return true
	if _t > 45.0:
		return _fail("global timeout phase=%d" % _phase)
	return false
