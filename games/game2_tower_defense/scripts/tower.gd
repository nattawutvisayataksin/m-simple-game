extends Node2D
# ป้อมยิง (T3) - นักธนู/ปืนใหญ่
# เลือกเป้า "คืบหน้าสุด" ในรัศมี (มอนที่ใกล้ปราสาทที่สุดก่อน - Kingdom Rush style)
# ยิงกระสุน homing ผ่าน projectile.gd ; ปืนใหญ่ระเบิดกระจุก (splash)
# Phase B: ค่ายทหาร (BARRACKS) - ไม่ยิง แต่เจนทหารยืนบล็อกทางมอน

const ProjectileScript := preload("res://scripts/projectile.gd")
const SoldierScript := preload("res://scripts/soldier.gd")

# ชนิดป้อม (ค่าคงที่ int ใช้ร่วมกับ projectile.gd - แก้ enum คนละสคริปต์ผิดกันได้)
const ARCHER := 0
const CANNON := 1
const MAGE := 2
const BARRACKS := 3

# ค่าทหารต่อเลเวลค่าย (Phase B)
const SOLDIER_STATS := [
	{"hp": 60.0, "dmg": 10.0, "interval": 0.8, "count": 1, "respawn": 6.0},
	{"hp": 95.0, "dmg": 16.0, "interval": 0.66, "count": 2, "respawn": 5.0},
]

class TurretWeaponVisual extends Node2D:
	var weapon_kind: int = 0
	var flash_alpha := 0.0

	func _draw() -> void:
		var barrel_color := Color(0.61, 0.39, 0.20)
		if weapon_kind == 1:
			barrel_color = Color(0.48, 0.52, 0.55)
		elif weapon_kind == 2:
			barrel_color = Color(0.35, 0.66, 0.95)

		draw_line(Vector2.ZERO, Vector2(0, -28), Color(0.12, 0.10, 0.09), 10.0)
		draw_line(Vector2.ZERO, Vector2(0, -28), barrel_color, 6.0)
		draw_line(Vector2(-2, -4), Vector2(-2, -23), barrel_color.lightened(0.3), 2.0)
		draw_circle(Vector2.ZERO, 9.0, Color(0.16, 0.13, 0.11))
		draw_circle(Vector2.ZERO, 6.0, barrel_color.darkened(0.12))

		if weapon_kind == 0:
			draw_line(Vector2(-9, -24), Vector2(9, -24), Color(0.76, 0.58, 0.28), 3.0)
		elif weapon_kind == 1:
			draw_line(Vector2(-5, -14), Vector2(5, -14), Color(0.76, 0.78, 0.76), 3.0)
		else:
			draw_circle(Vector2(0, -29), 5.0, Color(0.16, 0.52, 0.95, 0.65))
			draw_circle(Vector2(0, -29), 2.5, Color(0.78, 0.94, 1.0))

		if flash_alpha > 0.0:
			draw_circle(Vector2(0, -31), 8.0, Color(1.0, 0.62, 0.14, flash_alpha * 0.65))
			draw_circle(Vector2(0, -31), 3.5, Color(1.0, 0.96, 0.68, flash_alpha))

var kind := ARCHER
var damage := 9.0
var fire_interval := 0.75
var range_r := 180.0
var splash_r := 0.0         # >0 = ยิงแบบกระจุกระเบิด (ปืนใหญ่)
var shot_speed := 260.0
var image: Texture2D        # โครงป้อม (tower_archer/cannon)
var level := 1              # ระดับป้อม (T5): อัปเกรดเลือด/ยิงหนักขึ้นแล้วกายใหญ่ + ป้าย "II"
var invested_gold := 0

var _cooldown := 0.0
var _sprite: Sprite2D
var _weapon_pivot: Node2D
var _weapon_visual: TurretWeaponVisual
var _base_scale := Vector2(1.6, 1.6)
var _muzzle_flash_t := 0.0
var _turn_speed := 8.0
var show_range := false

# -- ค่ายทหาร (BARRACKS) --
var _soldiers: Array = []                 # ต่อ slot: Node2D or null
var _respawn: Array[float] = []
var rally_point := Vector2.ZERO           # พิกัดโลกจุดยืนทหาร
var rally_locked := false                 # ผู้เล่นสั่งย้ายเอง = true

func slot_offset(i: int) -> float:
	if i == 0:
		return 0.0
	return 18.0 if i % 2 == 1 else -18.0

func max_soldiers() -> int:
	return int(SOLDIER_STATS[level - 1]["count"])

func soldier_stats() -> Dictionary:
	return SOLDIER_STATS[level - 1]

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
	_base_scale = Vector2(1.75, 1.75)
	if _sprite != null:
		_sprite.scale = _base_scale
	if kind == BARRACKS:
		_refresh_soldier_stats()
	queue_redraw()

func _refresh_soldier_stats() -> void:
	var st := soldier_stats()
	for s in _soldiers:
		if s != null and is_instance_valid(s):
			s.max_hp = st["hp"]
			s.damage = st["dmg"]
			s.attack_interval = st["interval"]
			s._hp = st["hp"]   # อัปเกรดครั้งเดียว: พอใจเลือดเต็มยกต่อ

