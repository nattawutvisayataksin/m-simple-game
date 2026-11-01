extends Node2D
# play.gd - game room: 120s clock, pick up & deliver (Crazy Taxi style)
# Thai notes kept short on purpose (long Thai strings corrupt during generation)

signal back_to_menu

const CarScript := preload("res://scripts/car.gd")
const SaveScript := preload("res://scripts/save.gd")

const SLIME_TEX := preload("res://assets/sprites/hazard_slime.png")
const GOLEM_TEX := preload("res://assets/sprites/hazard_golem.png")
const PASS_TEX := preload("res://assets/sprites/pass_frog.png")
const PASS_LIZ_TEX := preload("res://assets/sprites/pass_liz.png")
const PASS_CHICK_TEX := preload("res://assets/sprites/pass_chick.png")
const TRAFFIC_TEX := preload("res://assets/sprites/car_traffic.png")
const CAR_ANG := PI * 0.75   # ภาพรถหันลงซ้าย 135° (ชุดเดียวกับ car.gd)
const CAR_NAMES := {"kubi": "Kubi Cab", "liz": "กิ้งก่าซิ่ง", "golem": "โกเลมแท็กซี่"}

const W := 1152.0
const H := 648.0
const GAME_TIME := 120.0
const PICK_RADIUS := 70.0
const STOP_SPEED := 70.0
const RAMP_TIP := 20
const NEARMISS_TIP := 5
const DRIFT_TIP := 10

# roads: 3 horizontal + 3 vertical strips
const ROADS_H_Y := [110.0, 294.0, 478.0]
const ROADS_V_X := [170.0, 576.0, 982.0]
const ROAD_W := 96.0
const POIS := [
	Vector2(170, 110), Vector2(576, 110), Vector2(982, 110),
	Vector2(170, 294), Vector2(576, 294), Vector2(982, 294),
	Vector2(170, 478), Vector2(576, 478), Vector2(982, 478),
]
const MIN_DROP_DIST := 340.0
const RAMP_ZONE := Rect2(636, 274, 140, 40)

var time_left := GAME_TIME
var cash := 0
var rides_ok := 0
var rides_fail := 0
var combo := 0
var playing := false
var over := false
var over_info := {}
var best := {}                 # สถานะอู่จากเซฟ (main ยัดก่อน add_child): {car_pick, upgrades}
var car: CharacterBody2D = null
var trip := {}                 # {p, drop, limit, left, dist, fare}
var trip_active := false
var spawn_gap := 0.0           # delay before next passenger appears
var tip_texts := []            # {pos, txt, left, color}
var slime_list := []
var golem_list := []
var traffic := []
var nearmiss_cd := 0.0
var drift_bank := 0.0          # seconds accumulated of destructive drifting
var golem_timer := 5.0
var _anim_t := 0.0             # นาฬิกาแต่งภาพ (สไลม์หายใจ)
var sfx: Node = null           # โหนดเสียงของ Main (ตั้งตอนเริ่มเกม)
var shake_t := 0.0             # กล้องเขย่า (ชนโกเลม)
var freeze_t := 0.0            # hit-stop 0.06 วิ (เงินเข้าส่งสำเร็จ)
var smoke := []                # ควันยางดริฟท์ [{pos, age}]
var _smoke_cd := 0.0

func _ready() -> void:
	_start()

func _start() -> void:
	playing = true
	over = false
	over_info = {}
	time_left = GAME_TIME
	cash = 0
	rides_ok = 0
	rides_fail = 0
	combo = 0
	trip = {}
	trip_active = false
	spawn_gap = 0.4
	tip_texts = []
	drift_bank = 0.0
	nearmiss_cd = 0.0
	golem_timer = 5.0
	if car != null:
		car.queue_free()
	car = CharacterBody2D.new()
	car.set_script(CarScript)
	car.position = Vector2(170, 60 + 50.0)
	car.rotation = 0.0
	car.set_meta("ramp_cd", false)
	# รถประจำกะจากอู่: เลือกคัน + เลเวลอัปเกรดจากเซฟ (best ต้องยัดก่อน add_child)
	var gpick: String = str(best.get("car_pick", "kubi"))
	car.car_id = gpick
	car.call("set_lv", int((best.get("upgrades", {}) as Dictionary).get(gpick, 0)))
	add_child(car)
	traffic = _build_traffic()
	slime_list = _build_slimes()
	golem_list = []

