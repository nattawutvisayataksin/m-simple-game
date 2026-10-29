extends Node2D
# หอคอยคู่ฟ้า (Kub Kingdom Rush) - ฉากหลัก
# ขั้น mockup: พื้นหลัง + ทางเดิน waypoint จากภาพจริง + จุดวางป้อม

# จากภาพ kub_kingdom_map.png (1152x648) โครงถนนจริง:
#  - ประตูม่วงซ้ายบน (230,60) ถนนแนวตั้งลงยาว
#  - จุดตัด T ที่ y~350 แยกซ้าย-ล่าง และแนวนอนเข้ากำแพงปราสาท (650,350)
#  - ถนนล่างซ้ายออกขอบล่าง (300,648)
#  - บันไดปราสาทขวาล่าง ถนนขึ้นสั้นจากขอบล่าง (855,648) -> บันไดที่ (855,500)

# เส้นหลัก: ประตูม่วง -> จุดตัด -> แนวนอนถึงกำแพงปราสาท (จุดหมาย)
const PATH_MAIN: Array[Vector2] = [
	Vector2(230, 70),    # จุดเกิด A - ประตูม่วง
	Vector2(230, 200),
	Vector2(232, 340),   # เข้าจุดตัด T
	Vector2(400, 350),
	Vector2(560, 352),
	Vector2(650, 352),   # กำแพงปราสาท (จุดหมาย - leak ที่นี่)
]

# เส้นใต้: ขอบล่างซ้าย -> ขึ้นถึงจุดตัด (จุดเกิด B)
const PATH_SOUTH_LEFT: Array[Vector2] = [
	Vector2(300, 668),   # จุดเกิด B - ขอบล่างซ้าย
	Vector2(300, 500),
	Vector2(280, 400),
	Vector2(240, 352),   # เข้าจุดตัด (ต่อ PATH_MAIN ขั้น index 2)
]

# เส้นใต้ขวา: ขอบล่าง -> บันไดปราสาท (จุดเกิด C - ทางสั้นสุด ต้องมีป้อมคุ้ม)
const PATH_SOUTH_RIGHT: Array[Vector2] = [
	Vector2(855, 668),   # จุดเกิด C - ถนนคลุมขอบล่าง
	Vector2(855, 560),
	Vector2(855, 500),   # บันไดปราสาท (จุดหมาย - leak ที่นี่)
]

# ลานจุดวางป้อม 5 จุด (หญ้าว่างจริงบนภาพ ครอบคลุมทุกเส้นทาง)
const TOWER_SPOTS: Array[Vector2] = [
	Vector2(150, 195),   # 1 โค้งประตูม่วง
	Vector2(385, 245),   # 2 แนวนอนบน ยิงเส้นหลักยาว
	Vector2(165, 430),   # 3 สามเหลี่ยมจุดตัดฝั่งซ้าย ยิงทั้งใต้
	Vector2(520, 452),   # 4 ช่วงกลางแนวนอนล่าง
	Vector2(955, 570),   # 5 คลุมบันไดปราสาท (จำเป็น เพราะเส้น C สั้น)
]

const SPOT_FILL := Color(1.0, 0.79, 0.24, 0.55)
const SPOT_EDGE := Color(0.16, 0.09, 0.03, 0.9)
const PATH_COLOR := Color(0.16, 0.09, 0.03, 0.45)
const GATE_COLOR := Color(0.55, 0.25, 0.80, 0.80)
const CASTLE_COLOR := Color(1.0, 0.35, 0.15, 0.85)

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	# ถนนมอนสเตอร์
	draw_polyline(PackedVector2Array(PATH_MAIN), PATH_COLOR, 3.0, true)
	draw_polyline(PackedVector2Array(PATH_SOUTH_LEFT), PATH_COLOR, 3.0, true)
	draw_polyline(PackedVector2Array(PATH_SOUTH_RIGHT), PATH_COLOR, 3.0, true)
	# จุดเกิดมอนสเตอร์: วงม่วง 3 จุด
	draw_circle(Vector2(230, 70), 14.0, GATE_COLOR)
	draw_circle(Vector2(300, 648), 14.0, GATE_COLOR)
	draw_circle(Vector2(855, 648), 14.0, GATE_COLOR)
	# จุดหมายปลายทาง (กำแพงปราสาท + บันได): วงส้มแดง
	draw_circle(Vector2(650, 352), 12.0, CASTLE_COLOR)
	draw_circle(Vector2(855, 500), 12.0, CASTLE_COLOR)
	# ลานจุดวางป้อม: วงทอง + ขอบเข้ม
	for spot in TOWER_SPOTS:
		draw_circle(spot, 26.0, SPOT_FILL)
		draw_arc(spot, 26.0, 0.0, TAU, 32, SPOT_EDGE, 2.0, true)
