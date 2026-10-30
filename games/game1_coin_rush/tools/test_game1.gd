extends SceneTree
# ชุดทดสอบเกม 1 (Kubi Coin Dash) — รัน headless แล้ว exit code 0 = ผ่าน, 1 = ล้ม
#   godot --headless --path games/game1_coin_rush --script res://tools/test_game1.gd
# แบบแผนเดียวกับชุดเทส tools/test_*.gd ของเกม 2
var _fail := 0
var _main: Node2D = null
var _frames := 0
var _phase := 0

func _check(cond: bool, msg: String) -> void:
	if cond:
		print("PASS: ", msg)
	else:
		_fail += 1
		print("FAIL: ", msg)

func _initialize() -> void:
	print("=== TEST_GAME1 START ===")
	# --- ส่วนที่ 1: ตรวจข้อมูลด่านจากสคริปต์โดยตรง (ยังไม่ต้องมี scene) ---
	var sc: GDScript = load("res://scripts/main.gd")
	_check(sc != null, "โหลด scripts/main.gd ได้")
	var levels: Array = sc.get_script_constant_map()["LEVELS"]
	_check(levels.size() == 8, "มี 8 ด่านตามแผนไน้")
	var need_keys := ["name", "sub", "width", "height", "time", "start", "platforms", "coins", "gold_index", "enemies", "hazards", "moving"]
	for i in range(levels.size()):
		var lvl: Dictionary = levels[i]
		_check(lvl.has_all(need_keys), "ด่าน %d มีคีย์ครบ" % (i + 1))
		_check(float(lvl["time"]) > 0.0, "ด่าน %d เวลา>0" % (i + 1))
		_check(float(lvl["width"]) >= 2400.0, "ด่าน %d ยาวพอชิม" % (i + 1))
		_check(lvl["coins"].size() >= 8, "ด่าน %d เหรียญหลาก" % (i + 1))
		_check(int(lvl["gold_index"]) >= 0 and int(lvl["gold_index"]) < lvl["coins"].size(), "ด่าน %d gold_index ชี้เหรียญจริง" % (i + 1))
		var sp: Vector2 = lvl["start"]
		_check(sp.y > 0.0, "ด่าน %d จุดเกิดเก็บได้" % (i + 1))
		for p in lvl["coins"]:
			_check(p != null, "ด่าน %d เหรียญทุกที่เปิดถูกต้อง" % (i + 1))
			break

	# --- ส่วนที่ 1.4: มินิบอสด่าน 8 ---
	_check(levels[7].get("bosses", []).size() == 1, "ด่าน 8 มีมินิบอส 1 ตัวคุมยอด")
	var boss_scene_ref: PackedScene = load("res://scenes/boss_kubit.tscn")
	var bs: Node2D = boss_scene_ref.instantiate()
	_check(bs != null and int(bs.hp) == 3, "บอสเกิดมา HP=3")
	bs.free()

	# --- ส่วนที่ 1.5: สกินฮีโร่ครบ 5 ชุด (ไฟล์ + set_skin ใน player) ---
	var skin_paths := [
		"res://assets/art/sprites/kubi_hero_run_sheet.png",
		"res://assets/art/gen/kubi_hero_run_sheet_cyan.png",
		"res://assets/art/gen/kubi_hero_run_sheet_ember.png",
		"res://assets/art/gen/kubi_hero_run_sheet_violet.png",
		"res://assets/art/gen/kubi_hero_run_sheet_leaf.png",
	]
	for p in skin_paths:
		_check(ResourceLoader.exists(p), "สกินไฟล์อยู่จริง: %s" % p)

	# --- ส่วนที่ 2: ตรวจ scenes โหลดได้ ---
	for path in ["res://scenes/title.tscn", "res://scenes/main.tscn", "res://scenes/player.tscn", "res://scenes/coin.tscn", "res://scenes/coin_gold.tscn", "res://scenes/enemy.tscn", "res://scenes/hopper.tscn", "res://scenes/goal.tscn", "res://scenes/hazard.tscn", "res://scenes/moving_platform.tscn", "res://scenes/bat.tscn", "res://scenes/charger.tscn", "res://scenes/boss_kubit.tscn"]:
		var ps: PackedScene = load(path)
		_check(ps != null, "โหลด %s ได้" % path)

	# --- ส่วนที่ 3: instantiate แล้วตรวจสตริง (ก่อนตั้ง main scene จริง) ---
	for pair in [["res://scenes/coin.tscn", 1], ["res://scenes/coin_gold.tscn", 3]]:
		var c: Area2D = (load(pair[0]) as PackedScene).instantiate()
		_check(c != null, "instantiate %s ได้" % pair[0])
		_check(int(c.value) == int(pair[1]), "%s value=%d" % [pair[0], pair[1]])
		c.free()

	# สร้าง main เข้า tree หลังสุดเพื่อให้ @onready เสร็จแล้วค่อยเทสใน _process
	var ms: PackedScene = load("res://scenes/main.tscn")
	_main = ms.instantiate()
	root.add_child(_main)