# ---------- life loop ----------

func _process(dt: float) -> void:
	queue_redraw()   # mark dirty: everything (timer/traffic/tips) redraws every frame
	if not playing:
		return
	if over:
		if Input.is_key_pressed(KEY_R):
			get_tree().reload_current_scene()
		elif Input.is_key_pressed(KEY_ESCAPE) or Input.is_key_pressed(KEY_M):
			playing = false
			back_to_menu.emit()
		return
	time_left -= dt
	_anim_t += dt
	# camera shake: หนุนจอสนุกหมุน 1 วิเท่านั้น — ระบายแรงตามเวลาที่เหลือ
	if shake_t > 0.0:
		shake_t -= dt
		var mag := 7.0 * shake_t / 0.35
		position = Vector2(randf_range(-mag, mag), randf_range(-mag, mag))
	elif position != Vector2.ZERO:
		position = Vector2.ZERO
	if time_left <= 0.0:
		time_left = 0.0
		_finish()
		return
	# hit-stop: โลกหยุดหายใจแวบเดียวตอนแตกโอกาส — อินพุตยังเก็บแต่เวลาโลกไม่ไหล
	var world_dt := dt
	if freeze_t > 0.0:
		freeze_t -= dt
		world_dt = 0.0
	_serve_input(world_dt)
	_update_trip(world_dt)
	_update_traffic(world_dt)
	_update_slimes(world_dt)
	_update_golems(world_dt)
	_update_tips(dt)
	_update_smoke(dt)
	if nearmiss_cd > 0.0:
		nearmiss_cd -= dt
	if drift_bank > 0.0 or car.drifting:
		if car.drifting:
			drift_bank += dt
			if drift_bank >= 0.8:
				drift_bank -= 0.8
				cash += DRIFT_TIP
				add_tip(car.position, "+%d ดริฟท์!" % DRIFT_TIP, Color(1.0, 0.85, 0.3))
				_sfx("squeal")
		else:
			drift_bank = 0.0

func _serve_input(_dt: float) -> void:
	var th := 0.0
	var tr := 0.0
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		th = 1.0
	elif Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		th = -1.0
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		tr = -1.0
	elif Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		tr = 1.0
	car.steer_throttle = th
	car.steer_turn = tr
	car.handbrake = Input.is_key_pressed(KEY_SPACE)
	# ramp zone: fast pass = +tip once per pass
	if RAMP_ZONE.has_point(car.position) and car.speed_abs() > 250.0:
		if not bool(car.get_meta("ramp_cd")):
			car.set_meta("ramp_cd", true)
			cash += RAMP_TIP
			combo += 1
			add_tip(car.position, "+%d แรมพ์!" % RAMP_TIP, Color(0.6, 1.0, 0.6))
			_sfx("boing")
	elif bool(car.get_meta("ramp_cd")) and not RAMP_ZONE.has_point(car.position):
		car.set_meta("ramp_cd", false)
	# keep inside city
	car.position.x = clampf(car.position.x, 26.0, W - 26.0)
	car.position.y = clampf(car.position.y, 26.0, H - 26.0)

# ---------- passenger flow ----------

