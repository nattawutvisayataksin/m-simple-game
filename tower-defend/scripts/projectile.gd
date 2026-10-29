extends Node2D
# กระสุนป้อม (T3) - ธนู = ลูกธนูแหลมเร็ว / ปืนใหญ่ = ลูกกระสุนดำ + ระเบิดกระจุก
# homing ตามเป้า ; เป้าตาย/หายกลางทาง = ระเบิดที่จุดล่าสุด (ปืนใหญ่) หรือหายไป (ธนู)
# วาดอาศัย rotation ของโหนด (look_at) - ธนูวาดเส้นหันตามหัว +x ตัวเอง

# ชนิดกระสุน (ค่าคงที่ int - ชุดเดียวกับ tower.gd)
const ARCHER := 0
const CANNON := 1

var target: Node2D
var damage := 9.0
var speed := 260.0
var splash_r := 0.0
var kind := 0

func _physics_process(delta: float) -> void:
	var alive: bool = target != null and is_instance_valid(target) and not target.dead
	if not alive:
		if kind == CANNON:
			_explode(position)
		else:
			queue_free()
		return
	var aim: Vector2 = target.position - Vector2(0, 24)   # เล็งกลางตัวไม่ใช่เท้า
	var to := aim - position
	var step := speed * delta
	if to.length() <= step:
		position = aim
		_hit()
		return
	position += to.normalized() * step
	look_at(aim)      # ธนูชี้หัวตามเป้า

func _hit() -> void:
	if kind == CANNON:
		_explode(position)
	else:
		target.take_damage(damage)
	queue_free()

func _explode(at: Vector2) -> void:
	# ระเบิดกระจุก: เป้าเต็ม + มอนรอบ ๆ ในรัศมีได้รับบางส่วน
	for e in get_tree().get_nodes_in_group("enemies"):
		if e is Node2D and not e.dead and (e.position.distance_to(at) <= splash_r):
			var dmg := damage
			if is_instance_valid(target) and e != target:
				dmg = damage * 0.55   # ตัวรอบ ๆ โหมเบากว่าเป้าหลัก
			e.take_damage(dmg)
	queue_free()

func _draw() -> void:
	if kind == ARCHER:
		# ลูกธนูหันตามหัว +x ตัวเอง (rotation ถูกคุมด้วย look_at)
		draw_line(Vector2(5, 0), Vector2(-7, 0), Color(0.32, 0.18, 0.06), 2.5)
		draw_circle(Vector2(6.5, 0), 2.6, Color(1.0, 0.68, 0.1))
	else:
		# ลูกระเบิดปืนใหญ่กลมดำ + ไฮไลต์
		draw_circle(Vector2.ZERO, 5.5, Color(0.14, 0.1, 0.08))
		draw_circle(Vector2(-1.5, -1.5), 1.6, Color(1.0, 1.0, 1.0, 0.55))
