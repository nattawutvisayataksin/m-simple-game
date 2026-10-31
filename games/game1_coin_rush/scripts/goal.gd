extends Area2D
## เสาธงชัยแห่งชัยชนะ — อนุสาวรีย์ทองสร้างเองตอน _ready
## โครงสร้าง: แท่นหิน + สันทอง + เหรียญตราเมือง + เสามืด + ลูกแก้วทอง
##            + คานขวาง + ธงผ้าสองชาย (แถบแดง + หางปลา) แกว่งตามลมเบา ๆ + ประกายทองลอย
## origin ถูกวางที่ y=goal_y (ขอบพื้นอยู่ +32) ฐานล่างจมดินนิด ๆ ให้ดูหนักแน่น

signal reached

const GOLD := Color(1.0, 0.82, 0.25)
const GOLD_HI := Color(1.0, 0.95, 0.62)
const GOLD_DARK := Color(0.78, 0.58, 0.14)
const POLE := Color(0.16, 0.1, 0.14)
const STONE := Color(0.64, 0.62, 0.68)
const STONE_TOP := Color(0.74, 0.72, 0.78)
const STONE_DARK := Color(0.52, 0.5, 0.56)
const RED := Color(0.85, 0.16, 0.2)

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_build_monument()
	_build_sparkles()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		reached.emit()

func _poly(points: PackedVector2Array, color: Color, z := 0) -> Polygon2D:
	var p := Polygon2D.new()
	p.polygon = points
	p.color = color
	p.z_index = z
	add_child(p)
	return p

func _rect(x1: float, y1: float, x2: float, y2: float, color: Color, z := 0) -> Polygon2D:
	return _poly(PackedVector2Array([
		Vector2(x1, y1), Vector2(x2, y1), Vector2(x2, y2), Vector2(x1, y2),
	]), color, z)

func _circle(center: Vector2, r: float, color: Color, z := 0, seg := 12) -> Polygon2D:
	var pts := PackedVector2Array()
	for i in range(seg):
		pts.append(center + Vector2(cos(TAU * float(i) / float(seg)), sin(TAU * float(i) / float(seg))) * r)
	return _poly(pts, color, z)

func _build_monument() -> void:
	# ——— แท่นฐานหิน (ล่างสุดแตะพื้นที่ +32) ———
	_rect(-38, 24, 38, 32, STONE_DARK)   # ฐานวงกว้าง ยอดจมดินเลยระดับ
	_rect(-27, 12, 27, 24, STONE)        # เอวเสาแท่น
	_rect(-31, 5, 31, 12, STONE_TOP)     # หน้าแท่นบน
	_rect(-31, 5, 31, 8, GOLD)           # ขอบทองบนแท่น
	# เหรียญตราเมืองประดับหน้าแท่น
	var coin := Sprite2D.new()
	coin.texture = load("res://assets/art/sprites/coin_kub.png")
	coin.position = Vector2(0, 16)
	coin.scale = Vector2(0.7, 0.7)
	coin.z_index = 1
	add_child(coin)
	# ——— เสามืดสง่า + แถบทอง 3 ขีด ———
	_rect(-3, -100, 3, 5, POLE, -1)
	_rect(-3, -58, 3, -54, GOLD_DARK)
	_rect(-3, -36, 3, -32, GOLD_DARK)
	_rect(-3, -14, 3, -10, GOLD_DARK)
	# ——— วงแหวน + ลูกแก้วทองยอดเสา ———
	_rect(-5, -102, 5, -96, GOLD_DARK, 1)
	_circle(Vector2(0, -108), 8, GOLD, 2)
	_circle(Vector2(-2.4, -110.5), 3.2, GOLD_HI, 3)
	# ——— คานสันขวางจุดผ้าธง + หมุดทองปลายคาน ———
	_rect(-22, -78, 22, -72, GOLD, 1)
	_circle(Vector2(-22, -75), 3, GOLD_HI, 2)
	_circle(Vector2(22, -75), 3, GOLD_HI, 2)
	# ——— ผ้าธงสองชาย (อยู่โหนด Sway เพื่อแกว่ง) ———
	var sway := Node2D.new()
	sway.name = "Sway"
	sway.position = Vector2(0, -72)
	sway.z_index = 2
	add_child(sway)
	for side in [-1.0, 1.0]:
		# ผ้าทองหางปลา (แคบลงแล้วแหลมกลาง) — พิกัดเทียบโหนดคาน (y=0 ใต้คาน)
		var cloth := Polygon2D.new()
		cloth.polygon = PackedVector2Array([
			Vector2(side * 15.0, 0.0), Vector2(side * 3.0, 0.0),
			Vector2(side * 3.0, 30.0), Vector2(side * 9.0, 40.0),
			Vector2(side * 15.0, 30.0),
		])
		cloth.color = GOLD
		sway.add_child(cloth)
		var stripe := Polygon2D.new()
		stripe.polygon = PackedVector2Array([
			Vector2(side * 15.0, 12.0), Vector2(side * 3.0, 12.0),
			Vector2(side * 3.0, 17.0), Vector2(side * 15.0, 17.0),
		])
		stripe.color = RED
		sway.add_child(stripe)
	# ผ้าแกว่งสุดสายตรียม: หมุนเบา ๆ รอบขอบคาน (จุดหมุน = ตำแหน่งโหนด)
	var tw := create_tween().set_loops()
	tw.tween_property(sway, "rotation", 0.055, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(sway, "rotation", -0.055, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _build_sparkles() -> void:
	var p := CPUParticles2D.new()
	p.name = "GoldSparkles"
	p.amount = 10
	p.lifetime = 2.4
	p.emitting = true
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(26, 4)
	p.direction = Vector2(0, -1)
	p.spread = 24.0
	p.gravity = Vector2(0, -14)
	p.initial_velocity_min = 14.0
	p.initial_velocity_max = 38.0
	p.scale_amount_min = 0.25
	p.scale_amount_max = 0.6
	p.color = Color(1.0, 0.9, 0.55, 0.5)
	p.position = Vector2(0, 6)
	add_child(p)