func _update_trip(dt: float) -> void:
	if trip.is_empty():
		spawn_gap -= dt
		if spawn_gap <= 0.0:
			_new_trip()
		return
	if not trip_active:
		# waiting at pickup point
		if car.position.distance_to(trip["p"]) < PICK_RADIUS and car.speed_abs() < STOP_SPEED:
			trip_active = true
			add_tip(trip["p"], "ขึ้นรถ! ส่งทัน %d วิ" % int(trip["limit"]), Color(0.4, 0.9, 1.0))
			_sfx("pickup")
		return
	# on board: countdown
	trip["left"] -= dt
	if trip["left"] <= 0.0:
		rides_fail += 1
		combo = 0
		add_tip(trip["drop"], "หมดเวลา! ลูกหนี", Color(1.0, 0.45, 0.35))
		_sfx("fail")
		trip = {}
		trip_active = false
		spawn_gap = 1.0
		return
	if car.position.distance_to(trip["drop"]) < PICK_RADIUS and car.speed_abs() < STOP_SPEED:
		var frac: float = trip["left"] / trip["limit"]
		var mult := 1.5
		if frac >= 0.5:
			mult = 2.0
		elif frac < 0.25:
			mult = 1.0
		var total := int(round(float(trip["fare"]) * mult))
		var is_vip := bool(trip.get("vip", false))
		if is_vip:
			total *= 3
		cash += total
		rides_ok += 1
		combo += 1
		if is_vip:
			add_tip(trip["drop"], "+%d บาท x%.1f · VIP!" % [total, mult], Color(1.0, 0.82, 0.2))
		else:
			add_tip(trip["drop"], "+%d บาท x%.1f" % [total, mult], Color(0.2, 0.95, 0.4))
		_sfx("drop")
		freeze_t = 0.06
		trip = {}
		trip_active = false
		spawn_gap = 0.6

func _new_trip() -> void:
	var pickup: Vector2 = POIS[randi() % POIS.size()]
	# หมุดรับต้องไกลจากรถ (ไม่งั้นเริ่มเกมขึ้นรถอัตโนมัติทันที)
	for i in 24:
		pickup = POIS[randi() % POIS.size()]
		if car == null or pickup.distance_to(car.position) > 260.0:
			break
	var drop: Vector2 = pickup
	var d := 0.0
	for i in 24:
		drop = POIS[randi() % POIS.size()]
		d = pickup.distance_to(drop)
		if d > MIN_DROP_DIST:
			break
	var lim := clampf(15.0 + d / 60.0, 18.0, 45.0)
	# สายพันธุ์ลูกค้า 3 แบบจากสไปรต์เดียว: กบปกติ / กบน้อง (เล็ก) / กบธุระ (ใหญ่)
	# VIP ~12%: แหวนทอง + ค่าโดยสาร x3
	trip = {"p": pickup, "drop": drop, "limit": lim, "left": lim, "dist": d, "fare": 50 + int(d / 10.0), "kind": randi() % 3, "vip": randf() < 0.12}
	trip_active = false

# ---------- traffic / hazards ----------

func _build_traffic() -> Array:
	var arr := []
	var lanes := [
		{"axis": "h", "fixed": 148.0, "speed": 170.0},
		{"axis": "h", "fixed": 332.0, "speed": 150.0},
		{"axis": "v", "fixed": 250.0, "speed": 160.0},
		{"axis": "v", "fixed": 886.0, "speed": 185.0},
	]
	for i in lanes.size():
		var lane: Dictionary = lanes[i]
		var pos := Vector2()
		if lane["axis"] == "h":
			pos = Vector2(60.0 + 120.0 * float(i), float(lane["fixed"]))
		else:
			pos = Vector2(float(lane["fixed"]), 90.0 + 140.0 * float(i))
		arr.append({"pos": pos, "axis": lane["axis"], "speed": float(lane["speed"]), "dir": 1.0 if i % 2 == 0 else -1.0, "tint": TRAFFIC_TINTS[i % TRAFFIC_TINTS.size()]})
	return arr

# สีจราจรต่อคัน (ทาบบนภาพเทา = จำเลนง่ายขึ้น)
const TRAFFIC_TINTS := [
	Color(1.0, 1.0, 1.0),        # เทาเดิม
	Color(0.45, 0.55, 1.0),     # ฟ้าสูตรเข้ม
	Color(1.0, 0.5, 0.45),      # แดงอิฐ
	Color(1.0, 0.85, 0.4),      # ทองแท็กซี่
]

