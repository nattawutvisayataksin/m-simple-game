extends Area2D
## ศัตรู "ลูกเหล็กเด้ง" — เด้งไปมาในสนาม ถ้าแตะผู้เล่น = เกมแพ้
##
## โจทย์ฝึกหัด:
##  1) ทำศัตรูปล่อยเร็วขึ้นเรื่อย ๆ (speed *= 1.01  เรียกในหนึ่ง _physics_process)
##  2) ทำศัตรู "ตาม" ผู้เล่นเล็กน้อย: เปลี่ยนทิศด้วย (player.position - position).normalized()

## แจ้งฉากหลักว่าจับผู้เล่นได้แล้ว
signal caught_player

## ความเร็วของลูกเหล็ก (พิกเซล/วินาที)
@export var speed := 260.0

## ขอบเขตการเด้ง (โดนกำแพงหนา 40 px อยากให้เด้งก่อนชนขอบจอ)
const BOUNDS_MIN := Vector2(60.0, 60.0)
const BOUNDS_MAX := Vector2(1092.0, 588.0)

var velocity := Vector2.ZERO

@onready var visual: Sprite2D = $Visual

## อัตราการเลื่อนเฟรม "เต้นหายใจ" (เฟรมต่อวินาที)
@export var anim_fps := 8.0
var _anim_timer := 0.0

func _ready() -> void:
	# เริ่มต้นด้วยทิศทางสุ่ม
	var angle := randf_range(0.0, TAU)
	velocity = Vector2.RIGHT.rotated(angle) * speed

func _physics_process(delta: float) -> void:
	position += velocity * delta

	# เด้งคล้ายลูกบอล: ถ้าออกนอกเขต ให้กลับเข้าไปแล้วพลิกความเร็ว
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

	_pulse(delta)


## แอนิเมชัน: เฟรมจริงจาก spritesheet (index 1-8 วนลูป; 0 คือต้นฉบับ)
func _pulse(delta: float) -> void:
	_anim_timer += delta
	if _anim_timer >= 1.0 / anim_fps:
		_anim_timer = 0.0
		visual.frame = 1 + (visual.frame % (visual.hframes - 1))

func _on_body_entered(body: Node2D) -> void:
	# body_entered (Area2D) ยิงมาเมื่อ PhysicsBody ชนเข้ามา
	if body.is_in_group("player"):
		caught_player.emit()
