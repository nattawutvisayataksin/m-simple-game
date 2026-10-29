extends Node2D
# หอคอยคู่ฟ้า (Kub Kingdom Rush) - ฉากหลัก
# โลก 1152x1296 (จอ 1152x648 เลื่อนดูแนวตั้งแบบ Kingdom Rush)
# T2: มอนเดินตาม waypoint จาก 2 ประตู + นับชีวิตเมื่อถึงปราสาท

const EnemyScript := preload("res://scripts/enemy.gd")
const FROG_TEX := preload("res://assets/art/gen/frog.png")
const LIZARD_TEX := preload("res://assets/art/gen/lizard.png")
const FROG_SHEET := preload("res://assets/art/gen/frog_sheet.png")
const LIZARD_SHEET := preload("res://assets/art/gen/lizard_sheet.png")

# โครงโลก (world coords, ไม่ได้ map ตามจอ): master แผงบน y 0-648, แผงทุ่งหญ้า y 648-1296
# ปราสาท: ประตูทองที่ (816, 495) ; ประตูม่วงบน (261, 240) ; ประตูม่วงล่าง ชิดขอบล่าง (843, 1290)

# เส้น A: ประตูม่วงบน -> ลงถนน -> เลี้ยวขวาเป็นเส้น U -> ประตูปราสาท
const PATH_A: Array[Vector2] = [
	Vector2(261, 260),
	Vector2(261, 420),
	Vector2(285, 500),
	Vector2(340, 540),
	Vector2(430, 548),
	Vector2(560, 545),
	Vector2(700, 545),
	Vector2(780, 540),
	Vector2(816, 500),
]

# เส้น C: ประตูม่วงล่าง (ชิดขอบล่างแผงใหม่) -> ถนนแนวตั้งขึ้นยาว -> ประตูปราสาท
const PATH_C: Array[Vector2] = [
	Vector2(843, 1290),
	Vector2(843, 1150),
	Vector2(843, 980),
	Vector2(843, 820),
	Vector2(840, 660),
	Vector2(830, 580),
	Vector2(816, 500),
]

# ลานจุดวางป้อม 5 จุด (หญ้าว่างการันตีจากการตามภาพ)
const TOWER_SPOTS: Array[Vector2] = [
	Vector2(110, 380),   # 1 ทุ่งซ้ายของถนนลงประตูบน
	Vector2(420, 615),   # 2 โค้งเลี้ยวขวา (เหนือแผงล่าง)
	Vector2(620, 350),   # 3 เหนือถนนแนวนอน
	Vector2(700, 620),   # 4 ใต้ถนนแนวนอนใกล้ปราสาท
	Vector2(950, 1150),  # 5 แผงล่าง งอกข้างถนนล่าง
]

const SPOT_FILL := Color(1.0, 0.79, 0.24, 0.55)
const SPOT_EDGE := Color(0.16, 0.09, 0.03, 0.9)
const GATE_COLOR := Color(0.55, 0.25, 0.80, 0.80)
const CASTLE_COLOR := Color(1.0, 0.35, 0.15, 0.85)

const SPAWN_INTERVAL := 2.2
const FROG_SPEED := 35.0
const LIZARD_SPEED := 60.0
const START_LIVES := 20

# กล้อง: เลื่อนแนวตั้งคู่จอ
const VIEW_H := 648.0
const WORLD_H := 1296.0

var _spawn_timer := 0.0
var _spawn_seq := 0
var _lives := START_LIVES
var _lives_label: Label
var _hud: CanvasLayer
var _camera: Camera2D
var _drag_cam := false

func _ready() -> void:
	_build_lives_label()
	_build_camera()
	queue_redraw()

func _build_camera() -> void:
	_camera = Camera2D.new()
	_camera.limit_left = 0
	_camera.limit_top = 0
	_camera.limit_right = 1152
	_camera.limit_bottom = 1296
	_camera.position = Vector2(576, VIEW_H / 2.0)  # เริ่มมองโซนปราสาท (บน)
	add_child(_camera)
	_camera.make_current()

