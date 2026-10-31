extends Node2D
# กระสุนป้อม (T3) - ธนู = ลูกธนูแหลมเร็ว / ปืนใหญ่ = ลูกกระสุนดำ + ระเบิดกระจุก
# homing ตามเป้า ; เป้าตาย/หายกลางทาง = ระเบิดที่จุดล่าสุด (ปืนใหญ่) หรือหายไป (ธนู)
# วาดอาศัย rotation ของโหนด (look_at) - ธนูวาดเส้นหันตามหัว +x ตัวเอง

# ชนิดกระสุน (ค่าคงที่ int - ชุดเดียวกับ tower.gd)
const ARCHER := 0
const CANNON := 1
const MAGE := 2

const ARROW_TEX := preload("res://assets/art/gen/arrow.png")
const BOMB_TEX := preload("res://assets/art/gen/bomb.png")

var target: Node2D
var damage := 9.0
var speed := 260.0
var splash_r := 0.0
var kind := 0

func _ready() -> void:
	if kind == MAGE:
		queue_redraw()
		return
	var s := Sprite2D.new()
	s.texture = ARROW_TEX if kind == ARCHER else BOMB_TEX
	s.scale = Vector2(0.45, 0.45) if kind == ARCHER else Vector2(0.22, 0.22)
	add_child(s)

func _draw() -> void:
	if kind != MAGE:
		return
	draw_line(Vector2(-16.0, 0.0), Vector2(-4.0, 0.0), Color(0.35, 0.78, 1.0, 0.75), 4.0, true)
	draw_circle(Vector2.ZERO, 8.0, Color(0.18, 0.69, 1.0, 0.7))
	draw_circle(Vector2.ZERO, 4.0, Color(0.86, 0.98, 1.0, 1.0))

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
		target.take_damage(damage, kind == MAGE)
	queue_free()

func _explode(at: Vector2) -> void:
	# ระเบิดกระจุก: เป้าเต็ม + มอนรอบ ๆ ในรัศมีได้รับบางส่วน
	if get_parent() and get_parent().has_method("sfx"):
		get_parent().sfx("explosion")
	for e in get_tree().get_nodes_in_group("enemies"):
		if e is Node2D and not e.dead and (e.position.distance_to(at) <= splash_r):
			var dmg := damage
			if is_instance_valid(target) and e != target:
				dmg = damage * 0.55   # ตัวรอบ ๆ โหมเบากว่าเป้าหลัก
			e.take_damage(dmg)
	queue_free()
