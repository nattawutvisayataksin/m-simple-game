extends CharacterBody2D
## ตัวละครผู้เล่น "Kubi" หุ่นนต์ส้มธีม KUB: เคลื่อนที่ด้วย WASD หรือปุ่มลูกศร
## + แอนิเมชันเฟรมจริง (spritesheet 9 เฟรม จาก REST animate-pixminimax)
##
## โจทย์ฝึกหัด:
##  1) ลองเปลี่ยนค่า SPEED ให้เร็วขึ้น/ช้าลง
##  2) ลองเพิ่ม "วิ่งเร็ว" เมื่อกดปุ่ม Shift (แก้ velocity *= 1.5) แล้วเปลี่ยน walk_fps ตามสปีด

## ความเร็วเดิน (พิกเซล/วินาที)
const SPEED := 300.0

## เฟรมเดินต่อวินาที (จังหวะก้าวขา)
@export var walk_fps := 10.0

@onready var visual: Sprite2D = $Visual
var _walk_timer := 0.0


func _physics_process(delta: float) -> void:
	# อ่านค่าการกดปุ่มที่ตั้งไว้ใน Input Map (project.godot)
	# ได้ Vector2 ระยะ -1 ถ้ากดซ้าย/ขึ้น ถึง +1 ถ้ากดขวา/ลง
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")

	# velocity = ทิศทาง x ความเร็ว = การเคลื่อนที่แบบลื่น ๆ
	velocity = direction * SPEED

	# ย้ายตัวละคร + ชนกับสิ่งกีดขวาง (กำแพง) ให้เลื่อนตามผนังอัตโนมัติ
	move_and_slide()

	_animate_visual(delta, direction)


## แอนิเมชัน: หันตามทิศเดิน (lerp กันกระตุก) + เลื่อนเฟรมเดินเมื่อกำลังเคลื่อนที่
func _animate_visual(delta: float, direction: Vector2) -> void:
	if direction != Vector2.ZERO:
		# sprite วาดหันไปทาง "ลง (south)" — สูตร: มุมป้ายหันไปลงต่อทิศที่เดิน (เนียน ๆ)
		var target_angle := direction.angle() - PI / 2.0
		visual.rotation = lerp_angle(visual.rotation, target_angle, 12.0 * delta)

		# เดิน = เลื่อนเฟรม 1-8 วนกลับที่ 1 (เฟรม 0 เก็บไว้ใช้ตอนยืน)
		_walk_timer += delta
		if _walk_timer >= 1.0 / walk_fps:
			_walk_timer = 0.0
			visual.frame = 1 + (visual.frame % (visual.hframes - 1))
	else:
		# ยืนนิ่ง: หันหน้ากลับทางจอ + เฟรมยืนประจำ (0)
		visual.rotation = lerp_angle(visual.rotation, 0.0, 10.0 * delta)
		visual.frame = 0
