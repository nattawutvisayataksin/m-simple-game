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
var lv := 0                 # อัปเกรดถาวร Lv0-3 (+8% สปีด / +6% ท่ีเหลือต่อเลเวล)
var _stat := {}
var steer_throttle := 0.0   # -1 ถอย, 1 เร่ง
var steer_turn := 0.0       # -1 ซ้าย, 1 ขวา
var handbrake := false
var slow_timer := 0.0       # slime hit = slow
var spin_timer := 0.0       # golem hit = spin out
var drifting := false

func set_lv(v: int) -> void:
	lv = clampi(v, 0, 3)
	var d: Dictionary = DEFS[NAMES[car_id]]
	_stat = d.duplicate()
	_stat["max_speed"] = float(d["max_speed"]) * (1.0 + 0.08 * float(lv))
	_stat["accel"] = float(d["accel"]) * (1.0 + 0.06 * float(lv))
	_stat["brake"] = float(d["brake"]) * (1.0 + 0.06 * float(lv))
	_stat["turn"] = float(d["turn"]) * (1.0 + 0.06 * float(lv))

func def() -> Dictionary:
	return _stat if _stat.is_empty() else _stat

func _physics_process(dt: float) -> void:
	queue_redraw()   # เงา/ไฟเบรก/ดาวหมุนเปลี่ยนทุกเฟรม
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

# สไปรต์รถ (PixelLab G5) — ภาพหันลงซ้าย 135°, ทางเกมรถหันตาม velocity
const SPRITE_ANG := PI * 0.75
const TEXES := {
	"kubi": preload("res://assets/sprites/car_kubi.png"),
	"liz": preload("res://assets/sprites/car_liz.png"),
	"golem": preload("res://assets/sprites/car_golem.png"),
}

func _draw() -> void:
	var drift_glow := drifting
	# เงาวงรีใต้รถ (หมุนตามรถ)
	draw_set_transform(Vector2(2.5, 3.5), rotation - SPRITE_ANG, Vector2(1.05, 0.62))
	draw_circle(Vector2.ZERO, 24.0, Color(0, 0, 0, 0.32))
	# ตัวรถ = สไปรต์ หมุนชดเชยมุมภาพ
	draw_set_transform(Vector2.ZERO, rotation - SPRITE_ANG, Vector2.ONE)
	draw_texture_rect(TEXES[car_id], Rect2(-26, -26, 52, 52), false)
	# ไฟเบรกเรืองแดงเวลาเหยียบเบรกมือ/ถอย
	if drift_glow or steer_throttle < 0.0:
		draw_set_transform(Vector2.ZERO, rotation - SPRITE_ANG, Vector2.ONE)
		draw_circle(Vector2(-17, 0), 4.0, Color(1.0, 0.25, 0.1, 0.75))
	if spin_timer > 0.0:
		# ดาวหัวหมุนตอนชนโกเลม
		for i in 3:
			var a := Time.get_ticks_msec() / 90.0 + float(i) * TAU / 3.0
			var pos := Vector2.RIGHT.rotated(a) * 26.0 + Vector2(0, -30)
			draw_circle(pos, 3.0, Color(1.0, 0.9, 0.3))
