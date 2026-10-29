extends Node2D
# หอคอยคู่ฟ้า (Kub Kingdom Rush) - ฉากหลัก
# T2.6 (feedback ผู้อำนวยการ): ตัดฉากล่างออก - ฉากเดียว 1152x648, มอนบุกทางเดียว
# จากประตูม่วงบนซ้าย -> ถนนวกลงเลี้ยวขวา -> ประตูปราสาท (ขวาบน)
# แก้เดินซ้อน: มอนแต่ละตัวเลื่อนข้างถนนสลับซ้าย/ขวา ±13px + สุ่มความเร็ว ±8%

const EnemyScript := preload("res://scripts/enemy.gd")
const TowerScript := preload("res://scripts/tower.gd")
const FROG_TEX := preload("res://assets/art/gen/frog.png")
const FROG_SHEET := preload("res://assets/art/gen/frog_sheet.png")
const LIZARD_TEX := preload("res://assets/art/gen/lizard_front.png")
const LIZARD_SHEET := preload("res://assets/art/gen/lizard_sheet.png")
const LIZARD_SIDE_SHEET := preload("res://assets/art/gen/lizard_side_sheet.png")  # T5.1 ชุดหันข้าง 8 ช่อง (หัวหันขวาโดยกำเนิด)
const GOLEM_TEX := preload("res://assets/art/gen/stone_golem.png")
# NB: lizard_side_sheet.png เคยเก็บเป็น stock (ตัดสิน T3.2 ใช้ชุดหน้าตรง) — ฟีดแบ็ค T5.1 สลับกลับมาใช้จริง ช่วงเดินแนวนอน
const TOWER_ARCHER_TEX := preload("res://assets/art/gen/tower_archer.png")
const TOWER_CANNON_TEX := preload("res://assets/art/gen/tower_cannon.png")
const TOWER_MAGE_TEX := preload("res://assets/art/gen/tower_mage.png")
const ICON_BOW := preload("res://assets/art/icons/bow.png")
const ICON_CANNON := preload("res://assets/art/icons/cannon.png")
const ICON_MAGE := TOWER_MAGE_TEX
const ICON_COIN := preload("res://assets/art/icons/coin.png")
const ICON_HEART := preload("res://assets/art/icons/heart.png")
const ICON_UPG_BOW := preload("res://assets/art/icons/upg_bow.png")       # T5 ไอคอนอัปเกรดป้อมธนู
const ICON_UPG_HAMMER := preload("res://assets/art/icons/upg_hammer.png") # T5 ไอคอนอัปเกรดปืนใหญ่
const HeroScript := preload("res://scripts/hero.gd")                     # T5 ฮีโร่ Kubi

# ตารางป้อม (T3): ค่าบาลานซ์รวมที่เดียวจูนง่าย - ราคา/ดาเมจ/คูลดาวน์/รัศมี/ความเร็วกระสุน/ระเบิดกระจุก
const TOWER_DEFS := {
	"archer": {
		"name": "ป้อมธนู", "cost": 90, "kind": TowerScript.ARCHER,
		"tex": TOWER_ARCHER_TEX, "icon": ICON_BOW,
		"dmg": 9.0, "interval": 0.75, "range": 170.0, "shot": 300.0, "splash": 0.0,
		# T5: อัปเกรด Lv2 (ยิงเร็วไกลขึ้น)
		"upg_cost": 70, "upg_icon": ICON_UPG_BOW,
		"upg": {"dmg": 15.0, "interval": 0.6, "range": 200.0, "shot": 330.0, "splash": 0.0},
	},
	"cannon": {
		"name": "ปืนใหญ่", "cost": 150, "kind": TowerScript.CANNON,
		"tex": TOWER_CANNON_TEX, "icon": ICON_CANNON,
		"dmg": 30.0, "interval": 1.7, "range": 200.0, "shot": 220.0, "splash": 70.0,
		# T5: อัปเกรด Lv2 (ระเบิดหนัก บอดใหญ่)
		"upg_cost": 110, "upg_icon": ICON_UPG_HAMMER,
		"upg": {"dmg": 50.0, "interval": 1.45, "range": 225.0, "shot": 220.0, "splash": 85.0},
	},
	"mage": {
		"name": "ป้อมเวท", "cost": 130, "kind": TowerScript.MAGE,
		"tex": TOWER_MAGE_TEX, "icon": ICON_MAGE,
		"dmg": 18.0, "interval": 1.1, "range": 185.0, "shot": 280.0, "splash": 0.0,
		"upg_cost": 100, "upg_icon": ICON_MAGE,
		"upg": {"dmg": 30.0, "interval": 0.95, "range": 210.0, "shot": 320.0, "splash": 0.0},
	},
}
const SELL_REFUND := 0.6   # T5 ขายป้อมคืน 60% ของเงินที่ลงไป (สร้าง + อัปเกรด)

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
	Vector2(160, 445),  # ยุ่มหญ้าทุ่งซ้าย (เลี่ยงต้นไม้กลุ่มบน - ว่างจริง)
	Vector2(420, 615),  # ใต้โค้งเลี้ยวขวา
	Vector2(395, 285),  # ยุ่มหญ้าระหว่างถนนตั้งกับต้นไม้ต้นใหญ่ (เดิม (620,350) ทับปราสาท - ฟีดแบ็ค T4.1)
	Vector2(815, 607),  # ช่องหญ้าด้านล่างต่อจากแขนถนนเข้าปราสาท (เลี่ยงต้นไม้สองกลุ่ม ล่างขวา)
]

