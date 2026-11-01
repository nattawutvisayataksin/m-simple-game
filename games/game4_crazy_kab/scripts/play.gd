extends Node2D
# play.gd - game room: 120s clock, pick up & deliver (Crazy Taxi style)
# Thai notes kept short on purpose (long Thai strings corrupt during generation)

signal back_to_menu

const CarScript := preload("res://scripts/car.gd")
const SaveScript := preload("res://scripts/save.gd")

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
	if time_left <= 0.0:
		time_left = 0.0
		_finish()
		return
	_serve_input(dt)
	_update_trip(dt)
	_update_traffic(dt)
	_update_slimes(dt)
	_update_golems(dt)
	_update_tips(dt)
	if nearmiss_cd > 0.0:
		nearmiss_cd -= dt
	if drift_bank > 0.0 or car.drifting:
		if car.drifting:
			drift_bank += dt
			if drift_bank >= 0.8:
				drift_bank -= 0.8
				cash += DRIFT_TIP
				add_tip(car.position, "+%d ดริฟท์!" % DRIFT_TIP, Color(1.0, 0.85, 0.3))
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
		return
	# on board: countdown
	trip["left"] -= dt
	if trip["left"] <= 0.0:
		rides_fail += 1
		combo = 0
		add_tip(trip["drop"], "หมดเวลา! ลูกหนี", Color(1.0, 0.45, 0.35))
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
		cash += total
		rides_ok += 1
		combo += 1
		add_tip(trip["drop"], "+%d บาท x%.1f" % [total, mult], Color(0.2, 0.95, 0.4))
		trip = {}
		trip_active = false
		spawn_gap = 0.6

func _new_trip() -> void:
	var pickup: Vector2 = POIS[randi() % POIS.size()]
	var drop: Vector2 = pickup
	var d := 0.0
	for i in 24:
		drop = POIS[randi() % POIS.size()]
		d = pickup.distance_to(drop)
		if d > MIN_DROP_DIST:
			break
	var lim := clampf(15.0 + d / 60.0, 18.0, 45.0)
	trip = {"p": pickup, "drop": drop, "limit": lim, "left": lim, "dist": d, "fare": 50 + int(d / 10.0)}
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
		arr.append({"pos": pos, "axis": lane["axis"], "speed": float(lane["speed"]), "dir": 1.0 if i % 2 == 0 else -1.0})
	return arr

func _update_traffic(dt: float) -> void:
	for t: Dictionary in traffic:
		if t["axis"] == "h":
			t["pos"].x = wrapf(t["pos"].x + t["dir"] * t["speed"] * dt, 0.0, W)
		else:
			t["pos"].y = wrapf(t["pos"].y + t["dir"] * t["speed"] * dt, 0.0, H)
		# near-miss: close while fast, once per second
		if nearmiss_cd <= 0.0 and car != null:
			var rel := car.velocity
			var dx := car.position.distance_to(t["pos"])
			if dx < 48.0 and rel.length() > 240.0:
				nearmiss_cd = 1.0
				cash += NEARMISS_TIP
				combo += 1
				add_tip(t["pos"], "+%d เฉียดสวย!" % NEARMISS_TIP, Color(1.0, 0.95, 0.4))

func _build_slimes() -> Array:
	var arr := []
	for i in 5:
		arr.append({
			"pos": POIS[(i * 2 + 1) % POIS.size()] + Vector2(40.0, 30.0),
			"vel": Vector2(60.0 - 30.0 * float(i), 40.0 - float(i) * 15.0),
		})
	return arr

func _update_slimes(dt: float) -> void:
	for s: Dictionary in slime_list:
		s["pos"] = s["pos"] + s["vel"] * dt
		if s["pos"].x < 130.0 or s["pos"].x > 1022.0:
			s["vel"].x *= -1.0
		if s["pos"].y < 70.0 or s["pos"].y > 580.0:
			s["vel"].y *= -1.0
		if car != null and car.position.distance_to(s["pos"]) < 30.0:
			car.apply_slow(2.0)