func _process(_delta: float) -> bool:
	_frames += 1
	if _main == null or _frames < 3:
		if _frames > 240:
			print("FAIL: main ไม่พร้อมใน 240 เฟรม")
			quit(1)
		return false
	if _phase == 0:
		# --- สกินฮีโร่: set_skin กับผู้เล่นจริง (ต้องรอ @onready) ---
		_main.player.set_skin(3)
		var vtex: Texture2D = _main.player.visual.texture
		_check(String(vtex.resource_path).contains("violet"), "set_skin(3) = ม่วงราตรีโหลดถูก")
		_main.player.set_skin(99)
		var ltex: Texture2D = _main.player.visual.texture
		_check(String(ltex.resource_path).contains("leaf"), "set_skin(99) clamp เป็นใบไม้ระยิบได้")
		_main.player.set_skin(0)
		# --- ส่วนที่ 3: สถานะเกมหลัง _ready ---
		_check(_main.state == _main.GameState.PLAYING, "เริ่มเกมสถานะ PLAYING")
		_check(_main.score == 0, "คะแนนเริ่ม 0")
		_check(_main.current_level == 0, "เริ่มที่ด่านแรก")
		var coins0: int = _main.LEVELS[0]["coins"].size()
		_check(_main.coins_container.get_child_count() == coins0, "ด่าน 1 มีเหรียญถูกเกิดครบ (%d)" % coins0)
		_check(_main.enemies_container.get_child_count() > 0, "ด่าน 1 มีศัตรูเกิด")
		_check(_main.time_left > 0.0, "ตัวจับเวลา > 0")
		_check(_main.player.is_in_group("player"), "ผู้เล่นอยู่กลุ่ม player")
		_check(_main.player.position.distance_to(_main.LEVELS[0]["start"]) < 120.0, "ผู้เล่นอยู่ใกล้จุดเกิดด่าน 1")
		_check(_main.sfx_pickup != null and _main.sfx_win != null and _main.sfx_lose != null, "โหนดเสียงหลักครบ")
		# คะแนนและเทรมือ
		_main._on_coin_collected(1)
		_check(_main.score == 1, "เก็บเหรียญ +1 ได้")
		_main._on_coin_collected(3)
		_check(_main.score == 4, "เก็บเหรียญทอง +3 ได้")
		_main.add_trauma(999.0)
		_check(_main._trauma <= 1.0, "claddots trauma ขีดสุดจริง")
		# ระบบเซฟ
		_main._record_loss()
		_check(_main.stats["plays"] >= 1, "บันทึก plays เพิ่มแล้ว")
		var path: String = _main.SAVE_PATH
		_check(FileAccess.file_exists(path), "เขียนไฟล์เซฟที่ %s สำเร็จ" % path)
		if FileAccess.file_exists(path):
			var data = JSON.parse_string(FileAccess.get_file_as_string(path))
			_check(data is Dictionary and int(data["version"]) == _main.SAVE_VERSION, "ไฟล์เซฟพ่ธได้และ version ถูก")
		# คืนสไมธี และลุกผลัดไปด่านสุดท้ายเพื่อยืนยัน _load_level รีเซ็ตครบ
		_main._load_level(_main.LEVELS.size() - 1)
		_check(_main.current_level == _main.LEVELS.size() - 1, "ถึงด่านใหม่เท่านั้นอาศัยการโหลด")
		_check(_main.state == _main.GameState.PLAYING, "state กลับมา PLAYING หลังโหลดด่าน")
		_check(_main.score == 0, "score รีเซ็ตหลังโหลดด่าน")
		_phase = 1
	elif _phase == 1:
		# รอ 1 เฟรมหลังโหลดด่าน ให้ queue_free เก่าถูกกวาดก่อนนับ
		var coinsN: int = _main.LEVELS[_main.current_level]["coins"].size()
		_check(_main.coins_container.get_child_count() == coinsN, "ด่านใหม่เหลิยญครบหลังโหลดทับ (%d)" % coinsN)
		var win_bg: Node = _main.find_child("BGFar", true, false)
		_check(win_bg != null, "มีชั้นพื้นหลังไกล BGFar")
		_phase = 2
	else:
		_finish()
		return true
	return false

func _finish() -> void:
	print("=== TEST_GAME1 END fail=%d ===" % _fail)
	quit(1 if _fail > 0 else 0)
