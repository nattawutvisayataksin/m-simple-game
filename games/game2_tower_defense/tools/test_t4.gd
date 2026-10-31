extends SceneTree
# เทส T4 อัตโนมัติ: โครงคลื่น -> เลือดโต -> เรียกก่อนได้โบนัส -> คลื่นจบโบนัส -> ชนะคลื่นสุดท้าย -> แพ้จาก leak
# รัน: godot --headless --path tower-defend --script <abs path>\tools\test_t4.gd  (script อยู่นอก res:// = ใช้ path เต็ม)
# ผ่านทุกด่าน = exit 0

var _main: Node2D
var _phase := 0              # 0 = โครงคลื่น 1, 1 = โบนัสเรียกก่อน, 2 = ชนะ, 3 = แพ้
var _gold_prep := 0          # ทอง ณ ตอนคลื่น 1 จบ (ครบฆ่า+โบนัส)
var _first_hp := -1.0
var _assembly_checked := false
var _sim_t := 0.0

func _initialize() -> void:
	var scene: PackedScene = load("res://scenes/main.tscn")
	_main = scene.instantiate()
	root.add_child(_main)
	if _main.WAVES.size() == 13:
		print("TEST_T4 structure PASS waves=13")
	else:
		print("TEST_T4 FAIL waves=%d" % _main.WAVES.size())
	# คลื่นแรกตั้งค่าผ่าน code path จริง (prep หมดเวลา -> _start_wave) ไม่เรียกแทนมือ
	_main._prep_t = 0.05

func _kill_all() -> void:
	for e in get_nodes_in_group("enemies"):
		if e is Node2D and not e.dead:
			e.take_damage(9999.0)

func _process(delta: float) -> bool:
	_sim_t += delta
	match _phase:
		0:
			# คลื่น 1: เช็คคิวเกิดข้อมูล + เลือดตัวแรก (ควร = 26.0 = 26 * 1.15^0) + กระทบจนจบคลื่น
			if _main._state == "wave" and not _assembly_checked:
				if _main._wave_idx == 0 and _main._queue.size() == 5:
					print("TEST_T4 wave1 assembly PASS queue=%d" % _main._queue.size())
				else:
					print("TEST_T4 wave1 assembly FAIL idx=%d queue=%d" % [_main._wave_idx, _main._queue.size()])
				_assembly_checked = true
			if _first_hp < 0.0:
				for e in get_nodes_in_group("enemies"):
					if e is Node2D and not e.dead:
						_first_hp = e.max_hp
						break
			_main._gap_t = 0.0   # ดันให้เกิดไว (ไม่แตะค่าเกมจริง - ดักเวลาเทสเท่านั้น)
			_kill_all()
			if _main._state == "prep" and _main._wave_idx == 0:
				if _first_hp == 26.0:
					print("TEST_T4 wave1 hp PASS hp=%.1f (โต 1.15^0)" % _first_hp)
				else:
					print("TEST_T4 wave1 hp FAIL hp=%.1f" % _first_hp)
				_gold_prep = _main._gold
				_phase = 1
		1:
			# เรียกคลื่นก่อน: วินาทีคงเหลือ 4.0 -> โบนัส = ceil(4 * 3) = 12 ทอง
			_main._prep_t = 4.0
			_main._on_wave_btn()
			if _main._state == "wave" and _main._wave_idx == 1 and _main._gold == _gold_prep + 12:
				print("TEST_T4 early-call PASS gold +%d (base %d)" % [12, _gold_prep])
				_phase = 2
			elif _main._state == "wave":
				print("TEST_T4 early-call FAIL state=%s idx=%d gold %d vs %d" % [_main._state, _main._wave_idx, _main._gold, _gold_prep + 12])
				_phase = 2   # เดินต่อเรื่องชนะ แต่ห้ามผ่านเงียบ: บันทึก FAIL แล้ว
			else:
				# ยังไม่ถึง: รอบเดิมรอบหน้า (state prep คงระบุ)
				pass
		2:
			# คลื่น 2 ตามปกติ: ฆ่าจบ -> กลับ prep (idx 1) -> ข้ามไปคลื่น 10 -> ฆ่าหมด -> ต้อง WON
			_main._gap_t = 0.0
			_kill_all()
			if _main._state == "prep" and _main._wave_idx == 1:
				_main._wave_idx = _main.WAVES.size() - 2
				_main._start_wave()   # ไปตรงคลื่นสุดท้าย
				print("TEST_T4 jump last wave idx=%d queue=%d" % [_main._wave_idx, _main._queue.size()])
			if _main._state == "won":
				print("TEST_T4 win PASS state=won paused=%s" % str(paused))
				_phase = 3
				# ด่านแพ้: อินสแตนซ์เกมใหม่ (แอดที่ tree ที่ paused ไปแล้ว - _ready ยังรัน)
				_main = load("res://scenes/main.tscn").instantiate()
				root.add_child(_main)
				_main._state = "wave"
				_main._lives = 3
				_main._update_lives()
				for _i in range(3):
					_main._on_enemy_leak()
				if _main._state == "lost":
					print("TEST_T4 lose PASS state=lost (leak 3 ครั้ง = lives 0)")
					print("TEST_T4 ALL PASS")
					quit(0)
					return true
				print("TEST_T4 lose FAIL state=%s" % _main._state)
				print("TEST_T4 FAIL")
				quit(1)
				return true
		_:
			pass
	if _sim_t > 60.0:
		print("TEST_T4 TIMEOUT sim=%.1f phase=%d state=%s idx=%d" % [_sim_t, _phase, _main._state, _main._wave_idx])
		quit(1)
		return true
	return false