func _update_golems(dt: float) -> void:
	golem_timer -= dt
	if golem_timer <= 0.0:
		golem_timer = randf_range(4.0, 7.0)
		# golem crosses one horizontal road at a random x
		var y: float = ROADS_H_Y[randi() % ROADS_H_Y.size()]
		golem_list.append({"pos": Vector2(-40.0, y), "dir": Vector2(1.0, 0.0)})
	for g: Dictionary in golem_list:
		g["pos"] = g["pos"] + g["dir"] * 55.0 * dt
		if car != null and car.position.distance_to(g["pos"]) < 34.0 and car.spin_timer <= 0.0:
			car.apply_spin(1.0)
			add_tip(car.position, "ชนโกเลม!", Color(1.0, 0.3, 0.3))
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

# ---------- drawing ----------

func _draw() -> void:
	# grass base
	draw_rect(Rect2(0, 0, W, H), Color(0.24, 0.5, 0.28))
	# city blocks between roads (simple deterministic rows)
	var block_color := Color(0.5, 0.44, 0.4)
	for bx in [Rect2(250, 10, 240, 40), Rect2(700, 10, 180, 40), Rect2(250, 610, 240, 30), Rect2(700, 610, 180, 30)]:
		draw_rect(bx, block_color)
	# roads
	_draw_roads()
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
	# trip arrow: pickup or drop
	if not trip.is_empty() and car != null:
		var target: Vector2 = trip["drop"] if trip_active else trip["p"]
		var rel := target - car.position
		if rel.length() > PICK_RADIUS:
			var ang := rel.angle()
			var arrow_pos := car.position + Vector2.RIGHT.rotated(ang) * 52.0
			_draw_arrow(arrow_pos, ang, Color(0.98, 0.85, 0.25))
	# traffic cars (gray)
	for t: Dictionary in traffic:
		draw_rect(Rect2(t["pos"] - Vector2(16, 10), Vector2(32, 20)), Color(0.62, 0.62, 0.66))
		draw_rect(Rect2(t["pos"] - Vector2(10, 10), Vector2(18, 20)), Color(0.35, 0.4, 0.45))
	# slimes (green blobs)
	for s: Dictionary in slime_list:
		draw_circle(s["pos"], 13.0, Color(0.35, 0.85, 0.4))
		draw_circle(s["pos"] + Vector2(-3, -3), 5.0, Color(0.7, 1.0, 0.75))
	# golems (gray walkers)
	for g: Dictionary in golem_list:
		draw_rect(Rect2(g["pos"] - Vector2(14, 16), Vector2(28, 32)), Color(0.5, 0.5, 0.55))
		draw_rect(Rect2(g["pos"] + Vector2(-6, -10), Vector2(12, 8)), Color(0.2, 0.35, 0.25))
	# floating tips
	for t: Dictionary in tip_texts:
		var alpha: float = clampf(t["left"] / 1.6, 0.0, 1.0)
		draw_string(ThemeDB.fallback_font, t["pos"] + Vector2(1, 1), t["txt"], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, Color(t["color"].r, t["color"].g, t["color"].b, alpha))
	_draw_hud()
	if over:
		_draw_over()

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
	var st: String = "รับได้ %d · พลาด %d" % [rides_ok, rides_fail]
	draw_string(ThemeDB.fallback_font, Vector2(340, 23), st, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, Color(0.9, 0.9, 0.95))
	draw_string(ThemeDB.fallback_font, Vector2(560, 23), "คอมโบ x%d" % combo, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, Color(1.0, 0.75, 0.3))
	# trip info panel
	if not trip.is_empty():
		var head: String = "รับ: ไปหมุดเหลือง" if not trip_active else "ส่ง: ไปหมุดฟ้า"
		var bar := Rect2(700, 4, 200, 26)
		draw_rect(bar.grow(1.5), Color(0.12, 0.12, 0.16))
		var frac: float = trip["left"] / trip["limit"]
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * frac, bar.size.y)), Color(0.2, 0.9, 0.45) if frac > 0.4 else Color(0.95, 0.4, 0.3))
		draw_string(ThemeDB.fallback_font, bar.position + Vector2(8, 18), "%s · %.1f วิ · %d บาท" % [head, trip["left"], trip["fare"]], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color(0.97, 0.97, 0.97))
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
	for u: Variant in over_info.get("new_unlocked", []):
		draw_string(ThemeDB.fallback_font, center + Vector2(-260, 12), "ปลดล็อกรถใหม่: %s" % str(u), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 17, Color(0.6, 0.9, 1.0))
	draw_string(ThemeDB.fallback_font, center + Vector2(-190, 70), "R เล่นใหม่ · ESC กลับเมนู", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color(0.85, 0.85, 0.8))