const SPOT_HIT_R := 44.0    # T5.1 คลิกอ้อมเผื่อ (เดิม 32 = ต้องคลิกเป๊ะ ๆ หาจุดไม่เจอ)
const GATE_COLOR := Color(0.55, 0.25, 0.80, 0.80)
const CASTLE_COLOR := Color(1.0, 0.35, 0.15, 0.85)

const FROG_SPEED := 35.0
const LIZARD_SPEED := 60.0
const GOLEM_SPEED := 27.0
const GOLEM_HP := 95.0
const GOLEM_RESIST := 0.65
const START_LIVES := 20
const LANE_OFFSET := 13.0  # ระยะเลื่อนข้างถนนต่อมอน (กันซ้อนตึงตึว)

# T4 ระบบคลื่น: หัวใจคลื่นเป็นข้อมูล + เลือดโต 1.15^คลื่น + โบนัสจบคลื่น
# + ปุ่มเรียกคลื่นถัดไปก่อนได้โบนัสตามวินาทีคงเหลือ (ตัดสินใจเสี่ยง) + ชนะ/แพ้
const SPD_GAP := 1.3             # ช่วงห่างเกิดรายตัวในคลื่น (วิ)
const HP_GROWTH := 1.15          # เลือดโตต่อคลื่น
const WAVE_PREP := 7.0           # นับถอยหลังก่อนคลื่นถัดไป
const FIRST_PREP := 10.0         # ก่อนคลื่นแรก: เผื่อเวลาสร้างป้อมแรก
const EARLY_BONUS_PER_SEC := 3.0 # ทองโบนัสต่อวินาทีที่ยังเหลือตอนเรียกก่อน
const WAVE_BONUS_BASE := 25      # โบนัสจบคลื่น = base + (คลื่นที่ * step)
const WAVE_BONUS_STEP := 5
# คลื่น 10 รอบ: [ชนิด, จำนวน] — ท้ายเกมกิ้งก่าเร็วจำนวนโก่งขึ้น จบกองใหญ่คลื่นสุดท้าย
const WAVES: Array = [
	[["frog", 5]],
	[["frog", 6]],
	[["frog", 4], ["lizard", 3]],
	[["lizard", 5]],
	[["frog", 6], ["lizard", 4]],
	[["frog", 5], ["lizard", 6]],
	[["frog", 9], ["lizard", 5], ["stone_golem", 1]],
	[["lizard", 9], ["stone_golem", 2]],
	[["frog", 8], ["lizard", 8]],
	[["frog", 6], ["lizard", 12]],
]

var _state := "prep"        # prep | wave | won | lost
var _wave_idx := -1         # คลื่นปัจจุบัน (0-based, -1 = ยังไม่เริ่ม)
var _queue: Array = []      # คิวเกิดของคลื่นนี้ ["frog", ...]
var _spawn_seq := 0
var _gap_t := 0.0           # จับเวลาเกิดรายตัวในคลื่น
var _prep_t := FIRST_PREP   # นับถอยหลังระหว่างคลื่น
var _lives := START_LIVES
var _gold := 180            # ทุนเริ่มพอสร้างนักธนู 1 + กองเผื่อ (T3 economy)
var _lives_label: Label
var _gold_label: Label
var _hud: CanvasLayer
var _towers: Array = [null, null, null, null]   # T5: node ป้อมต่อลาน (null = ว่าง, แทน _built เดิม)
var _lvl: Array[int] = [0, 0, 0, 0]             # T5: เลเวลต่อลาน (0=ว่าง 1 2)
var _inv: Array[int] = [0, 0, 0, 0]             # T5: เงินที่ลงทุนต่อลาน (สร้าง+อัปเกรด ใช้คิดคืนขาย)
var _menu: Control            # แผงเลือกป้อม (เปิดเมื่อคลิกลานว่าง)
var _menu_spot := -1          # ลานที่เมนูกำลังเปิด (สำหรับปุ่ม 1/2 เลือกป้อม)
var _menu_mode := ""          # T5: "build" = เลือกสร้าง / "built" = อัปเกรด-ขาย
var _hero                     # T5: ฮีโร่ Kubi (คลิกขวาสั่งเดิน)
var _spots_layer: SpotsOverlay  # T5.1: ชั้นวาดวงทองลานป้อม (z 30 เหนือพื้นหลัง)
var _wave_label: Label        # แถวข้อมูลคลื่นบน HUD (T4)
var _wave_btn: Button         # ปุ่มเรียกคลื่นถัดไปก่อนพร้อมโบนัส (T4)