func _update_traffic(dt: float) -> void:
	# ครึ่งเกมหลัง: เมืองหน่วงหนัก — จราจรรุกเร็วขึ้น 30%
	var rush := 1.0
	if (120.0 - time_left) > 60.0:
		rush = 1.3
	for t: Dictionary in traffic:
		if t["axis"] == "h":
			t["pos"].x = wrapf(t["pos"].x + t["dir"] * t["speed"] * rush * dt, 0.0, W)
		else:
			t["pos"].y = wrapf(t["pos"].y + t["dir"] * t["speed"] * rush * dt, 0.0, H)
		# near-miss: close while fast, once per second
		if nearmiss_cd <= 0.0 and car != null:
			var rel := car.velocity
			var dx := car.position.distance_to(t["pos"])
			if dx < 48.0 and rel.length() > 240.0:
				nearmiss_cd = 1.0
				cash += NEARMISS_TIP
				combo += 1
				add_tip(t["pos"], "+%d เฉียดสวย!" % NEARMISS_TIP, Color(1.0, 0.95, 0.4))
				_sfx("whoosh")

func _build_slimes() -> Array:
	var arr := []
	for i in 5:
		arr.append({
			"pos": POIS[(i * 2 + 1) % POIS.size()] + Vector2(40.0, 30.0),
			"vel": Vector2(60.0 - 30.0 * float(i), 40.0 - float(i) * 15.0),
		})
	return arr

func _update_slimes(dt: float) -> void:
	# ครึ่งเกมหลัง: สไลม์ออกเที่ยวพุ่งขึ้น 30% เท่ากัน
	var rush := 1.0
	if (120.0 - time_left) > 60.0:
		rush = 1.3
	for s: Dictionary in slime_list:
		s["pos"] = s["pos"] + s["vel"] * rush * dt
		if s["pos"].x < 130.0 or s["pos"].x > 1022.0:
			s["vel"].x *= -1.0
		if s["pos"].y < 70.0 or s["pos"].y > 580.0:
			s["vel"].y *= -1.0
		if car != null and car.position.distance_to(s["pos"]) < 30.0:
			car.apply_slow(2.0)
			_sfx("squish")

func _update_golems(dt: float) -> void:
	golem_timer -= dt
	if golem_timer <= 0.0:
		golem_timer = randf_range(4.0, 7.0)
		# golem crosses one horizontal road at a random x
		var y: float = ROADS_H_Y[randi() % ROADS_H_Y.size()]
		golem_list.append({"pos": Vector2(-40.0, y), "dir": Vector2(1.0, 0.0)})
	for g: Dictionary in golem_list:
		var grush := 1.3 if (120.0 - time_left) > 60.0 else 1.0
		g["pos"] = g["pos"] + g["dir"] * 55.0 * grush * dt
		if car != null and car.position.distance_to(g["pos"]) < 34.0 and car.spin_timer <= 0.0:
			car.apply_spin(1.0)
			add_tip(car.position, "ชนโกเลม!", Color(1.0, 0.3, 0.3))
			_sfx("thud")
			shake_t = 0.35
	golem_list = golem_list.filter(func(g): return g["pos"].x > -60.0 and g["pos"].x < W + 60.0)

# ---------- tips / over ----------

func add_tip(pos: Vector2, txt: String, color: Color) -> void:
	tip_texts.append({"pos": pos, "txt": txt, "left": 1.6, "color": color})

func _update_tips(dt: float) -> void:
	var keep := []
	for t: Dictionary in tip_texts:
		t["left"] -= dt
		t["pos"] = t["pos"] - Vector2(0.0, 24.0 * dt)
		if t["left"] > 0.0:
			keep.append(t)
	tip_texts = keep

