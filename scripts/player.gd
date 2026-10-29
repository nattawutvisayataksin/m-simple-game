extends CharacterBody2D
## ตัวละครผู้เล่น "Kubi" หุ่นนต์ส้มธีม KUB: เคลื่อนที่ด้วย WASD หรือปุ่มลูกศร
## + แอนิเมชันเฟรมจริง (spritesheet 9 เฟรม จาก REST animate-pixminimax)
##
## โจทย์ฝึกหัด:
##  1) ลองเปลี่ยนค่า SPEED ให้เร็วขึ้น/ช้าลง
##  2) [x 2026-10-29] วิ่งเร็วเมื่อกดปุ่ม Shift (SPRINT_MULT แล้วเลื่อน walk_fps ตามสปีด)

## ความเร็วเดิน (พิกเซล/วินาที)
const SPEED := 300.0

## ตัวคูณความเร็วเมื่อกด Shift (วิ่งเร็ว)
const SPRINT_MULT := 1.5

## เฟรมเดินต่อวินาที (จังหวะก้าวขา)
@export var walk_fps := 10.0

@onready var visual: Sprite2D = $Visual
var _walk_timer := 0.0


func _physics_process(delta: float) -> void:
	# อ่านค่าการกดปุ่มที่ตั้งไว้ใน Input Map (project.godot)
	# ได้ Vector2 ระยะ -1 ถ้ากดซ้าย/ขึ้น ถึง +1 ถ้ากดขวา/ลง
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")

	# กด Shift = วิ่งเร็วขึ้น 1.5 เท่า แล้วเฟรมเดินก็เร็วตามเพื่อให้อารมณ์ "ขาปั่น"
	var is_sprinting := Input.is_key_pressed(KEY_SHIFT)
	var speed := SPEED * (SPRINT_MULT if is_sprinting else 1.0)

	# velocity = ทิศทาง x ความเร็ว = การเคลื่อนที่แบบลื่น ๆ
	velocity = direction * speed

	# ย้ายตัวละคร + ชนกับสิ่งกีดขวาง (กำแพง) ให้เลื่อนตามผนังอัตโนมัติ
	move_and_slide()

	_animate_visual(delta, direction, is_sprinting)


## แอนิเมชัน: หันตามทิศเดิน (lerp กันกระตุก) + เลื่อนเฟรมเดินเมื่อกำลังเคลื่อนที่
## วิ่งเร็ว (sprinting) เฟรมก้าวเร็วขึ้น 1.5 เท่าให้ตามฝีเท้า
func _animate_visual(delta: float, direction: Vector2, sprinting: bool) -> void:
	if direction != Vector2.ZERO:
		# sprite วาดหันไปทาง "ลง (south)" — สูตร: มุมป้ายหันไปลงต่อทิศที่เดิน (เนียน ๆ)
		var target_angle := direction.angle() - PI / 2.0
		visual.rotation = lerp_angle(visual.rotation, target_angle, 12.0 * delta)

		# เดิน = เลื่อนเฟรม 1-8 วนกลับที่ 1 (เฟรม 0 เก็บไว้ใช้ตอนยืน)
		_walk_timer += delta
		var fps := walk_fps * SPRINT_MULT if sprinting else walk_fps
		if _walk_timer >= 1.0 / fps:
			_walk_timer = 0.0
			visual.frame = 1 + (visual.frame % (visual.hframes - 1))
	else:
		# ยืนนิ่ง: หันหน้ากลับทางจอ + เฟรมยืนประจำ (0)
		visual.rotation = lerp_angle(visual.rotation, 0.0, 10.0 * delta)
		visual.frame = 0