class SpotsOverlay:
	extends Node2D
	# ฐานหกเหลี่ยมแทนวงทองขนาดใหญ่; เลขเล็กช่วยจับคู่กับปุ่มลัด 1-4
	const PAD_RADIUS := 23.0
	const PAD_EDGE := Color(0.13, 0.10, 0.06, 0.92)
	const PAD_FILL := Color(0.28, 0.34, 0.20, 0.90)
	const PAD_ACCENT := Color(1.0, 0.79, 0.24, 0.95)

	var spots: Array[Vector2] = []
	var busy: Array = []        # ผูกอ้างอิงสดกับ main._towers (ลานที่มีป้อมไม่วาดวง)
	var selected := -1

	func _draw() -> void:
		# จุดเกิดมอน (วงม่วง) + ประตูปราสาท (วงแดงส้ม) — เดิมถูกพื้นหลังบดบังด้วยแล้วแก้ไปด้วยกัน
		draw_circle(Vector2(261, 250), 14.0, Color(0.55, 0.25, 0.80, 0.80))
		draw_circle(Vector2(816, 495), 12.0, Color(1.0, 0.35, 0.15, 0.85))
		for i in range(spots.size()):
			if busy[i] != null:
				continue
			var center := spots[i]
			var vertices := PackedVector2Array()
			for corner in range(6):
				var angle := TAU * float(corner) / 6.0
				vertices.append(center + Vector2.from_angle(angle) * PAD_RADIUS)
			draw_colored_polygon(vertices, PAD_FILL)
			draw_polyline(vertices, PAD_EDGE, 3.0, true)
			draw_arc(center, 14.0, 0.0, TAU, 24, PAD_ACCENT, 1.5, true)
			draw_line(center + Vector2(-5.0, 0.0), center + Vector2(5.0, 0.0), PAD_ACCENT, 3.0, true)
			draw_line(center + Vector2(0.0, -5.0), center + Vector2(0.0, 5.0), PAD_ACCENT, 3.0, true)
			draw_rect(Rect2(center + Vector2(-7.0, -35.0), Vector2(14.0, 14.0)), PAD_EDGE)
			draw_string(ThemeDB.fallback_font, center + Vector2(-4.0, -24.0), str(i + 1),
				HORIZONTAL_ALIGNMENT_CENTER, 8, 11, PAD_ACCENT)
			if i == selected:
				draw_arc(center, PAD_RADIUS + 5.0, 0.0, TAU, 32, PAD_ACCENT, 2.0, true)

func _ready() -> void:
	y_sort_enabled = true  # มอนวาดเรียงตามแนวระดับ (ตัวล่างจอบนตัวบนจอ - แก้ทับซ้อนดูลอย)
	_build_lives_label()
	# ฮีโร่ Kubi (T5): เกิดตรงประตูปราสาท (ฟีดแบ็ค T5.1) — ยืนตรงนี้ก็ฟาดมอนท้ายเข้าปราสาทให้เห็นตัวต่อ คลิกขวาสั่งเดินได้
	_hero = HeroScript.new()
	_hero.position = Vector2(816, 470)   # ประตูปราสาท (จุดฟื้น = จุดเกิด)
	add_child(_hero)
	# ชั้นวาดวงทอง (T5.1 fix): ประกาศใน SpotsOverlay การันตีวาดเหนือพื้นหลัง (สาเหตุรายแก้ไม่จบ: วงถูก Background ทับ)
	_spots_layer = SpotsOverlay.new()
	_spots_layer.z_index = 30
	_spots_layer.spots = TOWER_SPOTS
	_spots_layer.busy = _towers   # อ้างอิงสด — สร้างป้อมที่ลานไหน วงลานนั้นเงียบ
	add_child(_spots_layer)
	queue_redraw()