func _finish() -> void:
	over = true
	over_info = SaveScript.record_run(cash, rides_ok)
	# จังหวะปิด: ตัดเพลง + จิงเกิล ส่งคืนคู่คืงอย่างน้อย 5 = จัดว่ารวย
	if sfx != null and is_instance_valid(sfx):
		sfx.game_over(rides_ok >= 5)

func _sfx(kind: String) -> void:
	if sfx != null and is_instance_valid(sfx):
		sfx.play(kind)

func _update_smoke(dt: float) -> void:
	# ควันยาง: ปล่อยทุก 0.09 วิขณะดริฟท์ เก็บอายุ 0.7 วิตายผี
	if car != null and car.drifting:
		_smoke_cd -= dt
		if _smoke_cd <= 0.0:
			_smoke_cd = 0.09
			smoke.append({"pos": car.position + Vector2(randf_range(-8.0, 8.0), randf_range(-6.0, 10.0)), "age": 0.0})
	else:
		_smoke_cd = 0.0
	var keep := []
	for s: Dictionary in smoke:
		s["age"] += dt
		if s["age"] < 0.7:
			keep.append(s)
	smoke = keep

# ---------- drawing ----------

func _draw() -> void:
	# grass base + grass patches (deterministic)
	draw_rect(Rect2(0, 0, W, H), Color(0.24, 0.5, 0.28))
	for i in 26:
		var px := 40.0 + float(i * 97 % 1072)
		var py := 40.0 + float(i * 53 % 568)
		draw_rect(Rect2(px, py, 14 + float(i % 3) * 6.0, 8.0 + float(i % 2) * 5.0), Color(0.20, 0.44, 0.24, 0.8))
	_draw_sidewalks()
	_draw_buildings()
	# roads
	_draw_roads()
	_draw_crosswalks()
	# smoke puffs: วงเทาโปร่งขยายตามอายุ วาดก่อนของชิ้นใหญ่
	for s: Dictionary in smoke:
		var t: float = s["age"] / 0.7
		draw_circle(s["pos"], 6.0 + 10.0 * t, Color(0.85, 0.85, 0.85, 0.45 * (1.0 - t)))
	# ramp
	draw_rect(RAMP_ZONE, Color(0.85, 0.9, 0.95))
	draw_rect(RAMP_ZONE.grow(-4.0), Color(0.55, 0.6, 0.7))
	# POI pins
	for i in POIS.size():
		var p: Vector2 = POIS[i]
		var is_pick: bool = not trip.is_empty() and not trip_active and trip["p"] == p
		var is_drop: bool = not trip.is_empty() and trip_active and trip["drop"] == p
		var c := Color(0.95, 0.75, 0.2)
		if is_pick:
			c = Color(0.3, 0.95, 0.5)
		elif is_drop:
			c = Color(0.35, 0.75, 1.0)
		draw_circle(p, 12.0, c)
		draw_circle(p, 7.0, Color(0.08, 0.08, 0.08))
		# VIP: แหวนทองกระพริบรอบหมุดรับ
		if is_pick and not trip.is_empty() and bool(trip.get("vip", false)):
			var rr := 15.0 + 2.5 * sin(_anim_t * 7.0)
			draw_arc(p, rr, 0.0, TAU, 28, Color(1.0, 0.82, 0.2, 0.9), 3.0)
			draw_arc(p, rr + 4.0, 0.0, TAU, 28, Color(1.0, 0.82, 0.2, 0.35), 1.5)
	# ผู้โดยสารรอขึ้นรถที่หมุดรับ (ยืนเหนือหมุดเล็กน้อย) — สายพันธุ์จากสไปรต์จริง
	if not trip.is_empty() and not trip_active:
		var kind: int = int(trip.get("kind", 0))
		var tex: Texture2D = PASS_TEX
		var half := 11.0
		if kind == 1:
			tex = PASS_LIZ_TEX       # กิ้งก่าลูกน้อยตัวอวบหน่อย
			half = 12.0
		elif kind == 2:
			tex = PASS_CHICK_TEX     # ไก่แก้วตัวกลมโตกว่า
			half = 13.0
		draw_texture_rect(tex, Rect2(trip["p"] + Vector2(-half, -16.0 - half * 2.0), Vector2(half * 2.0, half * 2.0)), false)
		# มงกุฎทอง: ประชาสัมพันธ์ว่าคนนี้รวยเป็นสอง
		if bool(trip.get("vip", false)):
			var cy := -16.0 - half * 2.0
			var base := Vector2(trip["p"].x - half * 0.55, trip["p"].y + cy - 3.0)
			draw_rect(Rect2(base, Vector2(half * 1.1, 3.0)), Color(1.0, 0.82, 0.2))
			draw_colored_polygon(PackedVector2Array([
				trip["p"] + Vector2(-half * 0.55, cy - 3.0),
				trip["p"] + Vector2(-half * 0.2, cy - 8.0),
				trip["p"] + Vector2(0.0, cy - 4.0),
				trip["p"] + Vector2(half * 0.2, cy - 8.0),
				trip["p"] + Vector2(half * 0.55, cy - 3.0),
			]), Color(1.0, 0.85, 0.25))
	# trip arrow: pickup or drop
	if not trip.is_empty() and car != null:
		var target: Vector2 = trip["drop"] if trip_active else trip["p"]
		var rel := target - car.position
		if rel.length() > PICK_RADIUS:
			var ang := rel.angle()
			var arrow_pos := car.position + Vector2.RIGHT.rotated(ang) * 52.0
			_draw_arrow(arrow_pos, ang, Color(0.98, 0.85, 0.25))
	# traffic (civilian cars, rotated per lane direction)
	for t: Dictionary in traffic:
		var face := 0.0
		if t["axis"] == "h":
			face = 0.0 if float(t["dir"]) > 0.0 else PI
		else:
			face = PI * 0.5 if float(t["dir"]) > 0.0 else -PI * 0.5
		draw_set_transform(t["pos"], face - CAR_ANG, Vector2(0.9, 0.9))
		draw_texture_rect(TRAFFIC_TEX, Rect2(-24, -24, 48, 48), false, t.get("tint", Color(1.0, 1.0, 1.0)))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# slimes (squash-stretch blobs)
	for i in slime_list.size():
		var s: Dictionary = slime_list[i]
		var puff: float = 0.1 * sin(_anim_t * 6.0 + float(i) * 1.7)
		draw_set_transform(s["pos"], 0.0, Vector2(1.0 + puff, 1.0 - puff))
		draw_texture_rect(SLIME_TEX, Rect2(-14, -14, 28, 28), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# golems (walkers)
	for g: Dictionary in golem_list:
		draw_texture_rect(GOLEM_TEX, Rect2(g["pos"] + Vector2(-16, -30), Vector2(32, 32)), false)
	# floating tips
	for t: Dictionary in tip_texts:
		var alpha: float = clampf(t["left"] / 1.6, 0.0, 1.0)
		draw_string(ThemeDB.fallback_font, t["pos"] + Vector2(1, 1), t["txt"], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, Color(t["color"].r, t["color"].g, t["color"].b, alpha))
	_draw_hud()
	if over:
		_draw_over()

func _draw_sidewalks() -> void:
	var sc := Color(0.55, 0.52, 0.48)
	for hy in ROADS_H_Y:
		draw_rect(Rect2(0, float(hy) - 54.0, W, 6), sc)
		draw_rect(Rect2(0, float(hy) + 48.0, W, 6), sc)
	for vx in ROADS_V_X:
		draw_rect(Rect2(float(vx) - 54.0, 0, 6, H), sc)
		draw_rect(Rect2(float(vx) + 48.0, 0, 6, H), sc)

func _draw_buildings() -> void:
	# ตึกกระจายตามภูมิลำเนา (สูตรตายตัว no RNG → ไม่กระพริบ)
	var rows := [[26, 41], [178, 224], [362, 408], [548, 630]]
	var cols := [[16, 106], [236, 512], [642, 918], [1042, 1136]]
	var pal := [
		Color(0.45, 0.37, 0.35), Color(0.36, 0.40, 0.46), Color(0.46, 0.40, 0.30),
		Color(0.34, 0.42, 0.38), Color(0.47, 0.37, 0.30),
	]
	var bi := 0
	for ry: Array in rows:
		for cx: Array in cols:
			for parts in 2:
				var x0 := float(cx[0]) + (float(cx[1]) - float(cx[0])) * 0.58 * float(parts)
				var x1 := float(cx[1]) - (float(cx[1]) - float(cx[0])) * 0.34 * float(parts)
				var y_t := float(ry[0])
				var y_b := float(ry[0]) + (float(ry[1]) - float(ry[0])) * (0.60 if parts == 1 else 0.96)
				var rect := Rect2(x0, y_t, x1 - x0, y_b - y_t)
				draw_rect(rect, pal[bi % pal.size()])
				draw_rect(Rect2(rect.position, Vector2(rect.size.x, 4.0)), Color(0, 0, 0, 0.25))
				# หน้าต่างไฟ
				var nc := int(rect.size.x / 24.0)
				var nr := int(rect.size.y / 20.0)
				for wx in nc:
					for wy in nr:
						var lit: bool = (wx * 13 + wy * 7 + bi * 5) % 4 != 0
						var wc := Color(1.0, 0.88, 0.5, 0.9) if lit else Color(0.13, 0.15, 0.19)
						draw_rect(Rect2(rect.position.x + 8.0 + float(wx) * 22.0, rect.position.y + 8.0 + float(wy) * 18.0, 7.0, 9.0), wc)
				bi += 1
		bi += 1

func _draw_crosswalks() -> void:
	for vx in ROADS_V_X:
		for hy in ROADS_H_Y:
			for dx in [-64.0, 60.0]:
				var xx: float = float(vx) + float(dx)
				if xx < 10.0 or xx > W - 12.0:
					continue
				for k in 4:
					draw_rect(Rect2(xx, float(hy) - 40.0 + float(k) * 21.0, 7.0, 12.0), Color(0.95, 0.95, 0.95, 0.8))

func _draw_roads() -> void:
	for y in ROADS_H_Y:
		draw_rect(Rect2(0, y - ROAD_W * 0.5, W, ROAD_W), Color(0.32, 0.32, 0.36))
	for x in ROADS_V_X:
		draw_rect(Rect2(x - ROAD_W * 0.5, 0, ROAD_W, H), Color(0.32, 0.32, 0.36))
	# dashed center lines
	for y in ROADS_H_Y:
		for i in 19:
			draw_rect(Rect2(30.0 + float(i) * 60.0, y - 1.5, 30.0, 3.0), Color(0.9, 0.85, 0.3, 0.7))
	for x in ROADS_V_X:
		for i in 10:
			draw_rect(Rect2(x - 1.5, 24.0 + float(i) * 64.0, 3.0, 30.0), Color(0.9, 0.85, 0.3, 0.7))

func _draw_arrow(pos: Vector2, ang: float, color: Color) -> void:
	var pts := PackedVector2Array([
		Vector2(14, 0), Vector2(-8, -9), Vector2(-3, 0), Vector2(-8, 9),
	])
	var xf := Transform2D(ang, pos)
	var drawn := PackedVector2Array()
	for p in pts:
		drawn.append(xf * p)
	draw_colored_polygon(drawn, color)

func _draw_hud() -> void:
	# top bar
	draw_rect(Rect2(0, 0, W, 34), Color(0.08, 0.08, 0.12, 0.85))
	draw_string(ThemeDB.fallback_font, Vector2(14, 23), "เวลา %.1f" % time_left, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color(1.0, 0.85, 0.3) if time_left < 20.0 else Color(0.95, 0.95, 0.9))
	draw_string(ThemeDB.fallback_font, Vector2(180, 23), "เงิน %d" % cash, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color(0.2, 0.95, 0.4))
	var st: String = "รับได้ %d · พลาด %d · %s Lv%d" % [rides_ok, rides_fail, str(CAR_NAMES.get(car.car_id, "Kubi Cab")), int((best.get("upgrades", {}) as Dictionary).get(car.car_id, 0))]
	draw_string(ThemeDB.fallback_font, Vector2(340, 23), st, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, Color(0.9, 0.9, 0.95))
	draw_string(ThemeDB.fallback_font, Vector2(640, 23), "คอมโบ x%d" % combo, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, Color(1.0, 0.75, 0.3))
	# trip info panel
	if not trip.is_empty():
		var head: String = "รับ: ไปหมุดเหลือง" if not trip_active else "ส่ง: ไปหมุดฟ้า"
		if bool(trip.get("vip", false)):
			head += " · VIP x3"
		var bar := Rect2(700, 4, 200, 26)
		draw_rect(bar.grow(1.5), Color(0.12, 0.12, 0.16))
		var frac: float = trip["left"] / trip["limit"]
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * frac, bar.size.y)), Color(0.2, 0.9, 0.45) if frac > 0.4 else Color(0.95, 0.4, 0.3))
		var fc := Color(0.97, 0.97, 0.97)
		if bool(trip.get("vip", false)):
			fc = Color(1.0, 0.82, 0.2) if int(_anim_t * 4.0) % 2 == 0 else Color(0.97, 0.97, 0.97)
		draw_string(ThemeDB.fallback_font, bar.position + Vector2(8, 18), "%s · %.1f วิ · %d บาท" % [head, trip["left"], trip["fare"]], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, fc)
	# controls hint bottom
	draw_rect(Rect2(0, H - 26, W, 26), Color(0.08, 0.08, 0.12, 0.7))
	draw_string(ThemeDB.fallback_font, Vector2(12, H - 8), "ลูกศร/WASD ขับ · เคาะ Space เบรกมือ = ดริฟท์ · จอดใกล้หมุดเพื่อรับ/ส่ง · R เริ่มใหม่ · ESC เมนู", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color(0.9, 0.9, 0.85))

