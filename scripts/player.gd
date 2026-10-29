extends CharacterBody2D
## ตัวละครผู้เล่น: เคลื่อนที่ด้วย WASD หรือปุ่มลูกศร
## โจทย์ฝึกหัด:
##  1) ลองเปลี่ยนค่า SPEED ให้เร็วขึ้น/ช้าลง
##  2) ลองเพิ่ม "วิ่งเร็ว" เมื่อกดปุ่ม Shift (เศษของ velocity *= 1.5)

## ความเร็วเดิน (พิกเซล/วินาที)
const SPEED := 300.0

@onready var visual: Sprite2D = $Visual

func _physics_process(_delta: float) -> void:
	# อ่านค่าการกดปุ่มที่ตั้งไว้ใน Input Map (project.godot)
	# ได้ Vector2 ระยะ -1 ถ้ากดซ้าย/ขึ้น ถึง +1 ถ้ากดขวา/ลง
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")

	# velocity = ทิศทาง x ความเร็ว = การเคลื่อนท่องแบบลื่น ๆ
	velocity = direction * SPEED

	# ย้ายตัวละคร + ชนกับสิ่งกีดขวาง (กำแพง) ให้เลื่อนตามผนังอัตโนมัติ
	move_and_slide()

	_animate_visual(_delta, direction)


## แอนิเมชันแบบโค้ด (free-juice): หันตามทิศเดิน + เด้งตัวตามจังหวะวิ่ง
func _animate_visual(delta: float, direction: Vector2) -> void:
	var t := Time.get_ticks_msec() / 1000.0

	if direction != Vector2.ZERO:
		# sprite วาดหันไปทาง "ลง (south)" — มุมเท่ากับ 90° ดังนั้น หันเอา "ลง" ตรงเมื่อเดินลง
		# สูตร: หันสปริทตามทิศที่เดิน (แบบเนียน ๆ ไม่กระตุก)
		var target_angle := direction.angle() - PI / 2.0
		visual.rotation = lerp_angle(visual.rotation, target_angle, 12.0 * delta)

		# squash & stretch ตามจังหวะเดิน: ยุบ/ยืดเล็กน้อย รวมอัตราส่วนหน้าที่ 1.0
		var squash := sin(t * 13.0) * 0.06
		visual.scale = Vector2(1.0 - squash, 1.0 + squash)
	else:
		# ยืนนิ่ง: กลับทั้งหมดสู่ scale 1.0 และหันหน้ากลับมาทางจอ (ลง)
		visual.rotation = lerp_angle(visual.rotation, 0.0, 10.0 * delta)
		visual.scale = visual.scale.lerp(Vector2.ONE, 10.0 * delta)
