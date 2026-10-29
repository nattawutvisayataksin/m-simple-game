extends Node2D
# หอคอยคู่ฟ้า (Kub Kingdom Rush) - ฉากหลัก
# T2.6 (feedback ผู้อำนวยการ): ตัดฉากล่างออก - ฉากเดียว 1152x648, มอนบุกทางเดียว
# จากประตูม่วงบนซ้าย -> ถนนวกลงเลี้ยวขวา -> ประตูปราสาท (ขวาบน)
# แก้เดินซ้อน: มอนแต่ละตัวเลื่อนข้างถนนสลับซ้าย/ขวา ±13px + สุ่มความเร็ว ±8%

const EnemyScript := preload("res://scripts/enemy.gd")
const FROG_TEX := preload("res://assets/art/gen/frog.png")
const LIZARD_TEX := preload("res://assets/art/gen/lizard_front.png")
const FROG_SHEET := preload("res://assets/art/gen/frog_sheet.png")
const LIZARD_SHEET := preload("res://assets/art/gen/lizard_sheet.png")

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
var _lives_label: Label
var _hud: CanvasLayer

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
		_spawn_enemy(FROG_TEX, FROG_SHEET, _shift_path(PATH_A, lane), FROG_SPEED * jitter, true, false, 59)
	else:
		_spawn_enemy(LIZARD_TEX, LIZARD_SHEET, _shift_path(PATH_A, lane), LIZARD_SPEED * jitter, true, false, 56)

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

func _spawn_enemy(texture: Texture2D, sheet: Texture2D, path: Array[Vector2], speed: float, no_flip: bool, faces_left: bool, bottom_row: int) -> void:
	var e := EnemyScript.new()
	e.sheet = sheet          # เฟรมเดินจริงถ้ามี sheet (fallback texture นิ่ง)
	e.texture = texture
	e.waypoints = PackedVector2Array(path)
	e.speed = speed
	e.no_flip = no_flip
	e.faces_left = faces_left
	e.body_bottom_row = bottom_row  # แถวเท้าจริงในเฟรม (กบ 59 / กิ้งก่าเดิม 43)
	add_child(e)
	e.reached_castle.connect(_on_enemy_leak)

func _on_enemy_leak() -> void:
	_lives -= 1
	_update_lives()
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
	# ลานจุดวางป้อม: วงทอง + ขอบเข้ม
	for spot in TOWER_SPOTS:
		draw_circle(spot, 26.0, SPOT_FILL)
		draw_arc(spot, 26.0, 0.0, TAU, 32, SPOT_EDGE, 2.0, true)

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
