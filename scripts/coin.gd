extends Area2D
## เหรียญที่ผู้เล่นเก็บได้ — ฝึกเรื่อง Area2D + Signal + แอนิเมชันสปรไตต์
##
## โจทย์ฝึกหัด:
##  1) ทำเหรียญเรืองแสงวาบ ๆ (modulate วิบวับ) ข้างเติมการหมุนด้วยเฟรมจริง
##  2) [x 2026-10-29] เหรียญพิเศษสีทอง ให้คะแนน 3 เหรียญ (export var value — coin_gold.tscn)

## สัญญาณที่เตือนไปยังฉากหลักว่า "เก็บได้แล้ว"
## ส่ง value (คะแนนของเหรียญ) ไปด้วย — ฉากหลักนำไปสะสม score ต่อ
signal collected(value: int)

@onready var visual: Sprite2D = $Visual

## ดาวเรืองแสงที่โผล่แทนตำแหน่งเมื่อเก็บเหรียญไปแล้ว (จาก Key B pixflux)
@onready var burst_tex: Texture2D = preload("res://assets/art/gen/burst_gold.png")

## คะแนนของเหรียญ (ปกติ 1 / เหรียญทอง 3)
@export var value := 1

## อัตราการเลื่อนเฟรมเหรียญ (เฟรมต่อวินาที)
@export var anim_fps := 10.0
var _anim_timer := 0.0

## บล็อกเก็บซ้ำหลังจบรอบ (ดู disable())
var _taken := false

func _process(delta: float) -> void:
	# หมุนเหรียญด้วย "เฟรมจริง" จาก spritesheet (9 เฟรม, hframes ตั้งใน coin.tscn)
	# เหรียญทองยังเป็นภาพนิ่ง 1 เฟรม (รอ spritesheet จาก Key A) → hframes=1 ข้ามการเลื่อนเฟรม
	if visual.hframes > 1:
		_anim_timer += delta
		if _anim_timer >= 1.0 / anim_fps:
			_anim_timer = 0.0
			# เล่นเฟรมต่อจากปกติ วนกลับ 0 เมื่อจบ
			visual.frame = (visual.frame + 1) % visual.hframes
	if value >= 3:
		# เหรียญทองวาบแสงเพิ่ม เพื่อจับแยกจากเหรียญปกติว่า "ของพิเศษ"
		visual.modulate.a = 0.75 + 0.25 * sin(Time.get_ticks_msec() / 120.0)

func _on_body_entered(body: Node2D) -> void:
	if _taken:
		return
	# body_entered ยิงมาเมื่อมี PhysicsBody เข้ามาในพื้นที่เหรียญ
	# ตรวจก่อนว่าเป็นผู้เล่นจริงไหม (ทำใน group "player")
	if body.is_in_group("player"):
		_taken = true
		_spawn_burst()
		collected.emit(value)
		queue_free()  # เหรียญหายไปจากฉาก


## เอฟเฟกต์ประกายทองวาบครั้งเดียวที่จุดเก็บเหรียญ (scale ขยาย + จางหาย 0.35 วิ)
func _spawn_burst() -> void:
	var burst := Sprite2D.new()
	burst.texture = burst_tex
	burst.position = global_position
	get_tree().current_scene.add_child(burst)
	var tween := burst.create_tween().set_parallel(true)
	tween.tween_property(burst, "scale", Vector2(1.5, 1.5), 0.35)
	tween.tween_property(burst, "modulate:a", 0.0, 0.35)
	tween.chain().tween_callback(burst.queue_free)


## ปิดเหรียญเมื่อจบรอบ (ชนะแล้ว/หมดเวลา/โดนจับ) — ไม่ให้เก็บต่อได้อีก
## set_deferred ต้องใช้: ฟังก์ชันนี้ถูกเรียกจาก callback สัญญาณฟิสิกส์ ซึ่งห้ามตั้ง monitoring ตรง ๆ
func disable() -> void:
	_taken = true
	set_deferred("monitoring", false)
	set_process(false)