func _process(delta: float) -> void:
	if _spots_layer:
		_spots_layer.queue_redraw()   # วงทองลานป้อมเต้นกระพริบทุกเฟรม (T5.1)
	# ตัวรันคลื่น (T4): prep = นับถอยหลังโชว์ปุ่มเรียกก่อน ; wave = เกิดตามคิวกันฉาวจนจบ
	if _state == "prep":
		_prep_t -= delta
		if _prep_t <= 0.0:
			_start_wave()
	elif _state == "wave":
		_gap_t -= delta
		while _queue.size() > 0 and _gap_t <= 0.0:
			if _spawn_point_clear():
				_spawn_kind(_queue.pop_front())
				_gap_t += SPD_GAP
			else:
				_gap_t = 0.45   # ปากประตูแน่น: เลื่อนเกิดไปก่อน 0.45 วิ
				break
		if _queue.size() == 0 and not _enemies_alive():
			_wave_cleared()
	if _state == "prep" or _state == "wave":
		_update_wave_hud()

func _enemies_alive() -> bool:
	for e in get_tree().get_nodes_in_group("enemies"):
		if e is Node2D and not e.dead:
			return true
	return false

func _remaining() -> int:
	var n := _queue.size()
	for e in get_tree().get_nodes_in_group("enemies"):
		if e is Node2D and not e.dead:
			n += 1
	return n

func _start_wave() -> void:
	_wave_idx += 1
	_state = "wave"
	_queue.clear()
	for entry in WAVES[_wave_idx]:
		for _i in range(int(entry[1])):
			_queue.append(entry[0])
	_gap_t = 0.6
	_wave_announce(_wave_idx + 1)
	queue_redraw()

func _spawn_kind(kind: String) -> void:
	# เส้นทางเลื่อนข้างสลับ ซ้าย/ขวา/กลาง + สุ่มความเร็วบาง ๆ (งานเดิม) เพิ่มเลือดโตตามคลื่น
	var lanes := [-LANE_OFFSET, LANE_OFFSET, 0.0]
	var lane: float = lanes[_spawn_seq % 3]
	_spawn_seq += 1
	var jitter := randf_range(0.94, 1.06)
	var hp_mult := pow(HP_GROWTH, _wave_idx)
	if kind == "frog":
		_spawn_enemy(FROG_TEX, FROG_SHEET, _shift_path(PATH_A, lane), FROG_SPEED * jitter, true, false, 59, null, 43, 26.0 * hp_mult, 15)
	elif kind == "lizard":
		# กิ้งก่า: ชุดหันข้าง 8 ช่องหัวหันขวาโดยกำเนิด (ฟีดแบ็ค T5.1: เดินขวาต้องเห็นหัวหันขวาจริง ไม่ใช่รูปหน้าตรงส่ายหัว)
		_spawn_enemy(LIZARD_TEX, LIZARD_SHEET, _shift_path(PATH_A, lane), LIZARD_SPEED * jitter, true, false, 56, LIZARD_SIDE_SHEET, 43, 42.0 * hp_mult, 25)
	elif kind == "stone_golem":
		_spawn_enemy(GOLEM_TEX, null, _shift_path(PATH_A, lane), GOLEM_SPEED * jitter, true, false,
			59, null, 43, GOLEM_HP * hp_mult, 35, GOLEM_RESIST, 1.7)
	else:
		push_error("Unknown enemy type: %s" % kind)

func _spawn_point_clear() -> bool:
	# เว้นระยะเกิด: มอนหรือศพจางยังจอดปากประตู (< 80px) = ยังไม่เกิด
	var gate := PATH_A[0]
	for child in get_children():
		if child is Node2D:
			var v: Node2D = child
			if v.position.distance_to(gate) < 80.0 and v.get_script() == EnemyScript:
				return false
	return true

func _wave_cleared() -> void:
	if _state != "wave":
		return
	var bonus := WAVE_BONUS_BASE + (_wave_idx + 1) * WAVE_BONUS_STEP
	_gold += bonus
	_update_gold()
	_gold_popup(bonus, Vector2(816, 460))
	if _wave_idx >= WAVES.size() - 1:
		_game_over(true)
	else:
		_state = "prep"
		_prep_t = WAVE_PREP
	queue_redraw()

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

func _spawn_enemy(texture: Texture2D, sheet: Texture2D, path: Array[Vector2], speed: float, no_flip: bool, faces_left: bool, bottom_row: int, s_sheet: Texture2D = null, s_bottom: int = 43, hp: float = 26.0, gold: int = 15, resist: float = 0.0, enemy_scale: float = 1.5) -> void:
	var e := EnemyScript.new()
	e.sheet = sheet          # เฟรมเดินจริงถ้ามี sheet (fallback texture นิ่ง)
	e.texture = texture
	e.waypoints = PackedVector2Array(path)
	e.speed = speed
	e.damage_resist = resist
	e.base_scale = enemy_scale
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
	if _lives_label:
		_lives_label.modulate = Color(1.0, 0.4, 0.25)
		var t := _lives_label.create_tween()
		t.tween_property(_lives_label, "modulate", Color.WHITE, 0.4)
	queue_redraw()
	if _lives <= 0:
		_game_over(false)

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

