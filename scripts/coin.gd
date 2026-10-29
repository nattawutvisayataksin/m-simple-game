extends Area2D
## เหรียญที่ผู้เล่นเก็บได้ — ฝึกเรื่อง Area2D + Signal
##
## โจทย์ฝึกหัด:
##  1) ทำเหรียญหมุน โดยเพิ่ม _process(delta) ของ Polygon2D ในตัวเหรียญ (Visual)
##  2) ทำเหรียญพิเศษสีทอง ให้คะแนน 3 เหรียญ (เพิ่ม export var value)

## สัญญาณที่เตือนไปยังฉากหลักว่า "เก็บได้แล้ว"
## ฉากหลัก (main.gd) จะเป็นค่าย score ต่อ
signal collected

func _on_body_entered(body: Node2D) -> void:
	# body_entered ยิงมาเมื่อมี PhysicsBody เข้ามาในพื้นที่เหรียญ
	# ตรวจก่อนว่าเป็นผู้เล่นจริงไหม (ทำใน group "player")
	if body.is_in_group("player"):
		collected.emit()
		queue_free()  # เหรียญหายไปจากฉาก
