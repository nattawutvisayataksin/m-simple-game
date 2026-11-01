extends CharacterBody2D
# car.gd — รถแท็กซี่ฟิสิกส์อาร์เคด (แนว Crazy Taxi)
# ขับเชิงมุม: เร่ง/ถอย/เลี้ยวตามความเร็ว เบรกมือ = ดริฟท์ (เลี้ยวแหลมขึ้น + ลื่น)

# CAR_DEFS — [name, max_speed, accel, brake, turn_rate, unlocked_at_cash, color]
const NAMES := {"kubi": 0, "liz": 1, "golem": 2}
const DEFS := [
	{"id": "kubi", "name": "Kubi Cab", "max_speed": 380.0, "accel": 520.0, "brake": 620.0, "turn": 2.6, "unlock_cash": 0, "color": Color(0.95, 0.80, 0.2)},
	{"id": "liz", "name": "กิ้งก่าซิ่ง", "max_speed": 440.0, "accel": 480.0, "brake": 520.0, "turn": 3.1, "unlock_cash": 500, "color": Color(0.35, 0.75, 0.4)},
	{"id": "golem", "name": "โกเลมแท็กซี่", "max_speed": 310.0, "accel": 620.0, "brake": 900.0, "turn": 2.0, "unlock_cash": 1200, "color": Color(0.55, 0.55, 0.6)},
]

var car_id := "kubi"
var steer_throttle := 0.0   # -1 ถอย, 1 เร่ง
var steer_turn := 0.0       # -1 ซ้าย, 1 ขวา
var handbrake := false
var slow_timer := 0.0       # slime hit = slow
var spin_timer := 0.0       # golem hit = spin out
var drifting := false

func def() -> Dictionary:
	return DEFS[NAMES[car_id]]

func _physics_process(dt: float) -> void:
	var d := def()
	var dt2 := dt if dt > 0.0 else 1.0 / 60.0
	if spin_timer > 0.0:
		spin_timer -= dt2
		rotation += 6.0 * dt2          # หมุนส่าย ๆ (โดนโกเลมเหวี่ยง)
		velocity *= pow(0.02, dt2)     # ความเร็วหายไปเร็วระหว่างหมุน
		move_and_slide()
		return
	if slow_timer > 0.0:
		slow_timer -= dt2

	drifting = handbrake and absf(steer_turn) > 0.1 and speed_abs() > 120.0
	var turn_mult := 1.45 if drifting else 1.0
	turn_mult *= 0.35 + 0.65 * minf(speed_abs() / 180.0, 1.0)   # เลี้ยวสุดพลังต่อเมื่อความเร็วสูงพอ
	var target: float = steer_turn * float(d["turn"]) * turn_mult
	rotation = rotation + target * dt2

	var accel := 0.0
	if steer_throttle > 0.0:
		accel = steer_throttle * d["accel"]
	elif steer_throttle < 0.0:
		accel = steer_throttle * d["brake"]
	var speed_cap: float = float(d["max_speed"])
	if slow_timer > 0.0:
		speed_cap *= 0.4
	velocity = velocity + Vector2.RIGHT.rotated(rotation) * accel * dt2
	velocity = velocity * pow(0.85 if handbrake else 0.985, dt2 * 60.0)
	velocity = velocity.limit_length(speed_cap)
	if speed_abs() < 4.0 and accel == 0.0:
		velocity = Vector2.ZERO
	move_and_slide()

func speed_abs() -> float:
	return velocity.length()

func apply_slow(time_s: float) -> void:
	slow_timer = maxf(slow_timer, time_s)

func apply_spin(time_s: float) -> void:
	spin_timer = maxf(spin_timer, time_s)

# รถวาดด้วยโค้ดก่อน — เปลี่ยนเป็น sprite PixelLab ตอน G5
func _draw() -> void:
	var d := def()
	var c: Color = d["color"]
	# เงา
	draw_set_transform(Vector2(3.0, 3.0), 0.0, Vector2.ONE)
	draw_rect(Rect2(-22, -13, 44, 26), Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# ลำตัวรถ
	draw_rect(Rect2(-22, -13, 44, 26), c)
	# ป้าย TAXI (แถบเหลืองกลาง)
	draw_rect(Rect2(-10, -13, 20, 26), Color(0.1, 0.08, 0.05, 0.55))
	draw_rect(Rect2(-22, -3, 5, 6), Color(0.94, 0.93, 0.9))    # หัวไฟหน้า
	draw_rect(Rect2(17, -3, 5, 6), Color(0.7, 0.1, 0.05))     # ไฟท้าย
	# ล้อ 4 ตำแหน่งตามลำตัว
	for w: Vector2 in [Vector2(-14, -15), Vector2(-14, 15), Vector2(12, -15), Vector2(12, 15)]:
		draw_rect(Rect2(w.x - 5, w.y - 2.5, 10, 5), Color(0.05, 0.05, 0.05))