# ---------- ระบบคลื่น + จบเกม (T4) ----------
func _wave_text(idx: int) -> String:
	# แต้มคลื่นอ่านง่าย: "กบ 4, กิ้งก่า 3"
	var names := {"frog": "กบ", "lizard": "กิ้งก่า", "stone_golem": "โกเลมหิน"}
	var parts: Array = []
	for entry in WAVES[idx]:
		parts.append("%s %d" % [names[entry[0]], entry[1]])
	return ", ".join(parts)

func _update_wave_hud() -> void:
	if _wave_label:
		if _state == "wave":
			_wave_label.text = "คลื่น %d/%d · เหลือมอน %d" % [_wave_idx + 1, WAVES.size(), _remaining()]
		else:
			var nxt := _wave_idx + 1
			if nxt < WAVES.size():
				_wave_label.text = "คลื่นถัดไป %d/%d · %s" % [nxt + 1, WAVES.size(), _wave_text(nxt)]
	if _wave_btn:
		if _state == "prep":
			_wave_btn.disabled = false
			var bonus := int(ceil(_prep_t * EARLY_BONUS_PER_SEC))
			_wave_btn.text = "เรียกคลื่น %d (%d วิ) +โบนัส %d" % [_wave_idx + 2, int(ceil(_prep_t)), bonus]
		elif _state == "wave":
			_wave_btn.disabled = true
			_wave_btn.text = "คลื่น %d กำลังบุก..." % [_wave_idx + 1]
		else:
			_wave_btn.visible = false

func _on_wave_btn() -> void:
	# เรียกคลื่นถัดไปก่อน: ได้โบนัส = วินาทีที่ยังเหลือ × อัตรา (ตัดสินใจเสี่ยงรับเงินก่อน)
	if _state != "prep":
		return
	var bonus := int(ceil(_prep_t * EARLY_BONUS_PER_SEC))
	if bonus > 0:
		_gold += bonus
		_update_gold()
		_gold_popup(bonus, Vector2(930, 96))
	_start_wave()

func _wave_announce(n: int) -> void:
	# ป้ายชื่อคลื่นกลางจอ จางหายหลังโชว์เภูมิมอนกลุ่มใหม่ (HUD ยังไม่พร้อม = ข้ามเงียบ)
	if _hud == null:
		return
	var lb := Label.new()
	var st := LabelSettings.new()
	st.font_size = 38
	st.font_color = Color(1.0, 0.85, 0.2)
	st.outline_size = 10
	st.outline_color = Color(0.15, 0.09, 0.02)
	lb.label_settings = st
	lb.text = "คลื่นที่ %d" % n
	lb.set_anchors_preset(Control.PRESET_TOP_WIDE)
	lb.offset_top = 150.0
	lb.offset_bottom = 210.0
	lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hud.add_child(lb)
	var t := lb.create_tween()
	t.set_parallel(true)
	t.tween_property(lb, "modulate:a", 0.0, 1.2).set_delay(0.6)
	t.tween_property(lb, "position:y", lb.position.y - 22.0, 1.8)
	t.chain().tween_callback(lb.queue_free)