func _draw_over() -> void:
	draw_rect(Rect2(0, 0, W, H), Color(0, 0, 0, 0.72))
	var center := Vector2(W * 0.5, H * 0.5)
	draw_string(ThemeDB.fallback_font, center + Vector2(-260, -70), "หมดเวลา! รวมได้ %d บาท" % cash, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 34, Color(1.0, 0.9, 0.3))
	var best_cash := int(over_info.get("best_cash", cash))
	var is_new: bool = bool(over_info.get("new_best_cash", false))
	var bc := Color(0.35, 0.95, 0.5) if is_new else Color(0.9, 0.9, 0.9)
	draw_string(ThemeDB.fallback_font, center + Vector2(-260, -24), "รับได้ %d · พลาด %d · สถิติเงินดีสุด %d%s" % [rides_ok, rides_fail, best_cash, " (ใหม่!)" if is_new else ""], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 19, bc)
	var gpid: String = str(over_info.get("car_pick", "kubi"))
	var glv: int = int((over_info.get("upgrades", {}) as Dictionary).get(gpid, 0))
	draw_string(ThemeDB.fallback_font, center + Vector2(-260, 6), "เงินสะสมทุกกะ: %d บาท · รถ %s Lv%d — ไปดูที่เมนู 'รถและอู่อัปเกรด'" % [int(over_info.get("total_cash", 0)), str(CAR_NAMES.get(gpid, "Kubi Cab")), glv], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, Color(1.0, 0.85, 0.45))
	for u: Variant in over_info.get("new_unlocked", []):
		draw_string(ThemeDB.fallback_font, center + Vector2(-260, 12), "ปลดล็อกรถใหม่: %s" % str(u), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 17, Color(0.6, 0.9, 1.0))
	draw_string(ThemeDB.fallback_font, center + Vector2(-190, 70), "R เล่นใหม่ · ESC กลับเมนู", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color(0.85, 0.85, 0.8))