func _unhandled_input(event: InputEvent) -> void:
	# ลากจอด้วยเมาส์ (ปุ่มซ้ายค้าง) + ปุ่มลูกศร/PageUp-Down
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_drag_cam = event.pressed
	elif event is InputEventMouseMotion and _drag_cam:
		_camera.position.y = clampf(_camera.position.y - event.relative.y * (WORLD_H / VIEW_H) * 0.6, VIEW_H / 2.0, WORLD_H - VIEW_H / 2.0)
	elif event is InputEventKey and event.pressed:
		var step := 24.0
		if event.keycode == KEY_UP:
			_camera.position.y = clampf(_camera.position.y - step, VIEW_H / 2.0, WORLD_H - VIEW_H / 2.0)
		elif event.keycode == KEY_DOWN:
			_camera.position.y = clampf(_camera.position.y + step, VIEW_H / 2.0, WORLD_H - VIEW_H / 2.0)

func _process(delta: float) -> void:
	_spawn_timer += delta
	if _spawn_timer >= SPAWN_INTERVAL:
		_spawn_timer = 0.0
		_spawn_next()

func _spawn_next() -> void:
	# สลับประตูและชนิดเป็นคู่วน: กบจากบน/กบจากล่าง/กิ้งก่าบน/กิ้งก่าล่าง
	var from_bottom := (_spawn_seq % 2) == 1
	var kind := (_spawn_seq % 4) < 2
	_spawn_seq += 1
	var path: Array[Vector2] = PATH_C if from_bottom else PATH_A
	if kind:
		_spawn_enemy(FROG_TEX, FROG_SHEET, path, FROG_SPEED, true, false)    # กบ: sheet หน้าตรง ไม่กลับหัว
	else:
		_spawn_enemy(LIZARD_TEX, LIZARD_SHEET, path, LIZARD_SPEED, false, true)  # กิ้งก่า: หันข้าง native ซ้าย

func _spawn_enemy(texture: Texture2D, sheet: Texture2D, path: Array[Vector2], speed: float, no_flip: bool, faces_left: bool) -> void:
	var e := EnemyScript.new()
	e.sheet = sheet          # ใช้เฟรมเดินจริงถ้ามี sheet (fallback = texture นิ่ง)
	e.texture = texture
	e.waypoints = PackedVector2Array(path)
	e.speed = speed
	e.no_flip = no_flip
	e.faces_left = faces_left
	add_child(e)
	e.reached_castle.connect(_on_enemy_leak)

func _on_enemy_leak() -> void:
	_lives -= 1
	_update_lives()
	# จุดหมายคือประตูปราสาท: วาดวงแดงกระพริบบอกว่าเสียชีวิต
	queue_redraw()

func _update_lives() -> void:
	if _lives_label:
		_lives_label.text = "ชีวิต: %d" % _lives

# ---------- ภาพแต่งบนฉาก (overlay การออกแบบ) ----------
func _draw() -> void:
	# จุดเกิดมอนสเตอร์: วงม่วงที่ปากประตู (สองประตู)
	draw_circle(Vector2(261, 250), 14.0, GATE_COLOR)
	draw_circle(Vector2(843, 1286), 14.0, GATE_COLOR)
	# จุดหมาย (ประตูปราสาท): วงส้มแดง
	draw_circle(Vector2(816, 500), 12.0, CASTLE_COLOR)
	# ลานจุดวางป้อม 5 จุด: วงทอง + ขอบเข้ม
	for spot in TOWER_SPOTS:
		draw_circle(spot, 26.0, SPOT_FILL)
		draw_arc(spot, 26.0, 0.0, TAU, 32, SPOT_EDGE, 2.0, true)

func _build_lives_label() -> void:
	if not _hud:
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
