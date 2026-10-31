extends Node2D
# ฮีโร่ Kubi (T5) - คลิกขวาสั่งเดิน / ฟาดศัตรูอัตโนมัติในรัศมี / ฟื้นเลือดเมื่อพักสู้
# โดนรุมใกล้ตัวจะเสียเลือด ; เลือดหมด = ล่ม 0.25 จาง แล้วเกิดใหม่หน้าปราสาทครบเลือด
# เฟรมเดิน: kubi_hero_sheet.png 8 ช่อง (512x64) / ยืน: kubi_hero_neutral.png

const WALK_TEX := preload("res://assets/art/gen/kubi_hero_sheet.png")
const IDLE_TEX := preload("res://assets/art/gen/kubi_hero_neutral.png")
const GATE := Vector2(810, 450)   # จุดเกิดใหม่เริ่มต้น (ประตูปราสาทแผนที่ 1)

var home: Vector2 = GATE          # Phase E: จุดพัก/เกิดใหม่ตามแผนที่ปัจจุบัน (main ตั้งให้ตอนเลือกแผนที่)

var speed := 155.0
var acceleration := 900.0
var attack_range := 120.0
var attack_dmg := 24.0
var attack_interval := 0.72
var max_hp := 100.0
var contact_dmg := 7.0      # ความเจ็บจากศัตรูแนมตัววนจนอยู่ติดกัน (จังหวะ 0.9 วิ)
var respawn_time := 8.0

var _hp := 100.0
var _dead := false
var _respawn_t := 0.0
var _target := Vector2.ZERO
var _moving := false
var _velocity := Vector2.ZERO
var _combat_target: Node2D
var _attack_cd := 0.0
var _hurt_cd := 0.0
var _regen_cd := 0.0
var _anim_t := 0.0
var _attack_direction := Vector2.RIGHT
var _attack_flash_t := 0.0
var _command_marker_t := 0.0
var _sprite: Sprite2D

func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = IDLE_TEX
	_sprite.offset = Vector2(0, -14)
	_sprite.scale = Vector2(1.35, 1.35)
	add_child(_sprite)
	add_to_group("hero")
	_hp = max_hp

func move_to(pos: Vector2) -> void:
	if _dead:
		return
	_combat_target = null
	_target = Vector2(clampf(pos.x, 28.0, 1124.0), clampf(pos.y, 28.0, 620.0))
	_moving = position.distance_to(_target) > 4.0
	_command_marker_t = 0.75

func attack_target(target: Node2D) -> void:
	if _dead or target == null or not is_instance_valid(target) or target.dead:
		return
	_combat_target = target
	_target = target.position
	_moving = position.distance_to(_target) > attack_range * 0.72
	_command_marker_t = 0.75

func take_damage(amount: float) -> void:
	if _dead:
		return
	_hp -= amount
	if _hp <= 0.0:
		_die()

func _die() -> void:
	_dead = true
	_hp = 0.0
	_respawn_t = respawn_time
	_moving = false
	_velocity = Vector2.ZERO
	_combat_target = null
	_sprite.texture = IDLE_TEX
	_sprite.hframes = 1
	_sprite.frame = 0
	_sprite.modulate = Color(1.0, 1.0, 1.0, 0.25)

func _respawn() -> void:
	_dead = false
	_hp = max_hp
	position = home
	_moving = false
	_velocity = Vector2.ZERO
	_sprite.modulate = Color.WHITE

