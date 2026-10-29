extends Area2D
## เหรียญที่ผู้เล่นเก็บได้ — ฝึกเรื่อง Area2D + Signal + แอนิเมชันสปรไตต์
##
## โจทย์ฝึกหัด:
##  1) ทำเหรียญเรืองแสงวาบ ๆ (modulate วิบวับ) ข้างเติมการหมุนด้วยเฟรมจริง
##  2) ทำเหรียญพิเศษสีทอง ให้คะแนน 3 เหรียญ (เพิ่ม export var value)

## สัญญาณที่เตือนไปยังฉากหลักว่า "เก็บได้แล้ว"
## ฉากหลัก (main.gd) จะเป็นค่าย score ต่อ
signal collected

@onready var visual: Sprite2D = $Visual

## อัตราการเลื่อนเฟรมเหรียญ (เฟรมต่อวินาที)
@export var anim_fps := 10.0
var _anim_timer := 0.0

func _process(delta: float) -> void:
	# หมุนเหรียญด้วย "เฟรมจริง" จาก spritesheet (9 เฟรม, hframes ตั้งใน coin.tscn)
	_anim_timer += delta
	if _anim_timer >= 1.0 / anim_fps:
		_anim_timer = 0.0
		# เล่นเฟรมต่อจากตัวอย่างปกติ วนกลับ 0 เมื่อจบ
		visual.frame = (visual.frame + 1) % visual.hframes

func _on_body_entered(body: Node2D) -> void:
	# body_entered ยิงมาเมื่อมี PhysicsBody เข้ามาในพื้นที่เหรียญ
	# ตรวจก่อนว่าเป็นผู้เล่นจริงไหม (ทำใน group "player")
	if body.is_in_group("player"):
		collected.emit()
		queue_free()  # เหรียญหายไปจากฉาก