func _game_over(won: bool) -> void:
	# จบเกม: ป้ายกลางจอ + หยุดโลก + ปุ่มเริ่มใหม่ (คีย์ R ทำงานผ่าน Layer ที่นางจอทำงานต่อแม้ paused)
	if _state == "won" or _state == "lost":
		return
	_state = "won" if won else "lost"
	get_tree().paused = true   # หยุดโลกทันที (มอน/ป้อม/เกิด) — เลเยอร์จอจบเกมตั้ง ALWAYS ทำงานต่อ
	_close_menu()
	if _wave_btn:
		_wave_btn.visible = false
	queue_redraw()
	var layer := CanvasLayer.new()
	layer.layer = 20
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	var dim := ColorRect.new()
	dim.color = Color(0.06, 0.04, 0.02, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	center.add_child(box)
	var title := Label.new()
	title.text = "ชนะ! ปราสาทคงยืนยง" if won else "แพ้... ปราสาทแตก"
	var ts := LabelSettings.new()
	ts.font_size = 48
	ts.font_color = Color(1.0, 0.85, 0.2) if won else Color(1.0, 0.4, 0.3)
	ts.outline_size = 12
	ts.outline_color = Color(0.15, 0.09, 0.02)
	title.label_settings = ts
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var sub := Label.new()
	var ss := LabelSettings.new()
	ss.font_size = 20
	ss.font_color = Color(0.95, 0.93, 0.9)
	ss.outline_size = 7
	ss.outline_color = Color(0.1, 0.07, 0.04)
	sub.label_settings = ss
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if won:
		sub.text = "รอดครบ %d/%d คลื่น · ชีวิตคงเหลือ %d" % [WAVES.size(), WAVES.size(), _lives]
	else:
		sub.text = "ปราสาทแตกที่คลื่นที่ %d" % mini(_wave_idx + 1, WAVES.size())
	box.add_child(sub)
	var btn := Button.new()
	btn.text = "เริ่มใหม่ (R)"
	btn.custom_minimum_size = Vector2(190, 46)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.focus_mode = Control.FOCUS_NONE
	var sc := Shortcut.new()
	var ev := InputEventKey.new()
	ev.keycode = KEY_R
	sc.events = [ev]
	btn.shortcut = sc
	btn.pressed.connect(_restart)
	box.add_child(btn)
	if _hud:
		_hud.add_child(layer)

func _restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

# ---------- เมนูสร้างป้อม (T3) ----------
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		# ฮีโร่ (T5): คลิกขวาบนพื้น = สั่ง Kubi เดินไปหมุดนั้น
		if _hero != null and not _hero._dead:
			_hero.move_to(get_global_mouse_position())
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# NB: พิกัดคลิกมี 2 ระบบขึ้นกับ DPI - จอ 125% ย่อหน้าต่างจริงเป็น 921x518
		# เช็คทั้งพิกัดโลก, event.position ดิบ (หน้าต่าง=สเกลเดียว), และ event.position ยืดตามสเกลหน้าต่าง
		var candidates: Array[Vector2] = [event.position]
		if is_inside_tree():
			candidates.insert(0, get_global_mouse_position())
		var win := get_window()
		var wsize := Vector2(win.size) if win != null else Vector2.ZERO
		if wsize.x > 100.0 and wsize.y > 100.0 and (wsize.x < 1100.0 or wsize.y < 600.0):
			candidates.append(event.position * Vector2(1152.0, 648.0) / wsize)
		var hit := -1
		for p in candidates:
			for i in range(TOWER_SPOTS.size()):
				# T5: ลานที่มีป้อมแล้วก็คลิกได้ -> เมนูอัปเกรด/ขาย (เดิมกรองเฉพาะลานว่าง)
				if p.distance_to(TOWER_SPOTS[i]) <= SPOT_HIT_R:
					hit = i
					break
			if hit >= 0:
				break
		if hit >= 0:
			print("OPEN_MENU spot=", hit, " p=", candidates[0])  # DEBUG (console)
			_open_menu(hit)
		elif _menu != null:
			_close_menu()
	elif event is InputEventKey and event.pressed and not event.echo:
		# ทางลัดคีย์บอร์ด (ปลอดภัยกับ DPI เสมอ): 1-4 เปิดลาน, 1/2/3 เลือกป้อม, Esc/X ปิด
		var code: int = event.keycode
		if _state == "prep" and code == KEY_N:
			# ทางลัดเรียกคลื่นก่อน = เหมือนกดปุ่มมุมขวาบน (ได้โบนัสตามวินาทีคงเหลือ)
			_on_wave_btn()
		elif _menu == null:
			if code >= KEY_1 and code <= KEY_4:
				var idx := code - KEY_1
				print("OPEN_MENU spot=", idx, " (key)")  # DEBUG (console)
				_open_menu(idx)
		else:
			if _menu_mode == "build":
				if code == KEY_1:
					_build_tower(_menu_spot, "archer")
				elif code == KEY_2:
					_build_tower(_menu_spot, "cannon")
				elif code == KEY_3:
					_build_tower(_menu_spot, "mage")
			elif _menu_mode == "built":
				if code == KEY_1 and _menu_spot >= 0 and _towers[_menu_spot] != null and _lvl[_menu_spot] < 2:
					_upgrade_tower(_menu_spot)
				elif code == KEY_2:
					_sell_tower(_menu_spot)
			if code == KEY_ESCAPE or code == KEY_X:
				_close_menu()
	elif event.is_action_pressed("ui_cancel") and _menu != null:
		_close_menu()

func _open_menu(spot_idx: int) -> void:
	_close_menu()
	_menu_spot = spot_idx
	# T5: เมนู 2 โหมด - ลานว่าง = สร้างป้อม / ลานที่มีป้อม = อัปเกรด + ขาย
	_menu_mode = "build" if _towers[spot_idx] == null else "built"
	if _spots_layer:
		_spots_layer.selected = spot_idx
		_spots_layer.queue_redraw()
	if _menu_mode == "built":
		var selected_tower: Node2D = _towers[spot_idx]
		selected_tower.show_range = true
		selected_tower.queue_redraw()
	var panel := PanelContainer.new()
	var menu_width := 316.0 if _menu_mode == "build" else 218.0
	panel.custom_minimum_size.x = menu_width
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 6)
	panel.add_child(layout)
	var heading := Label.new()
	heading.text = "สร้างป้อม · ลาน %d" % [spot_idx + 1] if _menu_mode == "build" else "จัดการป้อม · ลาน %d" % [spot_idx + 1]
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var heading_style := LabelSettings.new()
	heading_style.font_size = 14
	heading_style.font_color = Color(1.0, 0.85, 0.45)
	heading_style.outline_size = 4
	heading_style.outline_color = Color(0.08, 0.06, 0.03)
	heading.label_settings = heading_style
	layout.add_child(heading)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_child(hb)
	if _menu_mode == "build":
		var option_number := 1
		for key in ["archer", "cannon", "mage"]:
			var def: Dictionary = TOWER_DEFS[key]
			var tip: String = "%s (รัศมี %d, ดาเมจ %.0f)" % [def["name"], def["range"], def["dmg"]]
			_menu_entry(hb, def["icon"], "%d %s" % [option_number, def["name"]], int(def["cost"]), tip, _build_tower.bind(spot_idx, key))
			option_number += 1
	else:
		var t: Node2D = _towers[spot_idx]
		var def: Dictionary = TOWER_DEFS[_tower_def_key(t)]
		if _lvl[spot_idx] < 2:
			# อัปเกรด Lv2: ไอคอนประจำป้อม + ราคาต่ำงาน
			var upg: Dictionary = def["upg"]
			var tip2: String = "อัปเกรด %s Lv2 (ดาเมจ %.0f, รัศมี %d)" % [def["name"], upg["dmg"], upg["range"]]
			_menu_entry(hb, def["upg_icon"], "1 อัปเกรด", int(def["upg_cost"]), tip2, _upgrade_tower.bind(spot_idx))
		# ขายคืน 60% ของเงินที่ลงไป (ไอคอนเหรียญ Kubi เดิม)
		var refund := _refund(spot_idx)
		_menu_entry(hb, ICON_COIN, "2 ขายคืน", refund, "ขายคืน 60%% ของเงินที่ลงไป (%d)" % refund, _sell_tower.bind(spot_idx))
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.07, 0.03, 0.9)
	style.set_corner_radius_all(8)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	panel.add_theme_stylebox_override("panel", style)
	panel.position = TOWER_SPOTS[spot_idx] + Vector2(-100, -78)
	panel.position.x = clampf(panel.position.x, 8.0, 1152.0 - menu_width - 8.0)
	panel.position.y = clampf(panel.position.y, 8.0, 648.0 - 178.0)
	panel.z_index = 100   # T5.1: เมนูต้องลอยเหนือตัวป้อม (เดิม y-sort ดันเมนูไปหลังป้อม = อ่านไม่รู้เรื่อง)
	_menu = panel
	add_child(panel)

