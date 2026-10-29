extends Area2D
## ศัตรู "ไวรัส" — เด้งไปมาในสนาม ถ้าแตะผู้เล่น = เกมแพ้
##
## โจทย์ฝึกหัด:
##  1) [x ระยะ B 2026-10-29] ไวรัสหลากสี: เขียว = เด้งบ้าคลั่ง (สุ่มกลับทิศ) / น้ำเงิน = ไล่ตามผู้เล่น
##  2) [x ระยะ B 2026-10-29] ไวรัสเพิ่มตามเวลา — จัดคิว spawn ใน main.gd ( VIRUS_SPAWN_SCHEDULE )

## แจ้งฉากหลักว่าจับผู้เล่นได้แล้ว
signal caught_player

## ความเร็วของไวรัส (พิกเซล/วินาที)
@export var speed := 260.0

## ความแรง "ไล่ตาม" (ต่อวินาที) — 0 = เด้งธรรมดา, >0 = หักทิศเข้าหาผู้เล่นต่อเนื่อง (ไวรัสน้ำเงิน)
@export var chase_strength := 0.0

## ช่วงห่างสุ่มกลับทิศ (วินาที) — 0 = ไม่กลับทิศเอง (ไวรัสเขียวตั้งไว้ ~1.2)
@export var jitter_interval := 0.0

## ขอบเขตการเด้ง (กำแพง 32 px อยากให้เด้งก่อนชนขอบจอ)
const BOUNDS_MIN := Vector2(60.0, 60.0)
const BOUNDS_MAX := Vector2(1092.0, 588.0)

var velocity := Vector2.ZERO
var _target: Node2D
var _jitter_timer := 0.0

@onready var visual: Sprite2D = $Visual

## อัตราการเลื่อนเฟรม "เต้นหายใจ" (เฟรมต่อวินาที)
@export var anim_fps := 8.0
var _anim_timer := 0.0


func _ready() -> void:
	# เริ่มต้นด้วยทิศทางสุ่ม
	var angle := randf_range(0.0, TAU)
	velocity = Vector2.RIGHT.rotated(angle) * speed
	if jitter_interval > 0.0:
		_jitter_timer = jitter_interval
	# ไวรัสไล่ตาม ต้องรู้จักผู้เล่นก่อน (ผู้เล่นอยู่ใน group "player")
	if chase_strength > 0.0:
		_target = get_tree().get_first_node_in_group("player")


func _physics_process(delta: float) -> void:
	_steer(delta)
	position += velocity * delta
	_bounce()
	_animate(delta)


## เปลี่ยนทิศพิเศษตามชนิดไวรัส (ชนิดแดงปกติไม่ทำอะไร)
func _steer(delta: float) -> void:
	# น้ำเงิน: ค่อย ๆ หักทิศเข้าหาผู้เล่น — ช้ากว่าแดงแต่กลิ้งตามไม่ยอมเลิก
	if chase_strength > 0.0 and is_instance_valid(_target):
		var chase := (_target.position - position).normalized() * speed
		velocity = velocity.lerp(chase, minf(chase_strength * delta, 1.0)).limit_length(speed)

	# เขียว: ระยะ ๆ ทีละสุ่มเปลี่ยนทิศตัวเอง ให้ผู้เล่นต้อง "เดาทาง" ก่อนหลบ
	if jitter_interval > 0.0:
		_jitter_timer -= delta
		if _jitter_timer <= 0.0:
			_jitter_timer = jitter_interval
			velocity = velocity.rotated(randf_range(-PI / 2.0, PI / 2.0)).limit_length(speed)


## เด้งคล้ายลูกบอล: ถ้าออกนอกเขต ให้กลับเข้าไปแล้วพลิกความเร็ว
func _bounce() -> void:
	if position.x < BOUNDS_MIN.x:
		position.x = BOUNDS_MIN.x
		velocity.x = absf(velocity.x)
	elif position.x > BOUNDS_MAX.x:
		position.x = BOUNDS_MAX.x
		velocity.x = -absf(velocity.x)

	if position.y < BOUNDS_MIN.y:
		position.y = BOUNDS_MIN.y
		velocity.y = absf(velocity.y)
	elif position.y > BOUNDS_MAX.y:
		position.y = BOUNDS_MAX.y
		velocity.y = -absf(velocity.y)


## แอนิเมชัน: เฟรมจริงจาก spritesheet (ซีตเดิม 9 เฟรม, วน index 1-8)
## สีพิเศษเขียว/น้ำเงินเป็นภาพนิ่ง (hframes=1) → "เต้นหายใจ" ด้วย scale แทน
func _animate(delta: float) -> void:
	if visual.hframes > 1:
		_anim_timer += delta
		if _anim_timer >= 1.0 / anim_fps:
			_anim_timer = 0.0
			visual.frame = 1 + (visual.frame % (visual.hframes - 1))
	else:
		var t := Time.get_ticks_msec() / 1000.0
		visual.scale = Vector2.ONE * (1.0 + 0.08 * sin(t * 6.0 + position.x * 0.05))


func _on_body_entered(body: Node2D) -> void:
	# body_entered (Area2D) ยิงมาเมื่อ PhysicsBody ชนเข้ามา
	if body.is_in_group("player"):
		caught_player.emit()