func _barracks_ready() -> void:
	# Phase B: หา rally default = จุดบน PATH_A ใกล้ค่าย (ทหารยืนหน้าถนน)
	_soldiers = [null, null]
	_respawn = [0.5, 1.2]   # เว้นจังหวะเชิ้ เกิดสลับกัน
	var parent := get_parent()
	if parent != null and "PATH_A" in parent:
		var best := position
		var best_d := INF
		for p in parent.PATH_A:
			var d: float = p.distance_to(position)
			if d < best_d:
				best_d = d
				best = p
		rally_point = best
	else:
		rally_point = position + Vector2(0, 80)

func _maintain_soldiers(delta: float) -> void:
	var st := soldier_stats()
	var count := max_soldiers()
	for i in range(_soldiers.size()):
		var s = _soldiers[i]
		if s == null or not is_instance_valid(s) or s.dead:
			_soldiers[i] = null
			if i < count:
				_respawn[i] -= delta
				if _respawn[i] <= 0.0:
					_soldiers[i] = _spawn_soldier(i)
					_respawn[i] = st["respawn"]   # รีเซ็ตตัวจับเวลาหลังเกิดใหม่ (กันฟื้นทันทีผิดกลไก)
		elif i >= count and not s.dead:
			# หดจำนวน (ไม่เกิดในสถานการณ์จริง แค่กัน overflow)
			pass

func _spawn_soldier(slot: int) -> Node2D:
	var st := soldier_stats()
	var s := SoldierScript.new()
	s.max_hp = st["hp"]
	s.damage = st["dmg"]
	s.attack_interval = st["interval"]
	s.barracks_path = self
	s.rally_point = rally_point
	s.slot_index = slot
	get_parent().add_child(s)
	s.position = rally_point + Vector2(slot_offset(slot), 0.0)
	return s

func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = image
	_sprite.offset = Vector2(0, -20)   # ฐานป้อมตรงจุด (ยกตัวขึ้นเล็กน้อย)
	_sprite.scale = _base_scale
	add_child(_sprite)
	add_to_group("towers")
	if kind == BARRACKS:
		_barracks_ready()
		queue_redraw()
		return
	_weapon_pivot = Node2D.new()
	_weapon_pivot.position = Vector2(0, -40)
	add_child(_weapon_pivot)
	_weapon_visual = TurretWeaponVisual.new()
	_weapon_visual.weapon_kind = kind
	_weapon_pivot.add_child(_weapon_visual)
	add_to_group("towers")
	queue_redraw()

func _draw() -> void:
	if show_range:
		draw_circle(Vector2.ZERO, range_r, Color(1.0, 0.9, 0.6, 0.05))
		draw_arc(Vector2.ZERO, range_r, 0.0, TAU, 64, Color(1.0, 0.85, 0.4, 0.30), 1.5, true)
	# ป้ายเลเวล (T5): "II" ยอดป้อมสีทอง - ผู้เล่นแยกออกจากป้อมธรรมดา
	if level >= 2:
		var font := ThemeDB.fallback_font
		draw_string(font, Vector2(14.0, -78.0), "II", HORIZONTAL_ALIGNMENT_CENTER, 18, 14, Color(1.0, 0.85, 0.2))
	# ค่ายทหาร: ธงชี้จุดยืนทหาร (rally) เสมอ เพราะผู้เล่นสามารถสั่งย้ายได้
	if kind == BARRACKS:
		var rp := rally_point - position
		var flag := rp + Vector2(0.0, -26.0)
		draw_line(rp, flag, Color(0.35, 0.28, 0.2, 0.9), 2.5, true)
		var fc := Color(0.42, 0.62, 0.95) if level >= 2 else Color(0.5, 0.5, 0.55)
		draw_polygon(PackedVector2Array([flag, flag + Vector2(14.0, 3.0), flag + Vector2(0.0, 7.0)]), [fc])
		draw_circle(rp, 5.0, Color(0.35, 0.55, 0.9, 0.6))

func _process_barracks(delta: float) -> void:
	_maintain_soldiers(delta)
	queue_redraw()

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
	if kind == BARRACKS:
		_process_barracks(delta)
		return
	if _muzzle_flash_t > 0.0:
		_muzzle_flash_t = maxf(_muzzle_flash_t - delta, 0.0)
		_weapon_visual.flash_alpha = clampf(_muzzle_flash_t / 0.12, 0.0, 1.0)
		_weapon_visual.queue_redraw()
	_cooldown -= delta
	var target := _pick_target()
	if target == null:
		return
	var to_target := target.position - position
	if to_target.length_squared() <= 0.001:
		return
	var desired_rotation := to_target.angle() + PI * 0.5
	_weapon_pivot.rotation = rotate_toward(_weapon_pivot.rotation, desired_rotation, _turn_speed * delta)
	if _cooldown > 0.0 or absf(wrapf(desired_rotation - _weapon_pivot.rotation, -PI, PI)) > 0.08:
		return

	_cooldown = fire_interval
	_muzzle_flash_t = 0.12
	_weapon_visual.flash_alpha = 1.0
	_weapon_visual.queue_redraw()
	_sprite.scale = _base_scale * Vector2(1.08, 0.94)
	var recoil := create_tween()
	recoil.tween_property(_sprite, "scale", _base_scale, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var p := ProjectileScript.new()
	p.target = target
	p.damage = damage
	p.speed = shot_speed
	p.splash_r = splash_r
	p.kind = kind
	var SND: String = "arrow"
	match kind:
		1: SND = "cannon"
		2: SND = "mage"
	if get_parent() and get_parent().has_method("sfx"):
		get_parent().sfx(SND)
	get_parent().add_child(p)
	p.global_position = _weapon_pivot.to_global(Vector2(0, -31))
