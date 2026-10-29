extends Node2D
# หอคอยคู่ฟ้า (Kub Kingdom Rush) - ฉากหลัก
# T2: มอนสเตอร์เดินตาม waypoint จาก 3 จุดเกิด + นับชีวิตเมื่อ leak
# พร้อม overlay ออกแบบ: ลานจุดวางป้อม 5 วงทอง (จาก T1 mockup ที่อนุมัติแล้ว)

const EnemyScript := preload("res://scripts/enemy.gd")
const FROG_TEX := preload("res://assets/art/gen/frog.png")
const LIZARD_TEX := preload("res://assets/art/gen/lizard.png")

# จากภาพ kub_kingdom_map.png (1152x648) โครงถนนจริง:
#  - ประตูม่วงซ้ายบน (230,60) ถนนแนวตั้งลงยาว
#  - จุดตัด T ที่ y~350 แยกซ้าย-ล่าง และแนวนอนเข้ากำแพงปราสาท (650,350)
#  - ถนนล่างซ้ายออกขอบล่าง (300,648)
#  - บันไดปราสาทขวาล่าง ถนนขึ้นสั้นจากขอบล่าง (855,648) -> บันไดที่ (855,500)

# เส้นหลัก: ประตูม่วง -> จุดตัด -> กำแพงปราสาท (จุดหมาย)
const PATH_MAIN: Array[Vector2] = [
	Vector2(230, 70),
	Vector2(230, 200),
	Vector2(232, 340),
	Vector2(400, 350),
	Vector2(560, 352),
	Vector2(650, 352),
]
# เส้นใต้: ขอบล่างซ้าย -> ขึ้นจุดตัด แล้วต่อแนวนอนเข้าปราสาท
const PATH_SOUTH_LEFT: Array[Vector2] = [
	Vector2(300, 668),
	Vector2(300, 500),
	Vector2(280, 400),
]
# เส้นใต้ขวา: ขอบล่าง -> บันไดปราสาท (ทางสั้น ต้องมีป้อมคุ้ม)
const PATH_SOUTH_RIGHT: Array[Vector2] = [
	Vector2(855, 668),
	Vector2(855, 560),
	Vector2(855, 500),
]

# ลานจุดวางป้อม 5 จุด (หญ้าว่างจริงบนภาพ ครอบคลุมทุกเส้นทาง)
const TOWER_SPOTS: Array[Vector2] = [
	Vector2(150, 195),
	Vector2(385, 245),
	Vector2(165, 430),
	Vector2(520, 452),
	Vector2(955, 570),
]

const SPOT_FILL := Color(1.0, 0.79, 0.24, 0.55)
const SPOT_EDGE := Color(0.16, 0.09, 0.03, 0.9)
const GATE_COLOR := Color(0.55, 0.25, 0.80, 0.80)
const CASTLE_COLOR := Color(1.0, 0.35, 0.15, 0.85)

const SPAWN_INTERVAL := 1.6
const FROG_SPEED := 60.0
const LIZARD_SPEED := 110.0
const START_LIVES := 20

var _spawn_timer := 0.0
var _spawn_seq := 0
var _lives := START_LIVES
var _lives_label: Label

func _ready() -> void:
	_build_lives_label()
	queue_redraw()

func _process(delta: float) -> void:
	_spawn_timer += delta
	if _spawn_timer >= SPAWN_INTERVAL:
		_spawn_timer = 0.0
		_spawn_next()

# เส้น B แบบเต็ม: ขอบล่างซ้าย -> จุดตัด -> แนวนอนถึงกำแพงปราสาท
const PATH_B_FULL: Array[Vector2] = [
	Vector2(300, 668),
	Vector2(300, 500),
	Vector2(280, 400),
	Vector2(400, 350),
	Vector2(560, 352),
	Vector2(650, 352),
]

func _spawn_next() -> void:
	# สลับชนิด/จุดเกิด วนลูปเพื่อดูทั้งระบบเดินจริง (จูนความยากหลัง T4)
	var route := _spawn_seq % 3
	var kind := (_spawn_seq / 3) % 2
	_spawn_seq += 1
	var path: Array[Vector2]
	match route:
		0:
			path = PATH_MAIN
		1:
			path = PATH_B_FULL
		_:
			path = PATH_SOUTH_RIGHT
	if kind == 0:
		_spawn_enemy(FROG_TEX, path, FROG_SPEED)
	else:
		_spawn_enemy(LIZARD_TEX, path, LIZARD_SPEED)

func _spawn_enemy(texture: Texture2D, path: Array[Vector2], speed: float) -> void:
	var e := EnemyScript.new()
	e.texture = texture
	e.waypoints = PackedVector2Array(path)
	e.speed = speed
	add_child(e)
	e.reached_castle.connect(_on_enemy_leak)

func _on_enemy_leak() -> void:
	_lives -= 1
	_update_lives()
	# จุดหมายถึงปราสาท: กระพริบวงแดงรอบปราสาท (แจ้งผู้เล่นว่าเสียชีวิต)
	queue_redraw()

func _update_lives() -> void:
	if _lives_label:
		_lives_label.text = "ชีวิต: %d" % _lives

# ---------- ภาพแต่งบนฉาก (overlay การออกแบบ) ----------
func _draw() -> void:
	# จุดเกิดมอนสเตอร์: วงม่วง 3 จุด
	draw_circle(Vector2(230, 70), 14.0, GATE_COLOR)
	draw_circle(Vector2(300, 648), 14.0, GATE_COLOR)
	draw_circle(Vector2(855, 648), 14.0, GATE_COLOR)
	# จุดหมาย (กำแพงปราสาท + บันได): วงส้มแดง
	draw_circle(Vector2(650, 352), 12.0, CASTLE_COLOR)
	draw_circle(Vector2(855, 500), 12.0, CASTLE_COLOR)
	# ลานจุดวางป้อม: วงทอง + ขอบเข้ม
	for spot in TOWER_SPOTS:
		draw_circle(spot, 26.0, SPOT_FILL)
		draw_arc(spot, 26.0, 0.0, TAU, 32, SPOT_EDGE, 2.0, true)

func _build_lives_label() -> void:
	_lives_label = Label.new()
	var ls := LabelSettings.new()
	ls.font_size = 22
	ls.font_color = Color(1.0, 0.79, 0.24)
	ls.outline_size = 6
	ls.outline_color = Color(0.16, 0.09, 0.03)
	_lives_label.label_settings = ls
	_lives_label.position = Vector2(16, 12)
	_lives_label.text = "ชีวิต: %d" % _lives
	add_child(_lives_label)
