extends Area2D
## เหรียญที่ผู้เล่นเก็บได้ — ฝึกเรื่อง Area2D + Signal + แอนิเมชันสปรไตต์
##
## โจทย์ฝึกหัด:
##  1) ทำเหรียญหมุนด้วยเฟรมจริง (animate_image → spritesheet) แทนการหมุนด้วยโค้ด
##  2) ทำเหรียญพิเศษสีทอง ให้คะแนน 3 เหรียญ (เพิ่ม export var value)

## สัญญาณที่เตือนไปยังฉากหลักว่า "เก็บได้แล้ว"
## ฉากหลัก (main.gd) จะเป็นค่าย score ต่อ
signal collected

@onready var visual: Sprite2D = $Visual

## ความเร็วการหมุน (เรเดียน/วินาที) — หมุนช้า ๆ เพื่อให้เห็นตัว K
@export var spin_speed := 2.2

func _process(delta: float) -> void:
	# หมุนเหรียญรอบตัวเอง (มุมมอง top-down = เหมือนเหรียญกลิ้งบนพื้น)
	visual.rotation += spin_speed * delta
	# squash & stretch เบา ๆ: บีบยุบ/ขยายสลับกันให้เหรียญมีชีวิต
	var t := Time.get_ticks_msec() / 1000.0
	visual.scale = Vector2.ONE * (1.0 + sin(t * 6.0) * 0.05)

func _on_body_entered(body: Node2D) -> void:
	# body_entered ยิงมาเมื่อมี PhysicsBody เข้ามาในพื้นที่เหรียญ
	# ตรวจก่อนว่าเป็นผู้เล่นจริงไหม (ทำใน group "player")
	if body.is_in_group("player"):
		collected.emit()
		queue_free()  # เหรียญหายไปจากฉาก
