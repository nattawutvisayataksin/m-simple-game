extends Node2D
# หอคอยคู่ฟ้า (Kub Kingdom Rush) - ฉากหลัก
# T2.6 (feedback ผู้อำนวยการ): ตัดฉากล่างออก - ฉากเดียว 1152x648, มอนบุกทางเดียว
# จากประตูม่วงบนซ้าย -> ถนนวกลงเลี้ยวขวา -> ประตูปราสาท (ขวาบน)
# แก้เดินซ้อน: มอนแต่ละตัวเลื่อนข้างถนนสลับซ้าย/ขวา ±13px + สุ่มความเร็ว ±8%

const EnemyScript := preload("res://scripts/enemy.gd")
const TowerScript := preload("res://scripts/tower.gd")
const FROG_TEX := preload("res://assets/art/gen/frog.png")
const LIZARD_TEX := preload("res://assets/art/gen/lizard_front.png")
const FROG_SHEET := preload("res://assets/art/gen/frog_sheet.png")
const LIZARD_SHEET := preload("res://assets/art/gen/lizard_sheet.png")
const LIZARD_SIDE_SHEET := preload("res://assets/art/gen/lizard_side_sheet.png")
const TOWER_ARCHER_TEX := preload("res://assets/art/gen/tower_archer.png")
const TOWER_CANNON_TEX := preload("res://assets/art/gen/tower_cannon.png")
const ICON_BOW := preload("res://assets/art/icons/bow.png")
const ICON_HAMMER := preload("res://assets/art/icons/hammer.png")
const ICON_COIN := preload("res://assets/art/icons/coin.png")

# ตารางป้อม (T3): ค่าบาลานซ์รวมที่เดียวจูนง่าย - ราคา/ดาเมจ/คูลดาวน์/รัศมี/ความเร็วกระสุน/ระเบิดกระจุก
const TOWER_DEFS := {
	"archer": {
		"name": "นักธนู", "cost": 90, "kind": TowerScript.ARCHER,
		"tex": TOWER_ARCHER_TEX, "icon": ICON_BOW,
		"dmg": 9.0, "interval": 0.75, "range": 170.0, "shot": 300.0, "splash": 0.0,
	},
	"cannon": {
		"name": "ปืนใหญ่", "cost": 150, "kind": TowerScript.CANNON,
		"tex": TOWER_CANNON_TEX, "icon": ICON_HAMMER,
		"dmg": 30.0, "interval": 1.7, "range": 200.0, "shot": 220.0, "splash": 70.0,
	},
}

# หมุดโลก (ฉากเดียว 1152x648): ประตูม่วงบนซ้าย (261, 250) ; ประตูปราสาท (816, 495)
const PATH_A: Array[Vector2] = [
	Vector2(261, 260),
	Vector2(261, 420),
	Vector2(285, 500),
	Vector2(340, 540),
	Vector2(430, 548),
	Vector2(560, 545),
	Vector2(700, 545),
	Vector2(780, 540),
	Vector2(816, 495),
]

# ลานจุดวางป้อม 4 จุด (หญ้าว่างการันตีบนฉากเดียว)
const TOWER_SPOTS: Array[Vector2] = [
	Vector2(110, 380),  # ทุ่งซ้าย
	Vector2(420, 615),  # ใต้โค้งเลี้ยวขวา
	Vector2(620, 350),  # เหนือถนนแนวนอน
	Vector2(700, 620),  # ใต้ถนนใกล้ปราสาท
]

const SPOT_FILL := Color(1.0, 0.79, 0.24, 0.55)
const SPOT_EDGE := Color(0.16, 0.09, 0.03, 0.9)
const GATE_COLOR := Color(0.55, 0.25, 0.80, 0.80)
const CASTLE_COLOR := Color(1.0, 0.35, 0.15, 0.85)

const SPAWN_INTERVAL := 2.2
const FROG_SPEED := 35.0
const LIZARD_SPEED := 60.0
const START_LIVES := 20
const LANE_OFFSET := 13.0  # ระยะเลื่อนข้างถนนต่อมอน (กันซ้อนตึงตึว)

var _spawn_timer := 0.0
var _spawn_seq := 0
var _lives := START_LIVES
var _gold := 180            # ทุนเริ่มพอสร้างนักธนู 1 + กองเผื่อ (T3 economy)
var _lives_label: Label
var _gold_label: Label
var _hud: CanvasLayer
var _built: Array[bool] = [false, false, false, false]   # ลานที่ปูป้อมแล้ว
var _menu: Control            # แผงเลือกป้อม (เปิดเมื่อคลิกลานว่าง)

func _ready() -> void:
	y_sort_enabled = true  # มอนวาดเรียงตามแนวระดับ (ตัวล่างจอบนตัวบนจอ - แก้ทับซ้อนดูลอย)
	_build_lives_label()
	queue_redraw()

func _process(delta: float) -> void:
	_spawn_timer += delta
	if _spawn_timer >= SPAWN_INTERVAL:
		_spawn_timer = 0.0
		if _spawn_point_clear():
			_spawn_next()

