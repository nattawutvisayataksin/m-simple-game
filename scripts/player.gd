extends CharacterBody2D
## ตัวละครผู้เล่น: เคลื่อนที่ด้วย WASD หรือปุ่มลูกศร
## โจทย์ฝึกหัด:
##  1) ลองเปลี่ยนค่า SPEED ให้เร็วขึ้น/ช้าลง
##  2) ลองเพิ่ม "วิ่งเร็ว" เมื่อกดปุ่ม Shift (เศษของ velocity *= 1.5)

## ความเร็วเดิน (พิกเซล/วินาที)
const SPEED := 300.0

func _physics_process(_delta: float) -> void:
	# อ่านค่าการกดปุ่มที่ตั้งไว้ใน Input Map (project.godot)
	# ได้ Vector2 ระยะ -1 ถ้ากดซ้าย/ขึ้น ถึง +1 ถ้ากดขวา/ลง
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")

	# velocity = ทิศทาง x ความเร็ว = การเคลื่อนท่องแบบลื่น ๆ
	velocity = direction * SPEED

	# ย้ายตัวละคร + ชนกับสิ่งกีดขวาง (กำแพง) ให้เลื่อนตามผนังอัตโนมัติ
	move_and_slide()
