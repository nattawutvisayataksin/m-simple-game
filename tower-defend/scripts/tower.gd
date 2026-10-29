extends Node2D
# ป้อมยิง (T3) - นักธนู/ปืนใหญ่
# เลือกเป้า "คืบหน้าสุด" ในรัศมี (มอนที่ใกล้ปราสาทที่สุดก่อน - Kingdom Rush style)
# ยิงกระสุน homing ผ่าน projectile.gd ; ปืนใหญ่ระเบิดกระจุก (splash)

const ProjectileScript := preload("res://scripts/projectile.gd")

# ชนิดป้อม (ค่าคงที่ int ใช้ร่วมกับ projectile.gd - แก้ enum คนละสคริปต์ผิดกันได้)
const ARCHER := 0
const CANNON := 1

var kind := ARCHER
var damage := 9.0
var fire_interval := 0.75
var range_r := 180.0
var splash_r := 0.0         # >0 = ยิงแบบกระจุกระเบิด (ปืนใหญ่)
var shot_speed := 260.0
var image: Texture2D        # โครงป้อม (tower_archer/cannon)
var level := 1              # ระดับป้อม (T5): อัปเกรดเลือด/ยิงหนักขึ้นแล้วกายใหญ่ + ป้าย "II"

var _cooldown := 0.0
var _sprite: Sprite2D

func setup(tower_kind: int, tex: Texture2D, dmg: float, interval: float, rng: float, shot: float, splash: float) -> void:
	kind = tower_kind
	image = tex
	damage = dmg
	fire_interval = interval
	range_r = rng
	shot_speed = shot
	splash_r = splash

func apply_upgrade(dmg: float, interval: float, rng: float, shot: float, splash: float) -> void:
	# T5: อัปเกรด Lv1 -> Lv2 ครั้งเดียว - ดาเมจ/จังหวะ/รัศมี/กระสุนตามตาราง + กายใหญ่ขึ้น
	damage = dmg
	fire_interval = interval
	range_r = rng
	shot_speed = shot
	splash_r = splash
	level = 2
	if _sprite != null:
		_sprite.scale = Vector2(1.75, 1.75)
	queue_redraw()

func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = image
	_sprite.offset = Vector2(0, -20)   # ฐานป้อมตรงจุด (ยกตัวขึ้นเล็กน้อย)
	_sprite.scale = Vector2(1.6, 1.6)  # 64px -> 102px พอดีลานทอง
	add_child(_sprite)
	add_to_group("towers")
	queue_redraw()

func _draw() -> void:
	# วงรัศมียิง (ฟาดบาง ๆ ให้ผู้เล่นเห็นขอบเขต)
	draw_circle(Vector2.ZERO, range_r, Color(1.0, 0.9, 0.6, 0.05))
	draw_arc(Vector2.ZERO, range_r, 0.0, TAU, 64, Color(1.0, 0.85, 0.4, 0.30), 1.5, true)
	# ป้ายเลเวล (T5): "II" ยอดป้อมสีทอง - ผู้เล่นแยกออกจากป้อมธรรมดา
	if level >= 2:
		var font := ThemeDB.fallback_font
		draw_string(font, Vector2(14.0, -78.0), "II", HORIZONTAL_ALIGNMENT_CENTER, 18, 14, Color(1.0, 0.85, 0.2))

func _pick_target() -> Node2D:
	var best: Node2D = null
	var best_prog := 0.0
	for e in get_tree().get_nodes_in_group("enemies"):
		if not e is Node2D or e.dead or e._progress < 0.0:
			continue
		var d: float = e.position.distance_to(position)
		if d <= range_r and e._progress > best_prog:
			best_prog = e._progress
			best = e
	return best

func _process(delta: float) -> void:
	_cooldown -= delta
	if _cooldown > 0.0:
		return
	var target := _pick_target()
	if target == null:
		return
	_cooldown = fire_interval
	var p := ProjectileScript.new()
	p.target = target
	p.damage = damage
	p.speed = shot_speed
	p.splash_r = splash_r
	p.kind = kind
	p.position = position + Vector2(0, -34)   # จาก"ปากป้อม"
	get_parent().add_child(p)