func _spawn_point_clear() -> bool:
	# เว้นระยะเกิด: ถ้ามีมอนยังจอดแถวปากประตู (< 80px) เลื่อนเกิดไปก่อน 0.45 วิ
	var gate := PATH_A[0]
	for child in get_children():
		if child is Node2D and child != _hud:
			var v: Node2D = child
			if v.position.distance_to(gate) < 80.0 and v.has_method("_process") and v.get_script() == EnemyScript:
				_spawn_timer = SPAWN_INTERVAL - 0.45
				return false
	return true

func _spawn_next() -> void:
	# ออกทีละชุดละ 3 ตัว (กบ 3 -> กิ้งก่า 3 ...) ความไล่เฉดเส้นทางข้างสลับ ซ้าย/ขวา/กลาง
	var batch := int(_spawn_seq / 3.0)
	var kind := (batch % 2) == 0
	var lanes := [-13.0, 13.0, 0.0]
	var lane: float = lanes[_spawn_seq % 3]
	_spawn_seq += 1
	var jitter := randf_range(0.94, 1.06)   # สุ่มความเร็วบาง ๆ กันเดินเป๊ะมืดเป๊ะ
	if kind:
		_spawn_enemy(FROG_TEX, FROG_SHEET, _shift_path(PATH_A, lane), FROG_SPEED * jitter, true, false, 59, null, 43, 26.0, 15)
	else:
		_spawn_enemy(LIZARD_TEX, LIZARD_SHEET, _shift_path(PATH_A, lane), LIZARD_SPEED * jitter, true, false, 56, LIZARD_SIDE_SHEET, 43, 42.0, 25)

func _shift_path(path: Array[Vector2], off: float) -> Array[Vector2]:
	# เลื่อน waypoint ทั้งเส้นตามแนวตั้งฉากของแต่ละช่วง (สายเดินข้างกันไม่ทับถนนกลาง)
	var out: Array[Vector2] = []
	for i in range(path.size()):
		var dir: Vector2
		if i == 0:
			dir = path[1] - path[0]
		elif i == path.size() - 1:
			dir = path[i] - path[i - 1]
		else:
			dir = path[i + 1] - path[i - 1]
		if absf(dir.x) >= absf(dir.y):
			out.append(path[i] + Vector2(0, off))   # ช่วงเดินราบ -> เลื่อนตามแกน y
		else:
			out.append(path[i] + Vector2(off, 0))   # ช่วงเดินตั้ง -> เลื่อนตามแกน x
	return out

func _spawn_enemy(texture: Texture2D, sheet: Texture2D, path: Array[Vector2], speed: float, no_flip: bool, faces_left: bool, bottom_row: int, s_sheet: Texture2D = null, s_bottom: int = 43, hp: float = 26.0, gold: int = 15) -> void:
	var e := EnemyScript.new()
	e.sheet = sheet          # เฟรมเดินจริงถ้ามี sheet (fallback texture นิ่ง)
	e.texture = texture
	e.waypoints = PackedVector2Array(path)
	e.speed = speed
	e.no_flip = no_flip
	e.faces_left = faces_left
	e.body_bottom_row = bottom_row  # แถวเท้าจริงในเฟรม
	e.side_sheet = s_sheet          # ชุดหันข้าง (ช่วงเดินแนวนอน)
	e.side_bottom_row = s_bottom
	e.max_hp = hp        # เลือดต่อชนิด (T3)
	e.reward = gold      # ทองต่อการฆ่า (T3)
	add_child(e)
	e.reached_castle.connect(_on_enemy_leak)
	e.died.connect(_on_enemy_died)

func _on_enemy_leak() -> void:
	_lives -= 1
	_update_lives()
	queue_redraw()

func _on_enemy_died(reward: int, at: Vector2) -> void:
	# ทองรางวัลต่อการฆ่า + จุดป๊อบเงินลอยขึ้น (T3)
	_gold += reward
	_update_gold()
	_gold_popup(reward, at)

func _gold_popup(amount: int, at: Vector2) -> void:
	var lb := Label.new()
	lb.text = "+%d" % amount
	lb.z_index = 60
	lb.position = at + Vector2(-16, -44)
	var st := LabelSettings.new()
	st.font_size = 17
	st.font_color = Color(1.0, 0.85, 0.2)
	st.outline_size = 6
	st.outline_color = Color(0.15, 0.09, 0.02)
	lb.label_settings = st
	add_child(lb)
	var t := lb.create_tween()
	t.set_parallel(true)
	t.tween_property(lb, "position", lb.position + Vector2(0, -30), 0.8)
	t.tween_property(lb, "modulate:a", 0.0, 0.8).set_delay(0.3)
	t.chain().tween_callback(lb.queue_free)

func _update_gold() -> void:
	if _gold_label:
		_gold_label.text = "ทอง: %d" % _gold

func _flash_gold() -> void:
	# เงินไม่พอ: แฟลชแดงบอก
	if _gold_label == null:
		return
	_gold_label.modulate = Color(1.0, 0.35, 0.2)
	var t := _gold_label.create_tween()
	t.tween_property(_gold_label, "modulate", Color.WHITE, 0.5)