func _menu_entry(hb: HBoxContainer, icon: Texture2D, title: String, price: int, tip: String, pressed: Callable) -> void:
	# แสดงชื่อและราคาใต้ไอคอน เพื่อให้รู้ว่ากำลังกดซื้อหรือจัดการอะไร
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 2)
	var btn := TextureButton.new()
	btn.texture_normal = icon
	btn.custom_minimum_size = Vector2(56, 56)
	btn.ignore_texture_size = true
	btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	btn.tooltip_text = tip
	btn.pressed.connect(pressed)
	col.add_child(btn)
	var name_label := Label.new()
	name_label.text = title
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", Color(0.96, 0.94, 0.87))
	name_label.custom_minimum_size.x = 92.0
	col.add_child(name_label)
	var cost := Label.new()
	cost.text = "%d" % price
	cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var cst := LabelSettings.new()
	cst.font_size = 15
	cst.font_color = Color(1.0, 0.35, 0.25) if price > _gold else Color(1.0, 0.85, 0.2)
	cst.outline_size = 5
	cst.outline_color = Color(0.15, 0.09, 0.02)
	cost.label_settings = cst
	col.add_child(cost)
	hb.add_child(col)

func _close_menu() -> void:
	if _menu != null:
		_menu.queue_free()
		_menu = null
	if _menu_spot >= 0 and _menu_spot < _towers.size() and _towers[_menu_spot] != null:
		var selected_tower: Node2D = _towers[_menu_spot]
		selected_tower.show_range = false
		selected_tower.queue_redraw()
	if _spots_layer:
		_spots_layer.selected = -1
		_spots_layer.queue_redraw()
	_menu_spot = -1
	_menu_mode = ""