func _physics_process(delta: float) -> void:
	queue_redraw()
	_attack_flash_t = maxf(_attack_flash_t - delta, 0.0)
	_command_marker_t = maxf(_command_marker_t - delta, 0.0)
	if _dead:
		_respawn_t -= delta
		if _respawn_t <= 0.0:
			_respawn()
		return
	_attack_cd -= delta
	_hurt_cd -= delta
	# ฟื้นเลือดสู้ช้า ๆ ต่อวินาที
	_regen_cd += delta
	if _regen_cd >= 1.0:
		_regen_cd = 0.0
		_hp = minf(_hp + 3.0, max_hp)
	if _combat_target != null and (not is_instance_valid(_combat_target) or _combat_target.dead):
		_combat_target = null
	if _combat_target != null:
		var to_enemy := _combat_target.position - position
		if to_enemy.length() > attack_range * 0.72:
			_target = _combat_target.position - to_enemy.normalized() * attack_range * 0.72
			_moving = true
		else:
			_moving = false

	var desired_velocity := Vector2.ZERO
	var arrived := false
	if _moving:
		var to_target := _target - position
		if to_target.length() <= 5.0:
			if _combat_target == null:
				position = _target
			_moving = false
			_velocity = Vector2.ZERO
			arrived = true
		else:
			desired_velocity = to_target.normalized() * speed
	_velocity = _velocity.move_toward(desired_velocity, acceleration * delta)
	if not arrived:
		position += _velocity * delta
	position.x = clampf(position.x, 24.0, 1128.0)
	position.y = clampf(position.y, 24.0, 624.0)
	if absf(_velocity.x) > 1.0:
		_sprite.flip_h = _velocity.x > 0.0
	_sprite.rotation = clampf(_velocity.x / speed * 0.08, -0.08, 0.08)
	_sprite.offset.y = -14.0 + sin(_anim_t * 0.5) * (1.2 if _velocity.length() < 5.0 else 0.0)

	if _velocity.length() > 5.0:
		if _sprite.texture != WALK_TEX:
			_sprite.texture = WALK_TEX
			_sprite.hframes = 8
		_anim_t += delta * lerpf(8.0, 13.0, clampf(_velocity.length() / speed, 0.0, 1.0))
		_sprite.frame = int(_anim_t) % 8
	else:
		_sprite.texture = IDLE_TEX
		_sprite.hframes = 1
		_sprite.frame = 0
	# เลือกตัวใกล้สุดในรัศมีฟาด
	var best: Node2D = null
	var bd := attack_range
	for e in get_tree().get_nodes_in_group("enemies"):
		if e is Node2D and not e.dead:
			var d: float = e.position.distance_to(position)
			if d < bd:
				bd = d
				best = e
	if best != null and _attack_cd <= 0.0:
		_attack_cd = attack_interval
		_attack_direction = (best.position - position).normalized()
		_attack_flash_t = 0.24
		_sprite.scale = Vector2(1.55, 1.12)
		var attack_tween := create_tween()
		attack_tween.tween_property(_sprite, "scale", Vector2(1.35, 1.35), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		best.take_damage(attack_dmg)
		if get_parent() and get_parent().has_method("sfx"):
			get_parent().sfx("slash")
		if best.dead and _combat_target == best:
			_combat_target = null
	# โดนรุม: ตัวใดยืนติดกันนานจนเย็น 0.9 วิ = บีบเลือดหนึ่งจังหวะ
	if _hurt_cd <= 0.0:
		for e2 in get_tree().get_nodes_in_group("enemies"):
			if e2 is Node2D and not e2.dead and e2.position.distance_to(position) <= 52.0:
				take_damage(contact_dmg)
				_hurt_cd = 0.9
				break

func _draw() -> void:
	if _dead:
		return
	if _command_marker_t > 0.0:
		var marker := _target - position
		var alpha := clampf(_command_marker_t / 0.75, 0.0, 1.0)
		draw_arc(marker, 13.0, 0.0, TAU, 24, Color(1.0, 0.84, 0.34, alpha), 2.5, true)
		draw_line(marker + Vector2(-5.0, 0.0), marker + Vector2(5.0, 0.0), Color(1.0, 0.92, 0.58, alpha), 2.0, true)
		draw_line(marker + Vector2(0.0, -5.0), marker + Vector2(0.0, 5.0), Color(1.0, 0.92, 0.58, alpha), 2.0, true)
	if _attack_flash_t > 0.0:
		var slash_center := Vector2(0.0, -18.0) + _attack_direction * 25.0
		var slash_side := _attack_direction.orthogonal()
		var slash_alpha := clampf(_attack_flash_t / 0.24, 0.0, 1.0)
		draw_line(slash_center - slash_side * 11.0 - _attack_direction * 7.0,
			slash_center + slash_side * 11.0 + _attack_direction * 7.0,
			Color(1.0, 0.72, 0.24, slash_alpha), 6.0, true)
		draw_line(slash_center - slash_side * 8.0 - _attack_direction * 5.0,
			slash_center + slash_side * 8.0 + _attack_direction * 5.0,
			Color(1.0, 0.96, 0.72, slash_alpha), 2.0, true)
	if _hp < max_hp - 0.01:
		var w := 46.0
		draw_rect(Rect2(-w / 2.0, -52.0, w, 7.0), Color(0.08, 0.05, 0.03, 0.85))
		var frac := clampf(_hp / max_hp, 0.0, 1.0)
		draw_rect(Rect2(-w / 2.0 + 1.0, -51.0, (w - 2.0) * frac, 5.0), Color(0.35, 0.9, 0.3))