# ---------- เมนูสร้างป้อม (T3) ----------
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var p := to_local(event.position)
		for i in range(TOWER_SPOTS.size()):
			if _built[i]:
				continue
			if p.distance_to(TOWER_SPOTS[i]) <= 30.0:
				_open_menu(i)
				return
		if _menu != null:
			_close_menu()
	elif event.is_action_pressed("ui_cancel") and _menu != null:
		_close_menu()

func _open_menu(spot_idx: int) -> void:
	if _built[spot_idx]:
		return
	_close_menu()
	var panel := PanelContainer.new()
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 14)
	panel.add_child(hb)
	for key in ["archer", "cannon"]:
		var def: Dictionary = TOWER_DEFS[key]
		var col := VBoxContainer.new()
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		var btn := TextureButton.new()
		btn.texture_normal = def["icon"]
		btn.custom_minimum_size = Vector2(52, 52)
		btn.ignore_texture_size = true
		btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		btn.tooltip_text = "%s (รัศมี %d, ดาเมจ %.0f)" % [def["name"], def["range"], def["dmg"]]
		btn.pressed.connect(_build_tower.bind(spot_idx, key))
		col.add_child(btn)
		var cost := Label.new()
		cost.text = "%d" % def["cost"]
		cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var cst := LabelSettings.new()
		cst.font_size = 15
		cst.font_color = Color(1.0, 0.85, 0.2)
		cst.outline_size = 5
		cst.outline_color = Color(0.15, 0.09, 0.02)
		cost.label_settings = cst
		col.add_child(cost)
		hb.add_child(col)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.07, 0.03, 0.9)
	style.set_corner_radius_all(8)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	panel.add_theme_stylebox_override("panel", style)
	panel.position = TOWER_SPOTS[spot_idx] + Vector2(-66, -46)
	panel.position.x = clampf(panel.position.x, 8.0, 1152.0 - 150.0)
	panel.position.y = clampf(panel.position.y, 8.0, 648.0 - 150.0)
	_menu = panel
	add_child(panel)

func _close_menu() -> void:
	if _menu != null:
		_menu.queue_free()
		_menu = null

func _build_tower(spot_idx: int, key: String) -> void:
	var def: Dictionary = TOWER_DEFS[key]
	if _gold < int(def["cost"]):
		_flash_gold()
		return
	_gold -= int(def["cost"])
	_update_gold()
	var t := TowerScript.new()
	t.setup(def["kind"], def["tex"], def["dmg"], def["interval"], def["range"], def["shot"], def["splash"])
	t.position = TOWER_SPOTS[spot_idx]
	add_child(t)
	_built[spot_idx] = true
	_close_menu()
	queue_redraw()

func _update_lives() -> void:
	if _lives_label:
		_lives_label.text = "ชีวิต: %d" % _lives

# ---------- ภาพแต่งบนฉาก (overlay การออกแบบ) ----------
func _draw() -> void:
	# จุดเกิดมอน: วงม่วงที่ปากประตูบน (ทางเดียว)
	draw_circle(Vector2(261, 250), 14.0, GATE_COLOR)
	# จุดหมาย (ประตูปราสาท): วงส้มแดง
	draw_circle(Vector2(816, 495), 12.0, CASTLE_COLOR)
	# ลานจุดวางป้อม: วงทอง + ขอบเข้ม (ลานที่ปูแล้วไม่วาด - เหลือป้อมจริง)
	for i in range(TOWER_SPOTS.size()):
		if _built[i]:
			continue
		draw_circle(TOWER_SPOTS[i], 26.0, SPOT_FILL)
		draw_arc(TOWER_SPOTS[i], 26.0, 0.0, TAU, 32, SPOT_EDGE, 2.0, true)

func _build_lives_label() -> void:
	_hud = CanvasLayer.new()
	_hud.layer = 10
	add_child(_hud)
	_lives_label = Label.new()
	var ls := LabelSettings.new()
	ls.font_size = 22
	ls.font_color = Color(1.0, 0.79, 0.24)
	ls.outline_size = 6
	ls.outline_color = Color(0.16, 0.09, 0.03)
	_lives_label.label_settings = ls
	_lives_label.position = Vector2(16, 12)
	_lives_label.text = "ชีวิต: %d" % _lives
	_hud.add_child(_lives_label)
	# แถวทอง (T3): ไอคอนเหรียญ + ตัวเลข
	var coin := TextureRect.new()
	coin.texture = ICON_COIN
	coin.custom_minimum_size = Vector2(26, 26)
	coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin.position = Vector2(16, 46)
	_hud.add_child(coin)
	_gold_label = Label.new()
	var gs := LabelSettings.new()
	gs.font_size = 20
	gs.font_color = Color(1.0, 0.85, 0.2)
	gs.outline_size = 6
	gs.outline_color = Color(0.16, 0.09, 0.03)
	_gold_label.label_settings = gs
	_gold_label.position = Vector2(48, 46)
	_gold_label.text = "ทอง: %d" % _gold
	_hud.add_child(_gold_label)