func _tower_def_key(t: Node2D) -> String:
	# T5: หาแถว def ของป้อมต่อลาน (จาก kind) สำหรับอัปเกรด/ขาย
	for key in TOWER_DEFS:
		if t.kind == int(TOWER_DEFS[key]["kind"]):
			return key
	return "archer"

func _refund(spot_idx: int) -> int:
	return int(round(float(_inv[spot_idx]) * SELL_REFUND))

func _build_tower(spot_idx: int, key: String) -> void:
	if spot_idx < 0 or _towers[spot_idx] != null:
		return
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
	# T5: จำสถานะต่อลาน (node / เลเวล / เงินที่ลงไป ใช้คิดคืนขาย)
	_towers[spot_idx] = t
	_lvl[spot_idx] = 1
	_inv[spot_idx] = int(def["cost"])
	_close_menu()
	queue_redraw()

func _upgrade_tower(spot_idx: int) -> void:
	var t: Node2D = _towers[spot_idx]
	if t == null or _lvl[spot_idx] >= 2:
		return
	var def: Dictionary = TOWER_DEFS[_tower_def_key(t)]
	var upg: Dictionary = def["upg"]
	var cost := int(def["upg_cost"])
	if _gold < cost:
		_flash_gold()
		return
	_gold -= cost
	_inv[spot_idx] += cost
	_update_gold()
	t.apply_upgrade(float(upg["dmg"]), float(upg["interval"]), float(upg["range"]), float(upg["shot"]), float(upg["splash"]))
	_lvl[spot_idx] = 2
	_close_menu()
	queue_redraw()

func _sell_tower(spot_idx: int) -> void:
	var t: Node2D = _towers[spot_idx]
	if t == null:
		return
	var refund := _refund(spot_idx)
	_gold += refund
	_update_gold()
	_gold_popup(refund, TOWER_SPOTS[spot_idx])
	t.queue_free()
	_towers[spot_idx] = null
	_lvl[spot_idx] = 0
	_inv[spot_idx] = 0
	_close_menu()
	queue_redraw()

func _update_lives() -> void:
	if _lives_label:
		_lives_label.text = "ชีวิต: %d" % _lives

func _build_lives_label() -> void:
	_hud = CanvasLayer.new()
	_hud.layer = 10
	add_child(_hud)
	# แถวชีวิต (T4.1): ไอคอนหัวใจ + ตัวเลข
	var heart := TextureRect.new()
	heart.texture = ICON_HEART
	heart.custom_minimum_size = Vector2(26, 26)
	heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	heart.position = Vector2(16, 12)
	_hud.add_child(heart)
	_lives_label = Label.new()
	var ls := LabelSettings.new()
	ls.font_size = 22
	ls.font_color = Color(1.0, 0.79, 0.24)
	ls.outline_size = 6
	ls.outline_color = Color(0.16, 0.09, 0.03)
	_lives_label.label_settings = ls
	_lives_label.position = Vector2(48, 12)
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
	# แถวข้อมูลคลื่น (T4): ใต้แถวชีวิต/ทอง (ข้อความวิธีเล่นล่างซ้ายถูกตัดออกตามฟีดแบ็ค T4.1)
	_wave_label = Label.new()
	var ws := LabelSettings.new()
	ws.font_size = 16
	ws.font_color = Color(0.92, 0.92, 0.95)
	ws.outline_size = 5
	ws.outline_color = Color(0.08, 0.06, 0.05)
	_wave_label.label_settings = ws
	_wave_label.position = Vector2(16, 80)
	_hud.add_child(_wave_label)
	var controls := Label.new()
	controls.text = "ฐาน +: เลือกสร้างป้อม · คลิกขวา: สั่ง Kubi · 1-4: เลือกฐาน"
	controls.add_theme_font_size_override("font_size", 13)
	controls.add_theme_color_override("font_color", Color(0.95, 0.93, 0.86))
	controls.add_theme_color_override("font_shadow_color", Color(0.08, 0.06, 0.04, 0.95))
	controls.add_theme_constant_override("shadow_offset_x", 1)
	controls.add_theme_constant_override("shadow_offset_y", 1)
	controls.position = Vector2(16, 108)
	_hud.add_child(controls)
	# ปุ่มเรียกคลื่นถัดไปก่อนพร้อมโบนัส (มุมขวาบน - T4)
	_wave_btn = Button.new()
	_wave_btn.text = "เรียกคลื่น 1"
	_wave_btn.pressed.connect(_on_wave_btn)
	_wave_btn.focus_mode = Control.FOCUS_NONE
	_wave_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_wave_btn.offset_left = -270.0
	_wave_btn.offset_right = -8.0
	_wave_btn.offset_top = 8.0
	_wave_btn.offset_bottom = 42.0
	_hud.add_child(_wave_btn)
	_update_wave_hud()
